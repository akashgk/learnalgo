// Merge Triplets to Form Target Triplet: merging two triplets takes the element-wise maximum.
// Can some set of the given triplets merge into exactly target?
// A triplet with any value above target can never be used (max only grows). Among the usable ones,
// merge all of them and check whether each coordinate hits its target. O(n) time, O(1) space.

bool mergeTriplets(List<List<int>> triplets, List<int> target) {
  final hit = [false, false, false];
  for (final t in triplets) {
    if (t[0] > target[0] || t[1] > target[1] || t[2] > target[2]) continue; // would overshoot
    for (var k = 0; k < 3; k++) {
      if (t[k] == target[k]) hit[k] = true;
    }
  }
  return hit[0] && hit[1] && hit[2];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    mergeTriplets(
      [
        [2, 5, 3],
        [1, 8, 4],
        [1, 7, 5],
      ],
      [2, 7, 5],
    ),
    true,
  );
  check(
    mergeTriplets(
      [
        [3, 4, 5],
        [4, 5, 6],
      ],
      [3, 2, 5],
    ),
    false,
  );
  check(
    mergeTriplets(
      [
        [2, 5, 3],
        [2, 3, 4],
        [1, 2, 5],
        [5, 2, 3],
      ],
      [5, 5, 5],
    ),
    true,
  );
}
