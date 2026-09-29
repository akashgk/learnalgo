// Disk Stacking: disks [width, depth, height]. A disk can sit on another only if it is strictly
// smaller in all three dimensions. Maximize total height. Returns the stack from top to bottom
// (smallest first). Sort by height, then LIS-style DP. O(n^2) time, O(n) space.

List<List<int>> diskStacking(List<List<int>> disks) {
  if (disks.isEmpty) return [];
  final d = [...disks]..sort((a, b) => a[2].compareTo(b[2]));
  final heights = [for (final x in d) x[2]];
  final prev = List<int?>.filled(d.length, null);
  var bestIdx = 0;
  bool fitsOn(List<int> top, List<int> bottom) => top[0] < bottom[0] && top[1] < bottom[1] && top[2] < bottom[2];

  for (var i = 1; i < d.length; i++) {
    for (var j = 0; j < i; j++) {
      if (fitsOn(d[j], d[i]) && heights[j] + d[i][2] > heights[i]) {
        heights[i] = heights[j] + d[i][2];
        prev[i] = j;
      }
    }
    if (heights[i] > heights[bestIdx]) bestIdx = i;
  }
  final stack = <List<int>>[];
  for (int? i = bestIdx; i != null; i = prev[i]) {
    stack.add(d[i]);
  }
  return stack.reversed.toList();
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    diskStacking([
      [2, 1, 2],
      [3, 2, 3],
      [2, 2, 8],
      [2, 3, 4],
      [1, 3, 1],
      [4, 4, 5],
    ]),
    [
      [2, 1, 2],
      [3, 2, 3],
      [4, 4, 5],
    ],
  );
  check(
    diskStacking([
      [2, 1, 2],
    ]),
    [
      [2, 1, 2],
    ],
  );
  // [1,1,1] on [2,2,8] = 9 beats [1,1,1] on [3,3,2] = 3.
  check(
    diskStacking([
      [2, 2, 8],
      [1, 1, 1],
      [3, 3, 2],
    ]),
    [
      [1, 1, 1],
      [2, 2, 8],
    ],
  );
}
