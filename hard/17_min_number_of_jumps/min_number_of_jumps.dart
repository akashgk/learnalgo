// Min Number Of Jumps: array[i] is the max jump length from i. Min jumps to reach the end.
// Greedy BFS by levels: each "level" is the range reachable with j jumps. O(n) time, O(1) space.

int minNumberOfJumps(List<int> array) {
  if (array.length <= 1) return 0;
  var jumps = 0, currentEnd = 0, farthest = 0;
  for (var i = 0; i < array.length - 1; i++) {
    if (i + array[i] > farthest) farthest = i + array[i];
    if (i == currentEnd) {
      // Finished scanning everything reachable with `jumps` jumps; take one more.
      jumps++;
      currentEnd = farthest;
      if (currentEnd >= array.length - 1) break;
    }
  }
  return jumps;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(minNumberOfJumps([3, 4, 2, 1, 2, 3, 7, 1, 1, 1, 3]), 4);
  check(minNumberOfJumps([1]), 0);
  check(minNumberOfJumps([2, 1, 1]), 1);
  check(minNumberOfJumps([1, 1, 1, 1]), 3);
}
