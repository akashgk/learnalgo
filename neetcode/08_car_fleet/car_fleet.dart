// Car Fleet: cars on a one-lane road drive toward target. A faster car that catches a slower one
// ahead slows down and joins it (a fleet). How many fleets arrive?
// Sort by position (closest to the target first) and compare arrival times. O(n log n) time.

int carFleet(int target, List<int> position, List<int> speed) {
  final order = List.generate(position.length, (i) => i)..sort((a, b) => position[b].compareTo(position[a]));
  var fleets = 0;
  var slowestAhead = 0.0; // arrival time of the fleet directly ahead
  for (final i in order) {
    final time = (target - position[i]) / speed[i]; // arrival time if the road were empty
    // Arriving strictly later than the fleet ahead means it never catches up: a new fleet.
    // Arriving earlier or at the same time means it catches up and joins that fleet.
    if (time > slowestAhead) {
      fleets++;
      slowestAhead = time;
    }
  }
  return fleets;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(carFleet(12, [10, 8, 0, 5, 3], [2, 4, 1, 1, 3]), 3);
  check(carFleet(10, [3], [3]), 1);
  check(carFleet(100, [0, 2, 4], [4, 2, 1]), 1); // everyone catches the car at 4
  check(carFleet(10, [6, 8], [3, 2]), 2); // 6 arrives at 4/3, 8 arrives at 1: never meet
}
