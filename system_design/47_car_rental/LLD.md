# Car Rental System: Low-Level Design

## 1. Scope for the LLD round

- **Vehicles** of a class at a location.
- **Availability over time intervals:** a reservation occupies `[start, end + cleaning buffer)`; a new booking fits if, at every moment of its window, fewer reservations overlap than there are cars of that class at the location (peak-overlap sweep).
- **Reserve by class**, assign a **specific vehicle at pickup**.
- **Pricing:** days rounded up after a 59-minute grace, 10% off for 7+ days, one-way fee; quoted at booking.
- **Return:** late fee per started hour after a 59-minute grace, fuel charge per missing quarter tank, one-way rentals move the car to the return location.
- **Cancellation** frees capacity.

Out of scope: payments, upgrades, fleet rebalancing (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `CarClass`, `Vehicle` | Class; ID, class, location, rented flag. |
| `Reservation`, `ResStatus` | Window, pickup/return locations, quote, assigned vehicle, lifecycle. |
| `Pricing` | Rates and fee rules; `quote`, `rentalDays`, `lateFee`. |
| `Invoice` | Line items and total. |
| `RentalService` | Capacity checks, reserve, cancel, pickup, return. |

```text
RentalService --has many--> Vehicle (class, location)
     |        --has many--> Reservation(class, [start, end), pickupLoc, returnLoc, quote, vehicle?)
     |  available(loc, class, window) = cars(loc, class) - peak overlap of reservations in window (+ buffer)
     +--uses--> Pricing (quote at booking, late and fuel fees at return)
```

## 3. Design decisions and why

- **Minutes, not days,** for availability: rentals start and end at any time; a day-based model would either waste or double-book cars.
- **Peak overlap, not a simple count of overlapping reservations:** two reservations that overlap the window but not each other need only one car.
- **Cleaning buffer** added to each reservation's end: the next customer cannot get a car that has not been turned around.
- **Class-level booking, vehicle assignment at pickup:** any clean car of the class works, which maximizes utilization.
- **Quote stored with the reservation:** rate changes after booking do not change the price.

## 4. The code

```dart
import 'dart:math';

enum CarClass { economy, suv }

class Vehicle {
  Vehicle(this.id, this.cls, this.location);
  final String id;
  final CarClass cls;
  String location;
  var rented = false;
}

enum ResStatus { reserved, active, completed, cancelled }

class Reservation {
  Reservation(this.id, this.cls, this.pickupLoc, this.returnLoc, this.start, this.end, this.quote);
  final String id;
  final CarClass cls;
  final String pickupLoc;
  final String returnLoc;
  final int start; // minutes
  final int end;
  final int quote; // cents
  var status = ResStatus.reserved;
  Vehicle? vehicle;
}

class Pricing {
  const Pricing({
    this.daily = const {CarClass.economy: 4000, CarClass.suv: 7000},
    this.weeklyDiscountPercent = 10,
    this.oneWayFee = 5000,
    this.latePerHour = 1500,
    this.fuelPerQuarter = 2000,
  });
  final Map<CarClass, int> daily;
  final int weeklyDiscountPercent;
  final int oneWayFee;
  final int latePerHour;
  final int fuelPerQuarter;

  /// Whole days, rounded up after a 59-minute grace; at least one.
  static int rentalDays(int minutes) => max(1, ((minutes - 59) + 1439) ~/ 1440);

  int quote(CarClass cls, int start, int end, {required bool oneWay}) {
    final days = rentalDays(end - start);
    var base = days * daily[cls]!;
    if (days >= 7) base -= base * weeklyDiscountPercent ~/ 100;
    return base + (oneWay ? oneWayFee : 0);
  }

  int lateFee(int minutesLate) => minutesLate <= 59 ? 0 : ((minutesLate - 59) + 59) ~/ 60 * latePerHour;
}

class Invoice {
  Invoice(this.lines);
  final Map<String, int> lines;
  int get total => lines.values.fold(0, (a, b) => a + b);
  @override
  String toString() => '$lines total=$total';
}

class NotAvailable implements Exception {}

class RentalService {
  RentalService({this.pricing = const Pricing(), this.bufferMinutes = 60});
  final Pricing pricing;
  final int bufferMinutes;
  final vehicles = <Vehicle>[];
  final reservations = <String, Reservation>{};
  var _next = 1;

  int carsAt(String location, CarClass cls) => vehicles.where((v) => v.location == location && v.cls == cls).length;

  Iterable<Reservation> _blocking(String location, CarClass cls) => reservations.values.where(
    (r) => r.pickupLoc == location && r.cls == cls && (r.status == ResStatus.reserved || r.status == ResStatus.active),
  );

  /// Cars free during the whole of [start, end): capacity minus the peak number of overlapping reservations.
  int available(String location, CarClass cls, int start, int end) {
    final intervals = [
      for (final r in _blocking(location, cls))
        if (r.start < end + bufferMinutes && start < r.end + bufferMinutes) (r.start, r.end + bufferMinutes),
    ];
    final events = <(int, int)>[
      for (final (s, e) in intervals) ...[(max(s, start), 1), (e, -1)],
    ]..sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2)); // ends before starts at a tie
    var current = 0, peak = 0;
    for (final (_, delta) in events) {
      current += delta;
      peak = max(peak, current);
    }
    return carsAt(location, cls) - peak;
  }

  Reservation reserve(CarClass cls, String pickupLoc, int start, int end, {String? returnLoc}) {
    if (end <= start) throw ArgumentError('return must be after pickup');
    if (available(pickupLoc, cls, start, end) <= 0) throw NotAvailable();
    final back = returnLoc ?? pickupLoc;
    final r = Reservation(
      'r${_next++}',
      cls,
      pickupLoc,
      back,
      start,
      end,
      pricing.quote(cls, start, end, oneWay: back != pickupLoc),
    );
    return reservations[r.id] = r;
  }

  void cancel(String id) {
    final r = reservations[id]!;
    if (r.status == ResStatus.reserved) r.status = ResStatus.cancelled;
  }

  Vehicle pickup(String id) {
    final r = reservations[id]!;
    if (r.status != ResStatus.reserved) throw StateError('reservation is ${r.status.name}');
    final car = vehicles.firstWhere(
      (v) => v.location == r.pickupLoc && v.cls == r.cls && !v.rented,
      orElse: () => throw NotAvailable(),
    );
    car.rented = true;
    r
      ..vehicle = car
      ..status = ResStatus.active;
    return car;
  }

  Invoice returnCar(String id, {required int at, int fuelQuartersMissing = 0}) {
    final r = reservations[id]!;
    if (r.status != ResStatus.active) throw StateError('reservation is ${r.status.name}');
    final car = r.vehicle!
      ..rented = false
      ..location = r.returnLoc; // a one-way rental leaves the car at the destination
    r.status = ResStatus.completed;
    return Invoice({
      'rental': r.quote,
      if (at - r.end > 59) 'late': pricing.lateFee(at - r.end),
      if (fuelQuartersMissing > 0) 'fuel': fuelQuartersMissing * pricing.fuelPerQuarter,
      'vehicle ${car.id}': 0,
    });
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void main() {
  int at(int day, int hour, [int minute = 0]) => (day * 24 + hour) * 60 + minute;

  // Pricing rules.
  check([Pricing.rentalDays(24 * 60 + 30), Pricing.rentalDays(25 * 60), Pricing.rentalDays(10)], [1, 2, 1]);
  const p = Pricing();
  check(
    [
      p.quote(CarClass.economy, at(0, 10), at(2, 10), oneWay: false),
      p.quote(CarClass.economy, at(0, 10), at(8, 10), oneWay: false), // 8 days, 10% off
      p.quote(CarClass.suv, at(0, 10), at(1, 10), oneWay: true),
    ],
    [8000, 28800, 12000],
  );
  check([p.lateFee(59), p.lateFee(60), p.lateFee(190)], [0, 1500, 4500]);

  final s = RentalService()
    ..vehicles.addAll([
      Vehicle('E1', CarClass.economy, 'SFO'),
      Vehicle('E2', CarClass.economy, 'SFO'),
      Vehicle('S1', CarClass.suv, 'SFO'),
    ]);

  // Day 1 = Monday. Two cars, interval overlaps with a 60-minute cleaning buffer.
  final r1 = s.reserve(CarClass.economy, 'SFO', at(1, 10), at(3, 10)); // Mon 10:00 -> Wed 10:00
  final r2 = s.reserve(CarClass.economy, 'SFO', at(2, 9), at(4, 9)); // Tue 09:00 -> Thu 09:00
  check(
    [
      s.available('SFO', CarClass.economy, at(2, 12), at(2, 18)),
      s.available('SFO', CarClass.economy, at(0, 0), at(1, 9)),
    ],
    [0, 2],
  );
  check(() {
    try {
      s.reserve(CarClass.economy, 'SFO', at(3, 10, 30), at(5, 10)); // r1's car is still being cleaned until 11:00
      return 'booked';
    } on NotAvailable {
      return 'not available';
    }
  }(), 'not available');
  final r3 = s.reserve(CarClass.economy, 'SFO', at(3, 11, 30), at(5, 10)); // after r1's buffer: fits
  check(r3.quote, 8000);

  // Peak overlap, not a plain count: r4 and r5 do not overlap each other, so the single SUV covers both.
  final r4 = s.reserve(CarClass.suv, 'SFO', at(10, 8), at(10, 12));
  final r5 = s.reserve(CarClass.suv, 'SFO', at(10, 14), at(10, 18));
  check([s.available('SFO', CarClass.suv, at(10, 0), at(11, 0)), r4.quote + r5.quote], [0, 14000]);
  s.cancel(r5.id);
  check(s.available('SFO', CarClass.suv, at(10, 14), at(10, 18)), 1);

  // Pickup assigns real cars; a late, one-way return moves the car and adds fees.
  check([s.pickup(r1.id).id, s.pickup(r2.id).id], ['E1', 'E2']);
  final oneWay = s.reserve(CarClass.suv, 'SFO', at(20, 9), at(22, 9), returnLoc: 'LAX');
  check(oneWay.quote, 2 * 7000 + 5000);
  s.pickup(oneWay.id);
  final invoice = s.returnCar(oneWay.id, at: at(22, 12, 10), fuelQuartersMissing: 2); // 3h10m late
  check(invoice, '{rental: 19000, late: 4500, fuel: 4000, vehicle S1: 0} total=27500');
  check([s.vehicles.firstWhere((v) => v.id == 'S1').location, s.carsAt('SFO', CarClass.suv)], ['LAX', 0]);
}
```

## 5. Walkthrough

- 24 h 30 min is one day (30 minutes over is within the 59-minute grace); 25 h is two days; ten minutes is billed as one day.
- Two days of economy cost 8,000; eight days 32,000 minus 10% = 28,800; a one-day SUV one-way rental is 7,000 + 5,000.
- Late fees: 59 minutes free; 60 minutes is one hour; 3 h 10 min is 3 started hours after the grace (4,500).
- Both economy cars are busy on Tuesday afternoon (r1 and r2), so availability there is 0, while Monday morning shows 2.
- A booking starting Wednesday 10:30 fails because r1's car returns at 10:00 and is cleaned until 11:00 while r2 still holds the other car; 11:30 works.
- r4 (8:00-12:00) and r5 (14:00-18:00) on day 10 do not overlap each other, so the single SUV can serve both; for the whole day, availability is 0. Cancelling r5 frees the afternoon.
- At pickup, r1 gets E1 and r2 gets E2. The one-way SUV to LAX costs 19,000; returned 3 h 10 min late and half a tank short, the invoice adds 4,500 and 4,000, and the SUV now belongs to LAX.

## 6. Concurrency

- The availability check and the insert must be atomic per (location, class): lock that row (or a per-location-class advisory lock) in the reservation transaction, or re-check after insert and roll back on conflict.
- Pickup assignment uses a conditional update on the vehicle (`WHERE rented = false`), so two counters cannot hand out the same car.
- Fleet location changes (one-way returns, transfers) update capacity; searches use a cached projection that is refreshed on these events.

## 7. Extensibility

| Change | Where |
|---|---|
| Upgrades | When a class is full, try the next class at the same price. |
| Overbooking | Allow `available` to go slightly negative per policy. |
| Arrivals from one-way rentals | Count cars scheduled to arrive at a location before the window starts. |
| Mileage limits | Record odometer at pickup/return; charge per extra km. |
| Maintenance | Vehicle status excluded from capacity during service windows. |

## 8. Common mistakes in LLD rounds

- Counting every overlapping reservation instead of the peak concurrent number.
- Forgetting turnaround time between rentals.
- Assigning specific cars at booking time.
- Not moving the car on one-way returns.

See [HLD.md](HLD.md) for the fleet-wide system.
