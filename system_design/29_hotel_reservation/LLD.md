# Hotel Reservation System: Low-Level Design

## 1. Scope for the LLD round

- **Inventory per (hotel, room type, night)** with `total`, `reserved` and a `version` for optimistic concurrency.
- **Overbooking limit** per room type: at most `floor(total x (1 + rate))` reservations per night.
- **Reserve** a stay (check-out exclusive) for N rooms: **all nights or none**, via a conditional multi-row commit that fails if any version changed; retries on conflict.
- **Idempotency key** per reservation request.
- **Cancel** releases every night. **Availability** for a range = minimum over its nights.
- **Nightly pricing** with weekend rates (Friday and Saturday nights).

Out of scope: payments, search caching, room assignment at check-in (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `nightsOf` | Check-in/check-out -> list of nights; validates the range. |
| `InventoryRow` | `total`, `reserved`, `version` for one night. |
| `InventoryStore` | Stands in for the database table: snapshot reads and an all-or-nothing conditional commit. |
| `RatePlan` | Price per night (weekday / weekend). |
| `Reservation` | ID, key, hotel, room type, nights, rooms, total price, status. |
| `ReservationService` | `available`, `reserve` (with retries), `cancel`, idempotency map. |

```text
ReservationService --reads/commits--> InventoryStore: (hotel, roomType, night) -> InventoryRow(total, reserved, version)
        |          --uses--> RatePlan
        +--has many--> Reservation (idempotency key -> reservation)
```

## 3. Design decisions and why

- **Room types, not rooms:** guests book a type; per-night counters are simple and fast. Physical rooms are assigned later.
- **Optimistic concurrency with versions:** conflicts are rare (most nights are not the last room), so reading without locks and committing conditionally is cheapest. The commit is the database statement `UPDATE ... WHERE version = :v` for each night, in one transaction.
- **All-or-nothing commit across nights:** a stay with one sold-out night must not leave the other nights reserved.
- **Bounded retries:** after a conflict the service re-reads; if the room is now gone, it reports "unavailable" rather than looping.
- **Overbooking is explicit configuration,** applied in exactly one place (`limitOf`).
- **Money in integer currency units,** computed per night so weekend pricing and future rate changes are exact.

## 4. The code

```dart
List<DateTime> nightsOf(DateTime checkIn, DateTime checkOut) {
  if (!checkOut.isAfter(checkIn)) throw ArgumentError('check-out must be after check-in');
  return [for (var d = checkIn; d.isBefore(checkOut); d = d.add(const Duration(days: 1))) d];
}

class InventoryRow {
  InventoryRow(this.total);
  int total;
  int reserved = 0;
  int version = 0;
}

typedef RowKey = (String, String, DateTime);

class InventoryStore {
  final rows = <RowKey, InventoryRow>{};
  final overbooking = <(String, String), double>{};

  void setInventory(String hotel, String type, DateTime from, DateTime to, int total, {double overbookingRate = 0}) {
    overbooking[(hotel, type)] = overbookingRate;
    for (final night in nightsOf(from, to)) {
      rows[(hotel, type, night)] = InventoryRow(total);
    }
  }

  int limitOf(String hotel, String type, InventoryRow row) =>
      (row.total * (1 + (overbooking[(hotel, type)] ?? 0)) + 1e-9).floor();

  /// Snapshot of (reserved, limit, version) per night, as a plain SELECT would return.
  List<(int, int, int)> read(String hotel, String type, List<DateTime> nights) => [
    for (final n in nights)
      if (rows[(hotel, type, n)] case final row?)
        (row.reserved, limitOf(hotel, type, row), row.version)
      else
        (0, 0, 0), // no inventory loaded for that night
  ];

  /// One transaction: for every night, apply [delta] only if its version is unchanged and the limit holds.
  bool commit(String hotel, String type, List<DateTime> nights, List<int> expectedVersions, int delta) {
    for (var i = 0; i < nights.length; i++) {
      final row = rows[(hotel, type, nights[i])];
      if (row == null || row.version != expectedVersions[i]) return false;
      final after = row.reserved + delta;
      if (after < 0 || after > limitOf(hotel, type, row)) return false;
    }
    for (final n in nights) {
      final row = rows[(hotel, type, n)]!;
      row
        ..reserved += delta
        ..version += 1;
    }
    return true;
  }
}

class RatePlan {
  const RatePlan({required this.weekday, required this.weekend});
  final int weekday;
  final int weekend;
  int priceFor(DateTime night) =>
      night.weekday == DateTime.friday || night.weekday == DateTime.saturday ? weekend : weekday;
}

enum ReservationStatus { confirmed, cancelled }

class Reservation {
  Reservation(this.id, this.hotel, this.type, this.nights, this.rooms, this.total);
  final String id;
  final String hotel;
  final String type;
  final List<DateTime> nights;
  final int rooms;
  final int total;
  ReservationStatus status = ReservationStatus.confirmed;
}

class NoAvailabilityException implements Exception {}

class ConcurrentUpdateException implements Exception {}

class ReservationService {
  ReservationService(this.store, this.rates, {this.maxRetries = 3});
  final InventoryStore store;
  final Map<(String, String), RatePlan> rates;
  final int maxRetries;
  final _byKey = <String, Reservation>{};
  final reservations = <String, Reservation>{};
  var conflicts = 0;
  var _nextId = 1;

  int available(String hotel, String type, DateTime checkIn, DateTime checkOut) =>
      store.read(hotel, type, nightsOf(checkIn, checkOut)).map((r) => r.$2 - r.$1).reduce((a, b) => a < b ? a : b);

  Reservation reserve({
    required String idempotencyKey,
    required String hotel,
    required String type,
    required DateTime checkIn,
    required DateTime checkOut,
    int rooms = 1,
    void Function()? beforeCommit, // test hook: another server acts between our read and our commit
  }) {
    final existing = _byKey[idempotencyKey];
    if (existing != null) return existing;
    final nights = nightsOf(checkIn, checkOut);
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      final snapshot = store.read(hotel, type, nights);
      if (snapshot.any((r) => r.$2 - r.$1 < rooms)) throw NoAvailabilityException();
      if (attempt == 0) beforeCommit?.call();
      if (store.commit(hotel, type, nights, [for (final r in snapshot) r.$3], rooms)) {
        final plan = rates[(hotel, type)]!;
        final total = rooms * nights.fold<int>(0, (sum, n) => sum + plan.priceFor(n));
        final r = Reservation('r${_nextId++}', hotel, type, nights, rooms, total);
        reservations[r.id] = r;
        _byKey[idempotencyKey] = r; // same transaction as the commit in a real database
        return r;
      }
      conflicts++;
    }
    throw ConcurrentUpdateException();
  }

  void cancel(String reservationId) {
    final r = reservations[reservationId]!;
    if (r.status == ReservationStatus.cancelled) return;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      final versions = [for (final s in store.read(r.hotel, r.type, r.nights)) s.$3];
      if (store.commit(r.hotel, r.type, r.nights, versions, -r.rooms)) {
        r.status = ReservationStatus.cancelled;
        return;
      }
    }
    throw ConcurrentUpdateException();
  }
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
  DateTime jan(int d) => DateTime.utc(2025, 1, d);
  final store = InventoryStore()
    ..setInventory('h1', 'deluxe', jan(1), jan(11), 2)
    ..setInventory('h1', 'standard', jan(1), jan(11), 10, overbookingRate: 0.1);
  final service = ReservationService(store, {
    ('h1', 'deluxe'): const RatePlan(weekday: 100, weekend: 150),
    ('h1', 'standard'): const RatePlan(weekday: 60, weekend: 80),
  });

  check(service.available('h1', 'deluxe', jan(1), jan(3)), 2);
  final r1 = service.reserve(idempotencyKey: 'k1', hotel: 'h1', type: 'deluxe', checkIn: jan(1), checkOut: jan(3));
  final r2 = service.reserve(idempotencyKey: 'k2', hotel: 'h1', type: 'deluxe', checkIn: jan(2), checkOut: jan(4));
  check([service.available('h1', 'deluxe', jan(1), jan(2)), service.available('h1', 'deluxe', jan(2), jan(3))], [1, 0]);

  // All or nothing: Jan 2 is full, so Jan 1 and Jan 3 must stay untouched.
  expectThrows<NoAvailabilityException>(
    () => service.reserve(idempotencyKey: 'k3', hotel: 'h1', type: 'deluxe', checkIn: jan(1), checkOut: jan(4)),
  );
  check(
    [
      for (final d in [1, 2, 3]) store.rows[('h1', 'deluxe', jan(d))]!.reserved,
    ],
    [1, 2, 1],
  );

  // Idempotent retry returns the same reservation without reserving again.
  check(
    identical(
      service.reserve(idempotencyKey: 'k1', hotel: 'h1', type: 'deluxe', checkIn: jan(1), checkOut: jan(3)),
      r1,
    ),
    true,
  );
  check(store.rows[('h1', 'deluxe', jan(1))]!.reserved, 1);

  // Cancel frees the nights; a previously impossible stay now fits.
  service.cancel(r1.id);
  final r3 = service.reserve(idempotencyKey: 'k4', hotel: 'h1', type: 'deluxe', checkIn: jan(1), checkOut: jan(4));
  check([r1.status, r3.nights.length, r2.status], [ReservationStatus.cancelled, 3, ReservationStatus.confirmed]);

  // Pricing: Thursday, Friday, Saturday nights.
  final weekend = service.reserve(
    idempotencyKey: 'k5',
    hotel: 'h1',
    type: 'standard',
    checkIn: jan(2),
    checkOut: jan(5),
    rooms: 2,
  );
  check([jan(2).weekday == DateTime.thursday, weekend.total], [true, 2 * (60 + 80 + 80)]);

  // Overbooking: 10 standard rooms with 10% allowance -> 11 sellable. Two are already taken on Jan 2-4.
  for (var i = 0; i < 9; i++) {
    service.reserve(idempotencyKey: 'ob$i', hotel: 'h1', type: 'standard', checkIn: jan(3), checkOut: jan(4));
  }
  check(store.rows[('h1', 'standard', jan(3))]!.reserved, 11);
  expectThrows<NoAvailabilityException>(
    () => service.reserve(idempotencyKey: 'ob9', hotel: 'h1', type: 'standard', checkIn: jan(3), checkOut: jan(4)),
  );

  // Optimistic concurrency: another server books the last deluxe room between our read and our commit.
  check(service.available('h1', 'deluxe', jan(8), jan(9)), 2);
  service.reserve(idempotencyKey: 'k6', hotel: 'h1', type: 'deluxe', checkIn: jan(8), checkOut: jan(9));
  final conflictsBefore = service.conflicts;
  expectThrows<NoAvailabilityException>(
    () => service.reserve(
      idempotencyKey: 'k7',
      hotel: 'h1',
      type: 'deluxe',
      checkIn: jan(8),
      checkOut: jan(9),
      beforeCommit: () =>
          service.reserve(idempotencyKey: 'k8', hotel: 'h1', type: 'deluxe', checkIn: jan(8), checkOut: jan(9)),
    ),
  );
  check([service.conflicts - conflictsBefore, store.rows[('h1', 'deluxe', jan(8))]!.reserved], [1, 2]); // never 3

  expectThrows<ArgumentError>(() => nightsOf(jan(5), jan(5)));
}
```

## 5. Walkthrough

- Two deluxe rooms: r1 takes Jan 1-2, r2 takes Jan 2-3, so Jan 2 is full.
- A stay from Jan 1 to Jan 4 includes Jan 2, so it fails, and the reserved counts stay `[1, 2, 1]`: nothing was partially applied.
- Retrying with key `k1` returns r1 without touching inventory.
- After cancelling r1, the Jan 1-4 stay fits.
- Jan 2, 2025 is a Thursday: two standard rooms for Thursday, Friday and Saturday nights cost `2 x (60 + 80 + 80)`.
- With 10% overbooking, 11 standard rooms can be sold on Jan 3 (2 from the weekend booking plus 9); the 12th is refused.
- The concurrency test: request `k7` reads one free room on Jan 8, then (via the hook) another server books it. `k7`'s commit sees a changed version and fails; the retry re-reads, finds no availability and reports it. The night never exceeds 2.

## 6. Concurrency

- In a database, `commit` is one transaction: for each night (in date order), `UPDATE room_type_inventory SET total_reserved = total_reserved + :n, version = version + 1 WHERE hotel_id = ? AND room_type_id = ? AND date = ? AND version = ? AND total_reserved + :n <= :limit`; roll back if any statement updates 0 rows.
- The idempotency key insert is in the same transaction (unique constraint), so two concurrent retries of the same request cannot both succeed.
- Search reads can come from replicas or cache; only the commit needs the primary.

## 7. Extensibility

| Change | Where |
|---|---|
| Pending holds during payment | A `pending` status with expiry; inventory is reserved, released on expiry (see 09). |
| Dynamic pricing | `RatePlan` per night from a pricing service. |
| Room assignment | At check-in, assign physical rooms to reservations with an interval-scheduling pass. |
| Minimum stay / closed dates | Validation rules checked in `reserve` before the commit. |
| Pessimistic mode for hot dates | Lock rows (`FOR UPDATE`) in date order instead of versions. |

## 8. Common mistakes in LLD rounds

- Check availability, then update, as two separate unprotected steps.
- Reserving night by night with no rollback when a later night is full.
- Booking specific rooms at search time.
- Infinite retry loops on conflicts.
- Floating-point overbooking math without care (10 x 1.1 is not exactly 11.0 in binary).

See [HLD.md](HLD.md) for search, caching, sharding and the reservation flow.
