// Best Seat: seats[i] is 1 (taken) or 0 (free); both ends are taken. Pick the free seat
// whose distance to the nearest taken seat is largest; ties go to the lowest index.
// Return -1 if no seat is free. O(n) time, O(1) space.

int bestSeat(List<int> seats) {
  var best = -1, bestDistance = 0;
  var left = 0;
  while (left < seats.length) {
    var right = left + 1;
    while (right < seats.length && seats[right] == 0) {
      right++;
    }
    // Free run is (left, right), exclusive. Its middle seat is farthest from both ends.
    final freeCount = right - left - 1;
    final distance = (freeCount + 1) ~/ 2; // distance from the middle to the nearer end
    if (freeCount > 0 && distance > bestDistance) {
      bestDistance = distance;
      best = (left + right) ~/ 2;
    }
    left = right;
  }
  return best;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(bestSeat([1, 0, 1, 0, 0, 0, 1]), 4);
  check(bestSeat([1]), -1);
  check(bestSeat([1, 0, 1]), 1);
  check(bestSeat([1, 0, 0, 1]), 1);
  check(bestSeat([1, 1, 1]), -1);
  check(bestSeat([1, 0, 0, 0, 1, 0, 0, 0, 0, 1]), 2); // run of 3 and run of 4 tie at distance 2
}
