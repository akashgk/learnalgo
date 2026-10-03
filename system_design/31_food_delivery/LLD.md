# Food Delivery: Low-Level Design

## 1. Scope for the LLD round

- **Order state machine:** placed -> accepted -> preparing -> ready -> picked up -> delivered, plus cancelled; invalid transitions rejected.
- **Cancellation policy:** full refund before preparation starts, half after, none possible after pickup; restaurant rejection refunds fully.
- **ETA:** pickup = max(courier arrival at the restaurant, food ready time); delivery = pickup + travel to the customer.
- **Readiness-aware dispatch:** among free couriers, choose the earliest pickup, then the **least courier waiting** (do not burn a nearby courier's time waiting for food).
- **Batching:** a second order from the same restaurant, ready within 5 minutes of the first, with a drop-off within 2 km, rides with the same courier (capacity 2).

Out of scope: maps and real routing (Manhattan distance here), payments, tracking transport (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Point`, `travelMinutes` | Grid locations, Manhattan distance, travel time at a fixed speed. |
| `Restaurant` | Location and typical prep time. |
| `Order`, `OrderStatus` | Lifecycle, ready time, assigned courier, refund. |
| `Courier` | Location, capacity, assigned orders. |
| `DeliveryService` | Clock, transitions, cancellation policy, ETA, dispatch with batching. |

```text
DeliveryService --has many--> Order --at--> Restaurant
        |       --has many--> Courier (assigned: List<Order>, capacity 2)
        +-- dispatch(order): batchable courier? -> same courier : best free courier by (pickupTime, courierWait)
```

## 3. Design decisions and why

- **Transition table in one place,** so every status change is validated the same way and the policy (who may cancel when) is easy to read.
- **Dispatch on acceptance,** when the ready time is known, not at order placement.
- **Score = (pickup time, courier wait):** both couriers may get the food out at the same moment; the one who would wait less is the better use of courier supply.
- **Batching first:** at peaks courier supply is the bottleneck; carrying two compatible orders frees a courier for someone else. The compatibility rules bound the extra delay for the second customer.
- **Integer minutes and kilometres on a grid:** deterministic tests; a routing service replaces `travelMinutes` in production.

## 4. The code

```dart
class Point {
  const Point(this.x, this.y);
  final int x;
  final int y;
  int distanceKm(Point o) => (x - o.x).abs() + (y - o.y).abs(); // city blocks
}

/// 30 km/h on city streets: 2 minutes per km.
int travelMinutes(Point a, Point b) => a.distanceKm(b) * 2;

class Restaurant {
  const Restaurant(this.id, this.location, this.prepMinutes);
  final String id;
  final Point location;
  final int prepMinutes;
}

enum OrderStatus {
  placed,
  accepted,
  preparing,
  ready,
  pickedUp,
  delivered,
  cancelled;

  Set<OrderStatus> get next => switch (this) {
    placed => {accepted, cancelled},
    accepted => {preparing, cancelled},
    preparing => {ready, cancelled},
    ready => {pickedUp, cancelled},
    pickedUp => {delivered},
    delivered || cancelled => {},
  };
}

class Order {
  Order(this.id, this.restaurant, this.dropoff, this.total, this.placedAt);
  final String id;
  final Restaurant restaurant;
  final Point dropoff;
  final int total; // cents
  final int placedAt;
  OrderStatus status = OrderStatus.placed;
  int? readyAt;
  Courier? courier;
  int refund = 0;
}

class Courier {
  Courier(this.id, this.location, {this.capacity = 2});
  final String id;
  Point location;
  final int capacity;
  final assigned = <Order>[];
  bool get isFree => assigned.isEmpty;
}

class InvalidTransitionException implements Exception {
  InvalidTransitionException(this.from, this.to);
  final OrderStatus from;
  final OrderStatus to;
}

class DeliveryService {
  DeliveryService(this.couriers);
  final List<Courier> couriers;
  final orders = <String, Order>{};
  var now = 0; // minutes

  void _move(Order o, OrderStatus to) {
    if (!o.status.next.contains(to)) throw InvalidTransitionException(o.status, to);
    o.status = to;
  }

  Order place(String id, Restaurant r, Point dropoff, int total) => orders[id] = Order(id, r, dropoff, total, now);

  Courier? accept(String id) {
    final o = orders[id]!;
    _move(o, OrderStatus.accepted);
    o.readyAt = now + o.restaurant.prepMinutes;
    return dispatch(o);
  }

  void startPreparing(String id) => _move(orders[id]!, OrderStatus.preparing);
  void markReady(String id) => _move(orders[id]!, OrderStatus.ready);

  void pickUp(String id) {
    final o = orders[id]!;
    if (o.courier == null) throw StateError('no courier assigned');
    _move(o, OrderStatus.pickedUp);
    o.courier!.location = o.restaurant.location;
  }

  void deliver(String id) {
    final o = orders[id]!;
    _move(o, OrderStatus.delivered);
    o.courier!
      ..location = o.dropoff
      ..assigned.remove(o);
  }

  /// Full refund before preparation, half after; not possible once picked up.
  void cancel(String id, {bool byRestaurant = false}) {
    final o = orders[id]!;
    final before = o.status;
    _move(o, OrderStatus.cancelled);
    o.refund = byRestaurant || before == OrderStatus.placed || before == OrderStatus.accepted ? o.total : o.total ~/ 2;
    o.courier?.assigned.remove(o);
  }

  int pickupTime(Courier c, Order o) {
    final arrival = now + travelMinutes(c.location, o.restaurant.location);
    return arrival > o.readyAt! ? arrival : o.readyAt!;
  }

  int courierWait(Courier c, Order o) => pickupTime(c, o) - (now + travelMinutes(c.location, o.restaurant.location));

  /// Estimated delivery minute for [o] if carried by its assigned courier.
  int eta(Order o) {
    final c = o.courier!;
    final pickup = c.assigned
        .where((x) => x.status != OrderStatus.pickedUp)
        .map((x) => pickupTime(c, x))
        .fold(0, (a, b) => a > b ? a : b);
    final others = c.assigned.where(
      (x) => x != o && x.dropoff.distanceKm(o.restaurant.location) < o.dropoff.distanceKm(o.restaurant.location),
    );
    var t = pickup, at = o.restaurant.location;
    for (final stop in [...others.map((x) => x.dropoff), o.dropoff]) {
      t += travelMinutes(at, stop); // deliver nearer drop-offs first
      at = stop;
    }
    return t;
  }

  bool _batchable(Courier c, Order o) =>
      c.assigned.length < c.capacity &&
      c.assigned.isNotEmpty &&
      c.assigned.every(
        (x) =>
            x.restaurant.id == o.restaurant.id &&
            x.status != OrderStatus.pickedUp &&
            (x.readyAt! - o.readyAt!).abs() <= 5 &&
            x.dropoff.distanceKm(o.dropoff) <= 2,
      );

  Courier? dispatch(Order o) {
    Courier? chosen;
    for (final c in couriers) {
      if (_batchable(c, o)) {
        chosen = c; // batching saves a courier
        break;
      }
    }
    if (chosen == null) {
      for (final c in couriers.where((c) => c.isFree)) {
        if (chosen == null) {
          chosen = c;
          continue;
        }
        final best = (pickupTime(chosen, o), courierWait(chosen, o));
        final mine = (pickupTime(c, o), courierWait(c, o));
        if (mine.$1 < best.$1 || (mine.$1 == best.$1 && mine.$2 < best.$2)) chosen = c;
      }
    }
    if (chosen != null) {
      chosen.assigned.add(o);
      o.courier = chosen;
    }
    return chosen;
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
  const pizza = Restaurant('pizza', Point(0, 0), 10);
  final a = Courier('A', const Point(1, 0)); // 2 minutes away
  final b = Courier('B', const Point(4, 0)); // 8 minutes away
  final c = Courier('C', const Point(9, 9)); // 36 minutes away
  final service = DeliveryService([a, b, c]);

  // Readiness-aware choice: A and B can both pick up at minute 10; B would wait 2 minutes, A 8.
  service.place('o1', pizza, const Point(3, 3), 2500);
  final first = service.accept('o1')!;
  final o1 = service.orders['o1']!;
  check([first.id, service.pickupTime(a, o1), service.courierWait(a, o1), service.courierWait(b, o1)], ['B', 10, 8, 2]);
  check(service.eta(o1), 22); // pickup 10 + 6 km x 2 min

  // Batching: same restaurant, ready 2 minutes later, drop-off 1 km away -> same courier.
  service.now = 2;
  service.place('o2', pizza, const Point(3, 4), 1800);
  check(service.accept('o2')!.id, 'B');
  final o2 = service.orders['o2']!;
  check(
    [b.assigned.length, service.eta(o1), service.eta(o2)],
    [2, 24, 26],
  ); // pickup at 12 now; o1 first, then 1 km more

  // A third order to the other side of town is not batchable; A is the best free courier.
  service.place('o3', pizza, const Point(-5, -5), 3000);
  check(service.accept('o3')!.id, 'A');

  // Lifecycle and invalid transitions.
  expectThrows<InvalidTransitionException>(() => service.deliver('o1')); // not picked up yet
  service
    ..startPreparing('o1')
    ..markReady('o1')
    ..pickUp('o1');
  expectThrows<InvalidTransitionException>(() => service.cancel('o1')); // too late to cancel
  service.deliver('o1');
  check([o1.status, b.assigned.map((o) => o.id), b.location.x, b.location.y], [OrderStatus.delivered, '(o2)', 3, 3]);

  // Cancellation policy.
  service.place('o4', pizza, const Point(1, 1), 2000);
  service.cancel('o4'); // before acceptance
  service.place('o5', pizza, const Point(1, 1), 2000);
  service.accept('o5');
  service.startPreparing('o5');
  service.cancel('o5'); // food already being made
  service.place('o6', pizza, const Point(1, 1), 2000);
  service.cancel('o6', byRestaurant: true);
  check(
    [
      for (final id in ['o4', 'o5', 'o6']) service.orders[id]!.refund,
    ],
    [2000, 1000, 2000],
  );
  check(service.orders['o5']!.courier!.assigned.contains(service.orders['o5']), false); // courier released
}
```

## 5. Walkthrough

- The pizza is ready at minute 10. A is 2 minutes away and would wait 8 minutes; B is 8 minutes away and waits 2. Both pick up at 10, so B wins on waiting, keeping A free. Delivery to (3,3) is 6 km = 12 minutes: ETA 22.
- At minute 2, a second pizza order (ready at 12, drop-off 1 km from the first) is batched onto B. Pickup moves to 12; B delivers the nearer drop-off first: o1 at 12 + 12 = 24, o2 at 24 + 2 = 26.
- A third order to (-5,-5) is 10 km from the batch's drop-offs, so it is not batched; A takes it (pickup at 12, waiting 8 minutes, but C would arrive at 38).
- Delivering before pickup and cancelling after pickup are both rejected. After delivery, B's position is the drop-off and only o2 remains assigned.
- Refunds: cancelled before acceptance (full), during preparation (half), rejected by the restaurant (full). A cancelled order releases its courier.

## 6. Concurrency

- Order transitions are conditional updates on the order row (`WHERE status = :expected`), because restaurant, courier and customer apps act concurrently (cancel vs pick up).
- Dispatch runs per city in one process (or one partition), so two orders cannot grab the same courier concurrently; courier reservation uses the same compare-and-set as in 08.
- Location updates go to the in-memory geo index, not the order database.

## 7. Extensibility

| Change | Where |
|---|---|
| Real routing and traffic | Replace `travelMinutes` with a routing/ETA service. |
| Global assignment | Collect pending orders and free couriers every few seconds; solve min-cost matching instead of greedy. |
| Courier offers and declines | An `offered` state with timeout, as in 08. |
| Different cancellation policies per market | A `CancellationPolicy` strategy. |
| Batches of 3+ | Raise capacity and order drop-offs with a small route optimizer. |

## 8. Common mistakes in LLD rounds

- Choosing the nearest courier regardless of when the food is ready.
- No cap on how much batching delays the second customer.
- Allowing any status to change to any other.
- Forgetting to free the courier when an order is cancelled.

See [HLD.md](HLD.md) for the marketplace architecture, ETAs and peak handling.
