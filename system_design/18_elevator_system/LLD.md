# Elevator System: Low-Level Design

## 1. Scope for the LLD round

- A building with floors `0..n-1` and several elevators.
- **Car calls** (a passenger inside presses a floor) and **hall calls** (a floor's up or down button).
- Each elevator schedules its stops with **LOOK**: keep going in the current direction while stops remain ahead, then reverse; idle when empty.
- A **dispatcher strategy** assigns each hall call to the elevator with the lowest cost.
- A tick-based **simulation**: each tick an elevator moves one floor, or opens its doors at a stop (doors stay open for one extra tick).
- Duplicate hall calls reuse the existing assignment. An elevator taken **out of service** gives its hall calls back to the dispatcher.
- Invalid floors are rejected.

Out of scope: door sensors, load limits, fire mode (HLD section 6).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Direction` (enum) | `up`, `down`, `idle`. |
| `Elevator` | Current floor, direction, sorted stops, which stops are hall calls, door timer, served log, in-service flag; `step()` implements LOOK. |
| `Dispatcher` (interface) | `choose(cars, floor, direction)`. |
| `CostDispatcher` | Distance if the call is ahead in the same direction, else distance via the turnaround point. |
| `ElevatorController` | Facade: validates calls, keeps hall-call assignments, ticks every car, reassigns on failure. |

```text
ElevatorController --has many--> Elevator (floor, direction, SplayTreeSet<int> stops, step = LOOK)
        |
        +--uses--> Dispatcher (interface) <-- CostDispatcher
        +--hall assignments: (floor, direction) -> Elevator
```

## 3. Design decisions and why

- **Stops in a sorted set:** "any stop above?" is `stops.last > floor`, "any below?" is `stops.first < floor`. LOOK needs only these two questions.
- **Scheduling inside `Elevator`, dispatching outside it.** An elevator only knows its own stops; choosing which elevator serves a hall call is a separate, swappable strategy (nearest car, zoning, destination dispatch).
- **The dispatcher's cost uses direction.** A car 2 floors away that is moving away from the caller may be a worse choice than an idle car 8 floors away.
- **Hall calls are remembered by `(floor, direction)`,** so pressing the button again does not create a second assignment, and an out-of-service car's calls can be found and reassigned.
- **Discrete ticks** make behavior exact and testable; real controllers use motion profiles but the same decisions.

## 4. The code

```dart
import 'dart:collection';

enum Direction { up, down, idle }

class Elevator {
  Elevator(this.id, {this.floor = 0});

  final String id;
  int floor;
  Direction direction = Direction.idle;
  final stops = SplayTreeSet<int>();
  final hallStops = <int>{};
  final served = <int>[];
  var inService = true;
  var _doorTicks = 0;

  bool get isIdle => stops.isEmpty && _doorTicks == 0;

  void step() {
    if (!inService) return;
    if (_doorTicks > 0) {
      _doorTicks--; // doors still open
      return;
    }
    if (stops.remove(floor)) {
      hallStops.remove(floor);
      served.add(floor);
      _doorTicks = 1; // open now, close after one more tick
      return;
    }
    direction = _nextDirection();
    if (direction == Direction.up) floor++;
    if (direction == Direction.down) floor--;
  }

  /// LOOK: continue while stops remain ahead; otherwise reverse; idle when nothing is left.
  Direction _nextDirection() {
    if (stops.isEmpty) return Direction.idle;
    final above = stops.last > floor, below = stops.first < floor;
    if (direction == Direction.up && above) return Direction.up;
    if (direction == Direction.down && below) return Direction.down;
    if (above && below) {
      final up = stops.firstWhere((s) => s > floor) - floor, down = floor - stops.lastWhere((s) => s < floor);
      return up <= down ? Direction.up : Direction.down; // idle: go toward the nearer stop
    }
    return above ? Direction.up : Direction.down;
  }

  @override
  String toString() => '$id@$floor';
}

abstract interface class Dispatcher {
  Elevator? choose(List<Elevator> cars, int floor, Direction direction);
}

class CostDispatcher implements Dispatcher {
  static const unavailable = 1 << 30;

  int cost(Elevator e, int floor, Direction wanted) {
    if (!e.inService) return unavailable;
    final distance = (e.floor - floor).abs();
    if (e.direction == Direction.idle || e.stops.isEmpty) return distance;
    final goingUp = e.direction == Direction.up;
    final ahead = goingUp ? floor >= e.floor : floor <= e.floor;
    if (ahead && wanted == e.direction) return distance; // picks it up on the way
    // Otherwise it finishes its run to the turnaround point, then comes back.
    final turn = goingUp
        ? (e.stops.last > floor ? e.stops.last : floor)
        : (e.stops.first < floor ? e.stops.first : floor);
    return (turn - e.floor).abs() + (turn - floor).abs();
  }

  @override
  Elevator? choose(List<Elevator> cars, int floor, Direction direction) {
    Elevator? best;
    var bestCost = unavailable;
    for (final e in cars) {
      final c = cost(e, floor, direction);
      if (c < bestCost) {
        best = e;
        bestCost = c;
      }
    }
    return best;
  }
}

class NoElevatorAvailableException implements Exception {}

class ElevatorController {
  ElevatorController({required this.floors, required this.cars, Dispatcher? dispatcher})
    : _dispatcher = dispatcher ?? CostDispatcher();

  final int floors;
  final List<Elevator> cars;
  final Dispatcher _dispatcher;
  final _hallAssignments = <(int, Direction), Elevator>{};

  Elevator car(String id) => cars.firstWhere((e) => e.id == id);

  void _validate(int floor) {
    if (floor < 0 || floor >= floors) throw ArgumentError.value(floor, 'floor', 'must be in 0..${floors - 1}');
  }

  Elevator hallCall(int floor, Direction direction) {
    _validate(floor);
    if (direction == Direction.idle) throw ArgumentError('a hall call has a direction');
    if (direction == Direction.up && floor == floors - 1) throw ArgumentError('no up button on the top floor');
    if (direction == Direction.down && floor == 0) throw ArgumentError('no down button on the ground floor');
    final existing = _hallAssignments[(floor, direction)];
    if (existing != null) return existing; // the button is already lit
    final e = _dispatcher.choose(cars, floor, direction);
    if (e == null) throw NoElevatorAvailableException();
    e.stops.add(floor);
    e.hallStops.add(floor);
    return _hallAssignments[(floor, direction)] = e;
  }

  void carCall(String carId, int floor) {
    _validate(floor);
    car(carId).stops.add(floor);
  }

  void tick() {
    for (final e in cars) {
      e.step();
    }
    _hallAssignments.removeWhere((key, e) => !e.hallStops.contains(key.$1)); // served
  }

  int runUntilIdle({int maxTicks = 10000}) {
    var ticks = 0;
    while (cars.any((e) => e.inService && !e.isIdle)) {
      if (++ticks > maxTicks) throw StateError('not converging');
      tick();
    }
    return ticks;
  }

  void setOutOfService(String carId) {
    final e = car(carId)
      ..inService = false
      ..direction = Direction.idle;
    final orphaned = _hallAssignments.entries.where((x) => identical(x.value, e)).map((x) => x.key).toList();
    for (final key in orphaned) {
      _hallAssignments.remove(key);
      e.stops.remove(key.$1);
      e.hallStops.remove(key.$1);
      hallCall(key.$1, key.$2); // back to the dispatcher
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

void main() {
  // LOOK on one car: stops are served in travel order, not press order.
  final solo = ElevatorController(floors: 10, cars: [Elevator('A')]);
  solo
    ..carCall('A', 5)
    ..carCall('A', 2)
    ..carCall('A', 8);
  solo.runUntilIdle();
  check(solo.car('A').served, [2, 5, 8]);

  // New calls while moving up: keep going up (8, 9), then come back down for 1.
  final look = ElevatorController(floors: 10, cars: [Elevator('A')]);
  look
    ..carCall('A', 5)
    ..carCall('A', 8);
  for (var i = 0; i < 6; i++) {
    look.tick(); // 5 moves + doors open at 5
  }
  look
    ..carCall('A', 1)
    ..carCall('A', 9);
  look.runUntilIdle();
  check(look.car('A').served, [5, 8, 9, 1]);

  // Dispatching between idle cars: the nearer one.
  final idle = ElevatorController(floors: 21, cars: [Elevator('A'), Elevator('B', floor: 10)]);
  check([idle.hallCall(8, Direction.down).id, idle.hallCall(1, Direction.up).id], ['B', 'A']);
  check(identical(idle.hallCall(8, Direction.down), idle.car('B')), true); // pressing again changes nothing

  // A is at floor 3 moving up to 9; B is idle at 10.
  ElevatorController moving() {
    final c = ElevatorController(floors: 21, cars: [Elevator('A'), Elevator('B', floor: 10)])..carCall('A', 9);
    for (var i = 0; i < 3; i++) {
      c.tick();
    }
    return c;
  }

  final m = moving();
  check([m.car('A'), m.car('A').direction], ['A@3', Direction.up]);
  final dispatcher = CostDispatcher();
  check(
    [
      dispatcher.cost(m.car('A'), 5, Direction.up), // ahead, same direction
      dispatcher.cost(m.car('A'), 2, Direction.up), // behind: up to 9, back to 2
      dispatcher.cost(m.car('A'), 7, Direction.down), // ahead but wants the opposite direction
      dispatcher.cost(m.car('B'), 7, Direction.down),
    ],
    [2, 13, 8, 3],
  );
  check(
    [m.hallCall(5, Direction.up).id, m.hallCall(2, Direction.up).id, m.hallCall(7, Direction.down).id],
    ['A', 'B', 'B'],
  );
  m.runUntilIdle();
  check([m.car('A').served, m.car('B').served], ['[5, 9]', '[7, 2]']);

  // Out of service: the car's hall calls are reassigned.
  final failing = moving();
  check(failing.hallCall(6, Direction.up).id, 'A');
  failing.setOutOfService('A');
  check(failing.car('B').stops, '{6}');
  failing.runUntilIdle();
  check([failing.car('B').served, failing.car('A').served], ['[6]', '[]']);

  // Validation.
  expectThrows<ArgumentError>(() => failing.carCall('B', 21));
  expectThrows<ArgumentError>(() => failing.hallCall(20, Direction.up));
  expectThrows<ArgumentError>(() => failing.hallCall(0, Direction.down));
  failing.setOutOfService('B');
  expectThrows<NoElevatorAvailableException>(() => failing.hallCall(4, Direction.up));
}
```

## 5. Walkthrough

- Pressing 5, 2, 8 from floor 0 is served as 2, 5, 8: LOOK goes up and stops at each floor it passes.
- After serving 5, the car still has 8 above. New calls 1 and 9 arrive. It continues up (8, then 9) and only then reverses for 1. A first-come-first-served scheduler would have zig-zagged.
- Costs when A is at 3 heading to 9: a hall call at 5 going up is on the way (cost 2). A call at 2 going up is behind: 6 floors up to 9 and 7 back (13). A call at 7 going down is ahead but in the wrong direction, so A would only serve it on the way back: 6 floors up to its turnaround at 9, then 2 down (8). Idle B at 10 costs 3, so B takes it.
- B starts at 10, above both of its stops, so it goes down and serves 7, then 2.
- When A goes out of service, its hall call at 6 is removed from A and dispatched again; B is the only candidate.

## 6. Concurrency

- Button presses arrive from many panels concurrently; the controller serializes them (one event queue processed by a single control thread). Each elevator's `step` runs in the same loop, so state is never shared across threads.
- If the dispatcher runs separately from car controllers (as in real systems), assignments are messages: the car acknowledges, and unacknowledged assignments time out and are reassigned.

## 7. Extensibility

| Change | Where |
|---|---|
| Capacity / overload | `Elevator.load`; the dispatcher skips full cars; doors stay open when overloaded. |
| Zoning (tall buildings) | A `ZonedDispatcher` restricting each car to a floor range. |
| Destination dispatch | Calls carry the destination; the dispatcher groups passengers by destination. |
| Fire service mode | Controller mode that clears all stops and sends every car to the recall floor. |
| Up-peak parking | When idle, cars return to the lobby (a policy on idle cars). |

## 8. Common mistakes in LLD rounds

- One `ElevatorSystem` class doing scheduling, dispatching and state all in one method.
- FIFO stop order.
- Ignoring the direction of hall calls when choosing a car.
- No handling for duplicate presses, invalid floors, or a car leaving service.
- Mixing the safety logic (doors locked) into scheduling decisions.

See [HLD.md](HLD.md) for the building controller, safety layers and cloud monitoring.
