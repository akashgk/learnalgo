// Non-overlapping Intervals: minimum number of intervals to remove so the rest do not overlap
// (touching endpoints like [1,2] and [2,3] do not overlap).
// Greedy: sort by END, keep every interval that starts at or after the last kept end.
// O(n log n) time, O(n) space for the sorted copy.

int eraseOverlapIntervals(List<List<int>> intervals) {
  if (intervals.isEmpty) return 0;
  final sorted = [...intervals]..sort((a, b) => a[1].compareTo(b[1]));
  var kept = 0, lastEnd = -(1 << 62);
  for (final iv in sorted) {
    if (iv[0] >= lastEnd) {
      kept++; // the earliest-finishing compatible interval leaves the most room for the rest
      lastEnd = iv[1];
    }
  }
  return intervals.length - kept;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    eraseOverlapIntervals([
      [1, 2],
      [2, 3],
      [3, 4],
      [1, 3],
    ]),
    1,
  );
  check(
    eraseOverlapIntervals([
      [1, 2],
      [1, 2],
      [1, 2],
    ]),
    2,
  );
  check(
    eraseOverlapIntervals([
      [1, 2],
      [2, 3],
    ]),
    0,
  );
  check(
    eraseOverlapIntervals([
      [1, 100],
      [11, 22],
      [1, 11],
      [2, 12],
    ]),
    2,
  );
  check(eraseOverlapIntervals([]), 0);
}
