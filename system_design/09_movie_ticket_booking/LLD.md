# Movie Ticket Booking: Low-Level Design

## 1. Scope for the LLD round

- A **show** has a fixed set of seats with categories and prices.
- A user **holds** specific seats for 10 minutes, **all or nothing**: if any requested seat is taken, nothing is held.
- **Expired holds are free** immediately (lazy check), and a sweep cleans them up.
- **Booking** a hold charges the payment gateway; while paying, the hold is extended to a payment window.
- Edge cases: payment declined (seats released), duplicate booking request (idempotency key), payment that succeeds after the seats were lost (automatic refund).
- **Cancellation** with refund until 1 hour before the show.

Out of scope: catalog search, seat-map caching, waiting rooms (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Show` | Seats (ID -> category), price per category, start time. |
| `ShowSeat` | Per show and seat: current hold (ID, expiry) or booking ID. |
| `Hold` / `HoldStatus` | A user's temporary claim: `active -> paying -> converted`, or `released` / `expired`. |
| `Booking` / `BookingStatus` | `confirmed`, `failed`, `refunded`, `cancelled`. |
| `PaymentGateway` (interface) | `charge(token, amount, idempotencyKey)`, `refund(paymentId)`. |
| `PaymentResult` (sealed) | `Paid(paymentId)` or `Declined(reason)`. |
| `BookingService` | Facade: `seatMap`, `hold`, `release`, `book`, `cancel`, `sweepExpired`. |

```text
BookingService --has many--> Show --has many--> ShowSeat (holdId + expiry | bookingId)
      |   --has many--> Hold     (seatIds, expiresAt, status)
      |   --has many--> Booking  (seatIds, amount, paymentId, status)
      +--uses--> PaymentGateway (interface) <-- real gateway / FakeGateway
      +--uses--> Clock
```

## 3. Design decisions and why

- **The hold is the lock.** A seat row carries `holdId` and `holdExpiresAt`; no lock is held while the user thinks or pays.
- **Availability is computed, not stored:** a seat is free if it has no booking and its hold is missing or expired. Correctness never depends on the sweep running.
- **All-or-nothing:** check every requested seat first, then claim all of them, in one atomic step (one transaction / one conditional update in a real database).
- **Extend the hold when payment starts**, to a payment window longer than the gateway's timeout, so the seats are not lost mid-payment in normal cases.
- **Re-verify ownership after payment.** If the gateway took longer than the window and someone else took a seat, refund instead of double booking.
- **Idempotency key -> booking**, so a retried "Pay" does not charge twice.
- **Seat state lives in the show**, not in `Seat`: the same physical seat has different states in different shows.

## 4. The code

```dart
// ---------- Time ----------

abstract interface class Clock {
  DateTime now();
}

class FakeClock implements Clock {
  FakeClock(this._now);
  DateTime _now;
  @override
  DateTime now() => _now;
  void advance(Duration d) => _now = _now.add(d);
}

// ---------- Catalog ----------

enum SeatCategory { regular, premium }

class Show {
  Show({required this.id, required this.startsAt, required Map<String, SeatCategory> seats, required this.prices})
    : seats = {for (final e in seats.entries) e.key: ShowSeat(e.key, e.value)};

  final String id;
  final DateTime startsAt;
  final Map<String, ShowSeat> seats;
  final Map<SeatCategory, int> prices; // cents
}

class ShowSeat {
  ShowSeat(this.seatId, this.category);
  final String seatId;
  final SeatCategory category;
  String? holdId;
  DateTime? holdExpiresAt;
  String? bookingId;
}

// ---------- Holds and bookings ----------

enum HoldStatus { active, paying, converted, released, expired }

class Hold {
  Hold(this.id, this.userId, this.showId, this.seatIds, this.expiresAt);
  final String id;
  final String userId;
  final String showId;
  final List<String> seatIds;
  DateTime expiresAt;
  HoldStatus status = HoldStatus.active;
}

enum BookingStatus { confirmed, failed, refunded, cancelled }

class Booking {
  Booking(this.id, this.userId, this.showId, this.seatIds, this.amountCents);
  final String id;
  final String userId;
  final String showId;
  final List<String> seatIds;
  final int amountCents;
  BookingStatus status = BookingStatus.failed;
  String? paymentId;
  String? failureReason;
}

// ---------- Payments ----------

sealed class PaymentResult {}

class Paid extends PaymentResult {
  Paid(this.paymentId);
  final String paymentId;
}

class Declined extends PaymentResult {
  Declined(this.reason);
  final String reason;
}

abstract interface class PaymentGateway {
  PaymentResult charge(String token, int amountCents, String idempotencyKey);
  void refund(String paymentId);
}

// ---------- Exceptions ----------

class SeatsUnavailableException implements Exception {
  SeatsUnavailableException(this.seatIds);
  final List<String> seatIds;
  @override
  String toString() => 'unavailable: $seatIds';
}

class HoldExpiredException implements Exception {}

class CancellationClosedException implements Exception {}

// ---------- Service ----------

class BookingService {
  BookingService({
    required this.clock,
    required this.gateway,
    this.holdDuration = const Duration(minutes: 10),
    this.paymentWindow = const Duration(minutes: 15),
    this.cancelCutoff = const Duration(hours: 1),
    this.maxSeatsPerHold = 10,
  });

  final Clock clock;
  final PaymentGateway gateway;
  final Duration holdDuration;
  final Duration paymentWindow;
  final Duration cancelCutoff;
  final int maxSeatsPerHold;

  final shows = <String, Show>{};
  final holds = <String, Hold>{};
  final bookings = <String, Booking>{};
  final _byIdempotencyKey = <String, Booking>{};
  var _nextHold = 1;
  var _nextBooking = 1;

  void addShow(Show show) => shows[show.id] = show;

  bool _isFree(ShowSeat s) => s.bookingId == null && (s.holdId == null || !s.holdExpiresAt!.isAfter(clock.now()));

  String statusOf(ShowSeat s) => s.bookingId != null
      ? 'booked'
      : _isFree(s)
      ? 'available'
      : 'held';

  Map<String, String> seatMap(String showId) => {for (final s in shows[showId]!.seats.values) s.seatId: statusOf(s)};

  Hold hold(String userId, String showId, List<String> seatIds) {
    final show = shows[showId]!;
    if (seatIds.isEmpty || seatIds.length > maxSeatsPerHold || seatIds.toSet().length != seatIds.length) {
      throw ArgumentError('choose 1 to $maxSeatsPerHold distinct seats');
    }
    final unknown = seatIds.where((id) => !show.seats.containsKey(id));
    if (unknown.isNotEmpty) throw ArgumentError('unknown seats: ${unknown.toList()}');

    // Check everything first, then claim everything: all or nothing.
    // In SQL: one UPDATE ... WHERE seat_id IN (...) AND <free>, and roll back unless all rows changed.
    final taken = [
      for (final id in seatIds)
        if (!_isFree(show.seats[id]!)) id,
    ];
    if (taken.isNotEmpty) throw SeatsUnavailableException(taken);

    final h = Hold('h${_nextHold++}', userId, showId, List.unmodifiable(seatIds), clock.now().add(holdDuration));
    for (final id in seatIds) {
      _expirePrevious(show.seats[id]!);
      show.seats[id]!
        ..holdId = h.id
        ..holdExpiresAt = h.expiresAt;
    }
    holds[h.id] = h;
    return h;
  }

  void _expirePrevious(ShowSeat s) {
    final previous = holds[s.holdId];
    if (previous != null && previous.status == HoldStatus.active) previous.status = HoldStatus.expired;
  }

  /// True while every seat of the hold still belongs to it and it has not expired.
  bool _owns(Hold h) {
    final show = shows[h.showId]!;
    return h.expiresAt.isAfter(clock.now()) &&
        h.seatIds.every((id) => show.seats[id]!.holdId == h.id && show.seats[id]!.bookingId == null);
  }

  void release(String holdId) {
    final h = holds[holdId]!;
    if (h.status != HoldStatus.active) return;
    _freeSeatsOf(h);
    h.status = HoldStatus.released;
  }

  void _freeSeatsOf(Hold h) {
    final show = shows[h.showId]!;
    for (final id in h.seatIds) {
      final s = show.seats[id]!;
      if (s.holdId == h.id) {
        s
          ..holdId = null
          ..holdExpiresAt = null;
      }
    }
  }

  Booking book(String holdId, String paymentToken, String idempotencyKey) {
    final previous = _byIdempotencyKey[idempotencyKey];
    if (previous != null) return previous; // retried request: same answer, no second charge

    final h = holds[holdId]!;
    if (h.status != HoldStatus.active || !_owns(h)) {
      if (h.status == HoldStatus.active) h.status = HoldStatus.expired;
      throw HoldExpiredException();
    }
    final show = shows[h.showId]!;
    final amount = h.seatIds.fold(0, (sum, id) => sum + show.prices[show.seats[id]!.category]!);
    final booking = Booking('b${_nextBooking++}', h.userId, h.showId, h.seatIds, amount);
    bookings[booking.id] = booking;
    _byIdempotencyKey[idempotencyKey] = booking;

    // Extend the hold for the payment, so it does not expire while the gateway works.
    h
      ..status = HoldStatus.paying
      ..expiresAt = clock.now().add(paymentWindow);
    for (final id in h.seatIds) {
      show.seats[id]!.holdExpiresAt = h.expiresAt;
    }

    switch (gateway.charge(paymentToken, amount, idempotencyKey)) {
      case Declined(:final reason):
        booking
          ..status = BookingStatus.failed
          ..failureReason = reason;
        _freeSeatsOf(h);
        h.status = HoldStatus.released;
      case Paid(:final paymentId):
        booking.paymentId = paymentId;
        if (!_owns(h)) {
          // The gateway outlived the payment window and someone else took a seat: never double book.
          gateway.refund(paymentId);
          booking
            ..status = BookingStatus.refunded
            ..failureReason = 'seats lost during payment';
          _freeSeatsOf(h);
          h.status = HoldStatus.expired;
        } else {
          for (final id in h.seatIds) {
            show.seats[id]!
              ..bookingId = booking.id
              ..holdId = null
              ..holdExpiresAt = null;
          }
          booking.status = BookingStatus.confirmed;
          h.status = HoldStatus.converted;
        }
    }
    return booking;
  }

  void cancel(String bookingId) {
    final b = bookings[bookingId]!;
    if (b.status != BookingStatus.confirmed) throw StateError('booking ${b.id} is ${b.status.name}');
    final show = shows[b.showId]!;
    if (clock.now().isAfter(show.startsAt.subtract(cancelCutoff))) throw CancellationClosedException();
    for (final id in b.seatIds) {
      show.seats[id]!.bookingId = null;
    }
    gateway.refund(b.paymentId!);
    b.status = BookingStatus.cancelled;
  }

  /// Background cleanup. Correctness does not depend on it; it keeps state tidy.
  int sweepExpired() {
    var n = 0;
    for (final h in holds.values.where((h) => h.status == HoldStatus.active && !h.expiresAt.isAfter(clock.now()))) {
      _freeSeatsOf(h);
      h.status = HoldStatus.expired;
      n++;
    }
    return n;
  }
}

// ---------- Test double ----------

class FakeGateway implements PaymentGateway {
  final charges = <String>[];
  final refunds = <String>[];
  void Function()? whileCharging; // simulate time passing and other users acting during a slow call

  @override
  PaymentResult charge(String token, int amountCents, String idempotencyKey) {
    whileCharging?.call();
    whileCharging = null;
    if (token == 'card-declined') return Declined('insufficient funds');
    charges.add('$idempotencyKey:$amountCents');
    return Paid('pay-${charges.length}');
  }

  @override
  void refund(String paymentId) => refunds.add(paymentId);
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void expectThrows<T extends Object>(void Function() f) {
  try {
    f();
  } on T {
    print('ok: threw $T');
    return;
  }
  throw StateError('expected $T');
}

void main() {
  final clock = FakeClock(DateTime.utc(2025, 6, 1, 15));
  final gateway = FakeGateway();
  final service = BookingService(clock: clock, gateway: gateway)
    ..addShow(
      Show(
        id: 's1',
        startsAt: DateTime.utc(2025, 6, 1, 20),
        seats: {
          for (final id in ['A1', 'A2', 'A3', 'A4']) id: SeatCategory.regular,
          for (final id in ['P1', 'P2']) id: SeatCategory.premium,
        },
        prices: {SeatCategory.regular: 1000, SeatCategory.premium: 1500},
      ),
    );

  // All or nothing: bob's request overlaps alice's hold, so he gets nothing (A3 stays free).
  final aliceHold = service.hold('alice', 's1', ['A1', 'A2']);
  try {
    service.hold('bob', 's1', ['A2', 'A3']);
    throw StateError('should have failed');
  } on SeatsUnavailableException catch (e) {
    check(e.seatIds, ['A2']);
  }
  check(service.seatMap('s1'), {
    'A1': 'held',
    'A2': 'held',
    'A3': 'available',
    'A4': 'available',
    'P1': 'available',
    'P2': 'available',
  });
  expectThrows<ArgumentError>(() => service.hold('bob', 's1', ['Z9']));
  expectThrows<ArgumentError>(() => service.hold('bob', 's1', ['A3', 'A3']));

  // Booking, and an idempotent retry that does not charge again.
  final b1 = service.book(aliceHold.id, 'card-ok', 'alice-pay-1');
  check([b1.status, b1.amountCents], [BookingStatus.confirmed, 2000]);
  check(identical(service.book(aliceHold.id, 'card-ok', 'alice-pay-1'), b1), true);
  check(gateway.charges, ['alice-pay-1:2000']);
  check([service.seatMap('s1')['A1'], aliceHold.status], ['booked', HoldStatus.converted]);

  // Expiry is lazy: after 10 minutes carol can take bob's seat, and bob can no longer pay.
  final bobHold = service.hold('bob', 's1', ['A3']);
  clock.advance(const Duration(minutes: 10));
  check(service.seatMap('s1')['A3'], 'available');
  final carolHold = service.hold('carol', 's1', ['A3']);
  expectThrows<HoldExpiredException>(() => service.book(bobHold.id, 'card-ok', 'bob-pay-1'));
  check(bobHold.status, HoldStatus.expired);

  // Declined payment releases the seats.
  final daveHold = service.hold('dave', 's1', ['P1']);
  final declined = service.book(daveHold.id, 'card-declined', 'dave-pay-1');
  check([declined.status, declined.failureReason], [BookingStatus.failed, 'insufficient funds']);
  check(service.seatMap('s1')['P1'], 'available');

  // Slow gateway inside the payment window: the extended hold protects the seat.
  final erinHold = service.hold('erin', 's1', ['P2']);
  Object? frankError;
  gateway.whileCharging = () {
    clock.advance(const Duration(minutes: 12)); // past the original 10-minute hold
    try {
      service.hold('frank', 's1', ['P2']);
    } on SeatsUnavailableException catch (e) {
      frankError = e;
    }
  };
  check(service.book(erinHold.id, 'card-ok', 'erin-pay-1').status, BookingStatus.confirmed);
  check(frankError, 'unavailable: [P2]');

  // Gateway slower than the payment window, and someone took the seat: refund, never double book.
  final graceHold = service.hold('grace', 's1', ['A4']);
  gateway.whileCharging = () {
    clock.advance(const Duration(minutes: 20));
    service.hold('heidi', 's1', ['A4']);
  };
  final late = service.book(graceHold.id, 'card-ok', 'grace-pay-1');
  check([late.status, late.failureReason], [BookingStatus.refunded, 'seats lost during payment']);
  check(gateway.refunds, [late.paymentId]);
  check(service.seatMap('s1')['A4'], 'held'); // heidi's hold

  // Sweep, release, cancellation with cutoff.
  service.release(carolHold.id);
  check(service.seatMap('s1')['A3'], 'available');
  clock.advance(const Duration(minutes: 10));
  check(service.sweepExpired(), 1); // heidi's hold
  service.cancel(b1.id); // it is 15:52, show at 20:00
  check([b1.status, service.seatMap('s1')['A1'], gateway.refunds.length], [BookingStatus.cancelled, 'available', 2]);
  clock.advance(const Duration(hours: 3, minutes: 30)); // 19:22
  final erinBooking = service.bookings.values.firstWhere((b) => b.userId == 'erin');
  expectThrows<CancellationClosedException>(() => service.cancel(erinBooking.id));
}
```

## 5. Walkthrough

- Bob's request includes A2 (held by Alice), so the service throws before claiming anything; A3 stays available. Without the check-all-first step, Bob would have been left holding a useless single seat.
- Alice's retry with the same idempotency key returns the same booking; the gateway was charged once.
- Ten minutes after Bob's hold, the seat map already shows A3 as available, without any sweep. Carol takes it, and Bob's payment attempt fails before charging.
- Erin's payment takes 12 minutes. Her hold was extended to a 15-minute payment window when payment began, so Frank cannot take P2 in the meantime.
- Grace's payment takes 20 minutes, longer than the window; Heidi legitimately holds A4 by then. The charge succeeds, ownership is re-checked, and Grace is refunded instead of double booking A4.
- Times in the cancellation check: start 15:00, plus 10 + 12 + 20 + 10 minutes = 15:52, before the 19:00 cutoff. After 3.5 more hours (19:22) cancellation is closed.

## 6. Concurrency

- `hold` must be atomic across its seats: in a database, a single conditional `UPDATE` with the free-seat predicate and a check that the affected row count equals the number of seats, or `SELECT ... FOR UPDATE` on those rows inside one transaction. Lock rows in a fixed order (seat ID) to avoid deadlocks between overlapping multi-seat requests.
- `book` marks seats booked with the same conditional style: `WHERE hold_id = ? AND booking_id IS NULL`.
- The gateway call happens **outside** any database transaction; the hold (row state) protects the seats in between.
- A unique constraint on `(show_id, seat_id)` in a bookings-per-seat table is a final safety net against bugs.

## 7. Extensibility

| Change | Where |
|---|---|
| Coupons, convenience fees | A `PricingStrategy` used by `book` to compute the amount. |
| Asynchronous payments (webhooks) | Split `book` into `startPayment` and `onPaymentResult`; the `paying` hold status already models the gap. |
| General admission | Replace seat rows with a counter per show and a conditional decrement. |
| Best-available seats | A `SeatSelector` that proposes adjacent seats; `hold` stays the same. |
| Waitlist | On release, expiry or cancellation, notify the next user in a queue. |

## 8. Common mistakes in LLD rounds

- Putting `isBooked` on the physical `Seat` class (it differs per show).
- Holding a mutex across the payment call.
- Partial holds (some seats held, others not).
- Expiry that only happens in a scheduled job.
- Charging before checking that the hold is still valid, or not re-checking after.

See [HLD.md](HLD.md) for the services, sharding and flash-sale handling.
