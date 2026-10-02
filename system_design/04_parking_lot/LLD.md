# Parking Lot: Low-Level Design

This is the version most interviewers mean by "design a parking lot": classes, relationships, patterns and working code in 45 minutes.

## 1. Scope for the LLD round

Agree on these with the interviewer before drawing classes:

- A lot has several **levels**; each level has spots of three sizes: **small, compact, large**.
- Vehicles: **motorcycle** (needs small), **car** (needs compact), **truck** (needs large). A vehicle may use a **bigger** spot if its own size is full, never a smaller one.
- Entry issues a **ticket**; exit computes the **fee** and frees the spot.
- Pricing: hourly per vehicle size, partial hours round up, a free grace period, a daily cap.
- Allocation rule is configurable (nearest first, or spread load across levels).
- Display boards show free spots per size and update on every change.

Out of scope: payments, gates hardware, reservations (see HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `SpotSize`, `VehicleType` (enums) | Sizes are ordered; each vehicle type knows the smallest size it needs. |
| `Vehicle` | Plate and type. |
| `ParkingSpot` | ID, level, size, current occupant. |
| `Level` | Its spots, and free spots per size in an ordered set: O(log n) take and release. |
| `Ticket` | Issued at entry; completed at exit with exit time and fee. |
| `SpotAllocationStrategy` (interface) | Picks a free spot for a vehicle: `NearestFirstStrategy`, `SpreadAcrossLevelsStrategy`. |
| `PricingStrategy` (interface) | Fee for a size and duration: `HourlyPricing`. |
| `AvailabilityListener` (interface) | Observer notified on every change, for example a `DisplayBoard`. |
| `ParkingLot` | Facade: `park`, `unpark`, `availability`. Owns tickets and the plate index. |

```text
               +-------------------- ParkingLot (facade) --------------------+
               |                 |                  |                        |
          has many           uses (strategy)    uses (strategy)        notifies (observer)
               v                 v                  v                        v
             Level      SpotAllocationStrategy  PricingStrategy      AvailabilityListener
               |          ^            ^             ^                       ^
          has many        |            |             |                       |
               v     NearestFirst  SpreadAcross  HourlyPricing          DisplayBoard
          ParkingSpot --occupied by--> Vehicle
      Ticket --refers to--> ParkingSpot, Vehicle
```

## 3. Design decisions and why

- **Enums with behavior** (`VehicleType.minSize`) instead of a `Vehicle` class hierarchy. Subclasses `Car`, `Truck` that only differ by one value add nothing; use inheritance only when behavior differs.
- **Strategy for allocation and pricing**: these are the parts that change between lots and over time (Open/Closed). The `ParkingLot` does not contain any pricing math or spot-search loops.
- **Observer for display boards**: the lot does not know what boards exist.
- **Free spots indexed per level per size** in sorted sets: allocation is `O(levels x sizes x log n)` instead of scanning every spot.
- **Plate index** (`plate -> ticket`) rejects a car that is already inside (catches duplicate gate events or cloned plates).
- **Injected clock** so fees are testable.
- **Typed exceptions** (`LotFullException`, `AlreadyParkedException`, `UnknownTicketException`) instead of returning `null` or magic values.
- **Charge by the vehicle's size, not the spot's.** A car pushed into a large spot pays the car rate. This is a business rule; state it and make it easy to change.

## 4. The code

```dart
import 'dart:collection';

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

// ---------- Core types ----------

enum SpotSize { small, compact, large }

enum VehicleType {
  motorcycle(SpotSize.small),
  car(SpotSize.compact),
  truck(SpotSize.large);

  const VehicleType(this.minSize);
  final SpotSize minSize;

  bool fits(SpotSize size) => size.index >= minSize.index;
}

class Vehicle {
  const Vehicle(this.plate, this.type);
  final String plate;
  final VehicleType type;
}

class ParkingSpot {
  ParkingSpot({required this.level, required this.number, required this.size});
  final int level;
  final int number;
  final SpotSize size;
  Vehicle? occupant;

  String get id => 'L$level-${size.name[0].toUpperCase()}$number';
  bool get isFree => occupant == null;
}

class Level {
  Level(this.number, Map<SpotSize, int> spotsPerSize) {
    var n = 1;
    for (final size in SpotSize.values) {
      final free = SplayTreeSet<ParkingSpot>((a, b) => a.number.compareTo(b.number));
      for (var i = 0; i < (spotsPerSize[size] ?? 0); i++) {
        final spot = ParkingSpot(level: number, number: n++, size: size);
        spots.add(spot);
        free.add(spot);
      }
      _free[size] = free;
    }
  }

  final int number;
  final List<ParkingSpot> spots = [];
  final Map<SpotSize, SplayTreeSet<ParkingSpot>> _free = {};

  int freeCount(SpotSize size) => _free[size]!.length;

  /// Lowest-numbered free spot of this size, or null.
  ParkingSpot? firstFree(SpotSize size) => _free[size]!.firstOrNull;

  void occupy(ParkingSpot spot, Vehicle v) {
    if (!spot.isFree) throw StateError('${spot.id} is taken');
    spot.occupant = v;
    _free[spot.size]!.remove(spot);
  }

  void release(ParkingSpot spot) {
    spot.occupant = null;
    _free[spot.size]!.add(spot);
  }
}

class Ticket {
  Ticket({required this.id, required this.vehicle, required this.spot, required this.entryTime});
  final String id;
  final Vehicle vehicle;
  final ParkingSpot spot;
  final DateTime entryTime;
  DateTime? exitTime;
  int? feeCents;

  bool get isClosed => exitTime != null;
}

// ---------- Exceptions ----------

class LotFullException implements Exception {
  LotFullException(this.type);
  final VehicleType type;
  @override
  String toString() => 'LotFullException: no spot for ${type.name}';
}

class AlreadyParkedException implements Exception {
  AlreadyParkedException(this.plate);
  final String plate;
}

class UnknownTicketException implements Exception {
  UnknownTicketException(this.ticketId);
  final String ticketId;
}

// ---------- Strategies ----------

abstract interface class SpotAllocationStrategy {
  ParkingSpot? choose(List<Level> levels, Vehicle vehicle);
}

/// Smallest fitting size first (keeps big spots for big vehicles), then lowest level, then lowest number.
class NearestFirstStrategy implements SpotAllocationStrategy {
  @override
  ParkingSpot? choose(List<Level> levels, Vehicle vehicle) {
    for (final size in SpotSize.values.where(vehicle.type.fits)) {
      for (final level in levels) {
        final spot = level.firstFree(size);
        if (spot != null) return spot;
      }
    }
    return null;
  }
}

/// Smallest fitting size first, then the level with the most free spots of that size.
class SpreadAcrossLevelsStrategy implements SpotAllocationStrategy {
  @override
  ParkingSpot? choose(List<Level> levels, Vehicle vehicle) {
    for (final size in SpotSize.values.where(vehicle.type.fits)) {
      Level? best;
      for (final level in levels) {
        if (level.freeCount(size) > 0 && (best == null || level.freeCount(size) > best.freeCount(size))) {
          best = level;
        }
      }
      if (best != null) return best.firstFree(size);
    }
    return null;
  }
}

abstract interface class PricingStrategy {
  int feeCents(VehicleType type, Duration parked);
}

class HourlyPricing implements PricingStrategy {
  HourlyPricing({required this.centsPerHour, required this.dailyCapCents, required this.gracePeriod});

  final Map<SpotSize, int> centsPerHour;
  final int dailyCapCents;
  final Duration gracePeriod;

  @override
  int feeCents(VehicleType type, Duration parked) {
    if (parked <= gracePeriod) return 0;
    final rate = centsPerHour[type.minSize]!;
    final fullDays = parked.inMinutes ~/ (24 * 60);
    final restMinutes = parked.inMinutes - fullDays * 24 * 60;
    final restHours = (restMinutes + 59) ~/ 60; // partial hours round up
    final restFee = restHours * rate;
    return fullDays * dailyCapCents + (restFee < dailyCapCents ? restFee : dailyCapCents);
  }
}

// ---------- Observer ----------

abstract interface class AvailabilityListener {
  void onAvailabilityChanged(Map<SpotSize, int> free);
}

class DisplayBoard implements AvailabilityListener {
  String text = '';
  @override
  void onAvailabilityChanged(Map<SpotSize, int> free) =>
      text = [for (final e in free.entries) '${e.key.name}:${e.value}'].join(' ');
}

// ---------- Facade ----------

class ParkingLot {
  ParkingLot({
    required this.levels,
    required SpotAllocationStrategy allocation,
    required PricingStrategy pricing,
    required Clock clock,
  }) : _allocation = allocation,
       _pricing = pricing,
       _clock = clock;

  final List<Level> levels;
  final SpotAllocationStrategy _allocation;
  final PricingStrategy _pricing;
  final Clock _clock;
  final _tickets = <String, Ticket>{};
  final _activeByPlate = <String, Ticket>{};
  final _listeners = <AvailabilityListener>[];
  var _nextTicket = 1;

  void addListener(AvailabilityListener l) {
    _listeners.add(l);
    l.onAvailabilityChanged(availability());
  }

  Map<SpotSize, int> availability() => {
    for (final size in SpotSize.values) size: levels.fold(0, (sum, l) => sum + l.freeCount(size)),
  };

  Ticket park(Vehicle vehicle) {
    if (_activeByPlate.containsKey(vehicle.plate)) throw AlreadyParkedException(vehicle.plate);
    final spot = _allocation.choose(levels, vehicle);
    if (spot == null) throw LotFullException(vehicle.type);
    levels.firstWhere((l) => l.number == spot.level).occupy(spot, vehicle);
    final ticket = Ticket(id: 'T${_nextTicket++}', vehicle: vehicle, spot: spot, entryTime: _clock.now());
    _tickets[ticket.id] = ticket;
    _activeByPlate[vehicle.plate] = ticket;
    _notify();
    return ticket;
  }

  Ticket unpark(String ticketId) {
    final ticket = _tickets[ticketId];
    if (ticket == null || ticket.isClosed) throw UnknownTicketException(ticketId);
    ticket
      ..exitTime = _clock.now()
      ..feeCents = _pricing.feeCents(ticket.vehicle.type, _clock.now().difference(ticket.entryTime));
    levels.firstWhere((l) => l.number == ticket.spot.level).release(ticket.spot);
    _activeByPlate.remove(ticket.vehicle.plate);
    _notify();
    return ticket;
  }

  void _notify() {
    final free = availability();
    for (final l in _listeners) {
      l.onAvailabilityChanged(free);
    }
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

ParkingLot buildLot(SpotAllocationStrategy allocation, Clock clock) => ParkingLot(
  levels: [
    Level(0, {SpotSize.small: 1, SpotSize.compact: 2, SpotSize.large: 1}),
    Level(1, {SpotSize.compact: 2, SpotSize.large: 1}),
  ],
  allocation: allocation,
  pricing: HourlyPricing(
    centsPerHour: {SpotSize.small: 100, SpotSize.compact: 300, SpotSize.large: 600},
    dailyCapCents: 2000,
    gracePeriod: const Duration(minutes: 10),
  ),
  clock: clock,
);

void main() {
  final clock = FakeClock(DateTime.utc(2025, 1, 1, 8));
  final lot = buildLot(NearestFirstStrategy(), clock);
  final board = DisplayBoard();
  lot.addListener(board);
  check(board.text, 'small:1 compact:4 large:2');

  // Allocation: smallest fitting size, nearest level; overflow to a bigger size.
  final bike1 = lot.park(const Vehicle('M-1', VehicleType.motorcycle));
  check(bike1.spot.id, 'L0-S1');
  final bike2 = lot.park(const Vehicle('M-2', VehicleType.motorcycle));
  check(bike2.spot.id, 'L0-C2'); // small is full, so the smallest bigger size
  final car1 = lot.park(const Vehicle('C-1', VehicleType.car));
  check(car1.spot.id, 'L0-C3');
  final car2 = lot.park(const Vehicle('C-2', VehicleType.car));
  check(car2.spot.id, 'L1-C1'); // level 0 compacts are full
  check(board.text, 'small:0 compact:1 large:2');

  expectThrows<AlreadyParkedException>(() => lot.park(const Vehicle('C-1', VehicleType.car)));

  final truck1 = lot.park(const Vehicle('T-1', VehicleType.truck));
  final truck2 = lot.park(const Vehicle('T-2', VehicleType.truck));
  check([truck1.spot.id, truck2.spot.id], ['L0-L4', 'L1-L3']);
  expectThrows<LotFullException>(() => lot.park(const Vehicle('T-3', VehicleType.truck)));

  // Pricing: grace period, rounding up, daily cap. Charged by vehicle size, not spot size.
  clock.advance(const Duration(minutes: 5));
  check(lot.unpark(bike1.id).feeCents, 0); // within grace
  clock.advance(const Duration(hours: 2, minutes: 25)); // 2h30m since entry
  check(lot.unpark(car1.id).feeCents, 900); // 3 started hours x 300
  check(lot.unpark(bike2.id).feeCents, 300); // motorcycle rate even though it used a compact spot
  clock.advance(const Duration(hours: 9)); // 11h30m
  check(lot.unpark(truck1.id).feeCents, 2000); // 12 x 600 = 7200, capped at 2000
  clock.advance(const Duration(hours: 14, minutes: 30)); // 26h
  check(lot.unpark(car2.id).feeCents, 2600); // one day cap + 2 hours

  expectThrows<UnknownTicketException>(() => lot.unpark(car2.id)); // already closed
  expectThrows<UnknownTicketException>(() => lot.unpark('T999'));

  // Freed spots are reused, lowest number first; the same plate can park again after leaving.
  check(lot.park(const Vehicle('C-1', VehicleType.car)).spot.id, 'L0-C2');
  check(board.text, 'small:1 compact:3 large:1');

  // A different strategy, same lot code.
  final spread = buildLot(SpreadAcrossLevelsStrategy(), FakeClock(DateTime.utc(2025)));
  final a = spread.park(const Vehicle('A', VehicleType.car));
  final b = spread.park(const Vehicle('B', VehicleType.car));
  final c = spread.park(const Vehicle('C', VehicleType.car));
  check([a.spot.id, b.spot.id, c.spot.id], ['L0-C2', 'L1-C1', 'L0-C3']);
}
```

## 5. Walkthrough

- Spot numbers run across sizes within a level, so level 0 is `S1, C2, C3, L4` and level 1 is `C1, C2, L3`.
- The second motorcycle finds no small spot, so the strategy moves to the next size up (compact) **before** moving to the next level. This is a choice: an alternative is "same size on any level first, then bigger". Keeping big spots for big vehicles usually matters more.
- Fees: 2 h 30 min is 3 started hours (900); the truck's 12 hours (7,200) hit the 2,000 cap; 26 hours is one capped day plus 2 hours.
- With `SpreadAcrossLevelsStrategy`, ties go to the first level, then the level with more free compacts wins, alternating the load.

## 6. Concurrency

- Two entry gates calling `park` at once could pick the same free spot. Options: one lock around `choose + occupy` (simple, plenty fast for a garage), or optimistic `occupy` that fails if taken and retries the search.
- The ticket counter and the plate index are shared state too; keep them under the same lock, or use an atomic counter and a concurrent map with `putIfAbsent` for the plate.
- In the HLD, one controller per garage is the single writer, which removes the race entirely.

## 7. Extensibility

| Change | Where |
|---|---|
| EV spots / accessible spots | Add `features` to `ParkingSpot`; the strategy filters by required features. |
| Electric vehicle charging fee | Decorate `PricingStrategy` (`ChargingPricing(base, centsPerKwh)`). |
| Weekend or night rates | New `PricingStrategy` that picks a rate table by entry time. |
| Reservations | A `ReservationService` that holds capacity; `park` checks it before the strategy. |
| Multiple entry gates, payment at exit | `EntryGate` / `ExitGate` classes calling the facade; `PaymentProcessor` interface. |
| A new vehicle type (van) | One enum value with its `minSize`; nothing else changes. |

## 8. Common mistakes in LLD rounds

- A deep class hierarchy (`Car extends Vehicle`, `CompactSpot extends Spot`) with no behavior differences.
- Pricing and search logic inside `ParkingLot` as one long method.
- Scanning every spot on every entry.
- Not handling: lot full, duplicate entry, exit with an unknown or already used ticket.
- Forgetting the exit flow and fee calculation entirely.
- Floating-point money; use integer cents.

See [HLD.md](HLD.md) for the multi-garage service with gates, reservations and offline mode.
