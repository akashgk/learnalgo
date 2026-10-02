# Ride Sharing: Low-Level Design

## 1. Scope for the LLD round

- Drivers go online/offline and send locations; a **grid index** answers "available drivers near this point", nearest first.
- A rider requests a ride; the service **offers** it to the nearest available driver, **reserving** that driver so no other trip can take them.
- Driver **accepts**, **declines**, or the offer **times out**; declines and timeouts move to the next candidate and never re-offer to the same driver for that trip.
- A **trip state machine** rejects invalid transitions.
- Fare via a **strategy** (base + distance + time, surge multiplier, minimum fare).
- Rider cancellation releases the driver.

Out of scope: real road-network ETAs, payments, push delivery (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Location` | Latitude/longitude; haversine distance in km. |
| `GridIndex` | Driver positions bucketed into lat/lng cells; `nearby(point, radiusKm)` sorted by distance. |
| `Driver` / `DriverStatus` | Driver data; `offline -> available -> offered -> onTrip -> available`. |
| `Trip` / `TripStatus` | A ride and its lifecycle; transition table enforced in one place. |
| `FareStrategy` | `fareCents(km, minutes, surge)`; `StandardFare` implementation. |
| `RideService` | Facade: drivers, requests, offers, accept/decline/timeout, trip progress, cancel. |

```text
RideService --uses--> GridIndex (only available drivers are indexed)
     |       --uses--> FareStrategy (interface) <-- StandardFare
     +--has many--> Driver (status: offline | available | offered | onTrip)
     +--has many--> Trip --status--> TripStatus (transition table)
```

## 3. Design decisions and why

- **Only available drivers live in the grid index.** Matching never needs to filter busy drivers, and removing a driver from the index is the reservation's first step.
- **Reservation = status change `available -> offered`** done before the offer is sent. With concurrency this is a compare-and-set; here, the single-threaded service makes it trivially atomic.
- **The transition table is data** (`TripStatus.allowedNext`), so the rules are visible in one place and every method goes through `_transition`, which also records history.
- **Declined drivers per trip** are remembered so the next candidate is someone else.
- **Grid cells** of 0.01 degrees (~1.1 km): search the rings of cells covering the radius, then filter by exact distance. A geohash or H3 index has the same shape: cell lookup plus exact filter.
- **Integer cents** for money; the surge multiplier is applied once at the end.

## 4. The code

```dart
import 'dart:math';

// ---------- Geometry ----------

class Location {
  const Location(this.lat, this.lng);
  final double lat;
  final double lng;

  static const earthRadiusKm = 6371.0;

  double distanceKm(Location o) {
    double rad(double d) => d * pi / 180;
    final dLat = rad(o.lat - lat), dLng = rad(o.lng - lng);
    final h = pow(sin(dLat / 2), 2) + cos(rad(lat)) * cos(rad(o.lat)) * pow(sin(dLng / 2), 2);
    return 2 * earthRadiusKm * asin(sqrt(h));
  }

  /// A point [km] due north (negative: south). Exact along a meridian.
  Location north(double km) => Location(lat + km / (earthRadiusKm * pi / 180), lng);
}

class GridIndex {
  GridIndex({this.cellDeg = 0.01});
  final double cellDeg;
  final _cells = <(int, int), Set<String>>{};
  final _where = <String, Location>{};

  (int, int) _cellOf(Location p) => ((p.lat / cellDeg).floor(), (p.lng / cellDeg).floor());

  void upsert(String id, Location p) {
    final old = _where[id];
    if (old != null) {
      final oldCell = _cellOf(old), newCell = _cellOf(p);
      if (oldCell == newCell) {
        _where[id] = p; // common case: same cell, update in place
        return;
      }
      _removeFromCell(id, oldCell);
    }
    _where[id] = p;
    _cells.putIfAbsent(_cellOf(p), () => {}).add(id);
  }

  void remove(String id) {
    final old = _where.remove(id);
    if (old != null) _removeFromCell(id, _cellOf(old));
  }

  void _removeFromCell(String id, (int, int) cell) {
    final set = _cells[cell]!..remove(id);
    if (set.isEmpty) _cells.remove(cell);
  }

  /// IDs within [radiusKm], nearest first.
  List<String> nearby(Location p, double radiusKm) {
    final kmPerDegLat = Location.earthRadiusKm * pi / 180;
    final kmPerDegLng = kmPerDegLat * cos(p.lat * pi / 180);
    final rings = (max(radiusKm / kmPerDegLat, radiusKm / kmPerDegLng) / cellDeg).ceil();
    final (ci, cj) = _cellOf(p);
    final found = <(String, double)>[];
    for (var i = ci - rings; i <= ci + rings; i++) {
      for (var j = cj - rings; j <= cj + rings; j++) {
        for (final id in _cells[(i, j)] ?? const <String>{}) {
          final d = _where[id]!.distanceKm(p);
          if (d <= radiusKm) found.add((id, d));
        }
      }
    }
    found.sort((a, b) => a.$2.compareTo(b.$2));
    return [for (final f in found) f.$1];
  }
}

// ---------- Drivers, trips, pricing ----------

enum DriverStatus { offline, available, offered, onTrip }

class Driver {
  Driver(this.id, this.location);
  final String id;
  Location location;
  DriverStatus status = DriverStatus.offline;
}

enum TripStatus {
  matching,
  accepted,
  arrived,
  inProgress,
  completed,
  cancelled,
  noDriver;

  Set<TripStatus> get allowedNext => switch (this) {
    matching => {accepted, cancelled, noDriver},
    accepted => {arrived, cancelled},
    arrived => {inProgress, cancelled},
    inProgress => {completed},
    completed || cancelled || noDriver => {},
  };
}

class Trip {
  Trip(this.id, this.riderId, this.pickup, this.dropoff, this.surge);
  final String id;
  final String riderId;
  final Location pickup;
  final Location dropoff;
  final double surge;
  TripStatus status = TripStatus.matching;
  String? driverId; // the offered driver while matching, then the assigned driver
  int? fareCents;
  final declinedBy = <String>{};
  final history = <TripStatus>[TripStatus.matching];
}

class InvalidTransitionException implements Exception {
  InvalidTransitionException(this.from, this.to);
  final TripStatus from;
  final TripStatus to;
  @override
  String toString() => 'cannot go from ${from.name} to ${to.name}';
}

class NotYourTripException implements Exception {}

abstract interface class FareStrategy {
  int fareCents(double km, int minutes, double surge);
}

class StandardFare implements FareStrategy {
  const StandardFare({
    required this.baseCents,
    required this.perKmCents,
    required this.perMinCents,
    required this.minCents,
  });
  final int baseCents;
  final int perKmCents;
  final int perMinCents;
  final int minCents;

  @override
  int fareCents(double km, int minutes, double surge) {
    final raw = ((baseCents + perKmCents * km + perMinCents * minutes) * surge).round();
    return raw < minCents ? minCents : raw;
  }
}

// ---------- Service ----------

class RideService {
  RideService({required this.fare, this.searchRadiusKm = 6});

  final FareStrategy fare;
  final double searchRadiusKm;
  final index = GridIndex();
  final drivers = <String, Driver>{};
  final trips = <String, Trip>{};
  var _nextTrip = 1;

  // --- drivers ---

  void goOnline(String driverId, Location at) {
    final d = drivers.putIfAbsent(driverId, () => Driver(driverId, at))..location = at;
    if (d.status == DriverStatus.offline) {
      d.status = DriverStatus.available;
      index.upsert(driverId, at);
    }
  }

  void goOffline(String driverId) {
    final d = drivers[driverId]!;
    if (d.status != DriverStatus.available) throw StateError('driver $driverId is busy');
    d.status = DriverStatus.offline;
    index.remove(driverId);
  }

  void updateLocation(String driverId, Location at) {
    final d = drivers[driverId]!..location = at;
    if (d.status == DriverStatus.available) index.upsert(driverId, at);
  }

  // --- matching ---

  Trip requestRide(String riderId, Location pickup, Location dropoff, {double surge = 1.0}) {
    final trip = Trip('t${_nextTrip++}', riderId, pickup, dropoff, surge);
    trips[trip.id] = trip;
    _offerNext(trip);
    return trip;
  }

  void _offerNext(Trip trip) {
    for (final id in index.nearby(trip.pickup, searchRadiusKm)) {
      if (trip.declinedBy.contains(id)) continue;
      final d = drivers[id]!;
      // Reserve: available -> offered. With threads this must be a compare-and-set.
      d.status = DriverStatus.offered;
      index.remove(id);
      trip.driverId = id;
      return; // in production: push the offer and start a ~15 s timer that calls offerTimedOut
    }
    trip.driverId = null;
    _transition(trip, TripStatus.noDriver);
  }

  void _release(String driverId) {
    final d = drivers[driverId]!..status = DriverStatus.available;
    index.upsert(driverId, d.location);
  }

  Trip _offeredTrip(String tripId, String driverId) {
    final trip = trips[tripId]!;
    if (trip.status != TripStatus.matching || trip.driverId != driverId) throw NotYourTripException();
    return trip;
  }

  void accept(String tripId, String driverId) {
    final trip = _offeredTrip(tripId, driverId);
    _transition(trip, TripStatus.accepted);
    drivers[driverId]!.status = DriverStatus.onTrip;
  }

  void decline(String tripId, String driverId) {
    final trip = _offeredTrip(tripId, driverId);
    trip.declinedBy.add(driverId);
    _release(driverId);
    _offerNext(trip);
  }

  void offerTimedOut(String tripId) {
    final trip = trips[tripId]!;
    if (trip.status == TripStatus.matching && trip.driverId != null) decline(tripId, trip.driverId!);
  }

  // --- trip progress ---

  void arrived(String tripId) => _transition(trips[tripId]!, TripStatus.arrived);
  void start(String tripId) => _transition(trips[tripId]!, TripStatus.inProgress);

  int complete(String tripId, {required double km, required int minutes}) {
    final trip = trips[tripId]!;
    _transition(trip, TripStatus.completed);
    trip.fareCents = fare.fareCents(km, minutes, trip.surge);
    drivers[trip.driverId!]!.location = trip.dropoff;
    _release(trip.driverId!);
    return trip.fareCents!;
  }

  void cancel(String tripId) {
    final trip = trips[tripId]!;
    final hadDriver = trip.driverId;
    _transition(trip, TripStatus.cancelled);
    if (hadDriver != null) _release(hadDriver); // offered or assigned driver goes back to the pool
  }

  void _transition(Trip trip, TripStatus to) {
    if (!trip.status.allowedNext.contains(to)) throw InvalidTransitionException(trip.status, to);
    trip
      ..status = to
      ..history.add(to);
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
  const pickup = Location(12.9716, 77.5946);
  final dropoff = pickup.north(8);
  check(pickup.distanceKm(pickup.north(1.5)).toStringAsFixed(3), '1.500');
  check((pickup.distanceKm(const Location(12.9716, 77.6046)) * 10).round() / 10, 1.1); // 0.01 deg lng

  final service = RideService(
    fare: const StandardFare(baseCents: 250, perKmCents: 120, perMinCents: 30, minCents: 500),
  );
  service
    ..goOnline('d1', pickup.north(0.5))
    ..goOnline('d2', pickup.north(-1.5))
    ..goOnline('d3', pickup.north(5))
    ..goOnline('d4', pickup.north(0.1));
  service.goOffline('d4');

  // Grid index: within radius, nearest first, offline drivers excluded.
  check(service.index.nearby(pickup, 2), ['d1', 'd2']);
  check(service.index.nearby(pickup, 6), ['d1', 'd2', 'd3']);
  service.updateLocation('d3', pickup.north(1.0)); // moves into another cell
  check(service.index.nearby(pickup, 2), ['d1', 'd3', 'd2']);
  service.updateLocation('d3', pickup.north(5));

  // Two concurrent requests never get the same driver.
  final t1 = service.requestRide('r1', pickup, dropoff, surge: 1.5);
  final t2 = service.requestRide('r2', pickup, dropoff);
  check([t1.driverId, t2.driverId], ['d1', 'd2']);
  check(service.drivers['d1']!.status, DriverStatus.offered);

  // Decline: offered to the next nearest available driver, never back to the same one.
  service.decline(t1.id, 'd1');
  check(t1.driverId, 'd3');
  expectThrows<NotYourTripException>(() => service.accept(t1.id, 'd1'));

  // Happy path through the state machine; invalid jumps are rejected.
  service.accept(t1.id, 'd3');
  check(service.drivers['d3']!.status, DriverStatus.onTrip);
  expectThrows<InvalidTransitionException>(() => service.start(t1.id)); // must arrive first
  service
    ..arrived(t1.id)
    ..start(t1.id);
  expectThrows<InvalidTransitionException>(() => service.cancel(t1.id)); // cannot cancel mid-trip
  check(service.complete(t1.id, km: 8, minutes: 20), 2715); // (250 + 960 + 600) x 1.5
  check(t1.history.map((s) => s.name), '(matching, accepted, arrived, inProgress, completed)');
  check(service.drivers['d3']!.status, DriverStatus.available);
  check(service.index.nearby(dropoff, 0.1), ['d3']); // indexed again at the drop-off point

  // Timeout moves on (d1 is free again after declining t1); rider cancel releases the offered driver.
  service.offerTimedOut(t2.id);
  check(t2.driverId, 'd1');
  service.cancel(t2.id);
  check([t2.status, service.drivers['d1']!.status], [TripStatus.cancelled, DriverStatus.available]);

  // Nobody nearby.
  final far = service.requestRide('r3', const Location(13.5, 78.5), dropoff);
  check([far.status, far.driverId], [TripStatus.noDriver, null]);

  // Minimum fare.
  check(const StandardFare(baseCents: 250, perKmCents: 120, perMinCents: 30, minCents: 500).fareCents(0.5, 2, 1), 500);
}
```

## 5. Walkthrough

- `d4` went offline, so it never appears even though it is the closest. Moving `d3` 1 km north of the pickup relocates it to a different cell, and the index finds it there.
- `t1` reserves `d1`; `t2` then sees only `d2` and `d3` as available and reserves `d2`, the nearer one.
- `d1` declines `t1`: `d1` returns to the pool, but `t1` remembers the decline and offers `d3`. A late `accept` from `d1` is rejected.
- After completion, the fare is `(250 + 120 x 8 + 30 x 20) x 1.5 = 2715` cents, and `d3` is indexed again at the drop-off point.
- `t2`'s offer to `d2` times out; `d1` (free again) gets the offer, and the rider's cancellation returns `d1` to the pool.

## 6. Concurrency

- **Reservation is the critical section.** With many matching threads: an atomic compare-and-set on the driver's status (`UPDATE drivers SET status = 'offered', trip_id = ? WHERE id = ? AND status = 'available'`, or a Redis Lua script). If it fails, take the next candidate.
- **Accept vs timeout race:** both are conditional on `trip.status == matching && trip.driverId == d`; whichever commits first wins, and the other gets "not your trip".
- **Trip transitions** use optimistic concurrency (`version` column) so two devices cannot move the trip from the same state twice.
- Location updates are last-writer-wins by timestamp; drop updates older than the stored one.

## 7. Extensibility

| Change | Where |
|---|---|
| Rank by ETA, rating, acceptance rate | A `DriverRanker` strategy applied to `nearby` results in `_offerNext`. |
| Vehicle types (XL, premium) | One grid index per type, or a type filter in `_offerNext`. |
| Surge per area | `SurgeCalculator` from demand and supply per cell; stored on the trip at request time. |
| Cancellation fees | In `cancel`: charge when the trip is `accepted` for more than N minutes. |
| H3 or geohash | Replace `GridIndex` behind the same `upsert` / `remove` / `nearby` interface. |

## 8. Common mistakes in LLD rounds

- Scanning all drivers for every request.
- No `offered` state: the same driver gets two offers.
- Trip status as free-form strings changed anywhere in the code.
- Forgetting declines, timeouts and cancellation.
- Floating-point money.

See [HLD.md](HLD.md) for location ingestion, the matching service and surge pricing.
