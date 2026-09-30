// Insert Interval: intervals are sorted by start and non-overlapping. Insert newInterval, merging
// where needed. Three phases in one scan: intervals entirely before it, overlapping ones (merged
// into it), intervals entirely after it. O(n) time, O(n) space for the output.

List<List<int>> insert(List<List<int>> intervals, List<int> newInterval) {
  final result = <List<int>>[];
  var i = 0;
  var start = newInterval[0], end = newInterval[1];
  // 1. Ends before the new interval starts: untouched.
  while (i < intervals.length && intervals[i][1] < start) {
    result.add(intervals[i++]);
  }
  // 2. Starts before (or when) the new interval ends: overlaps, so absorb it.
  while (i < intervals.length && intervals[i][0] <= end) {
    if (intervals[i][0] < start) start = intervals[i][0];
    if (intervals[i][1] > end) end = intervals[i][1];
    i++;
  }
  result.add([start, end]);
  // 3. Everything else starts after the merged interval ends.
  while (i < intervals.length) {
    result.add(intervals[i++]);
  }
  return result;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    insert(
      [
        [1, 3],
        [6, 9],
      ],
      [2, 5],
    ),
    [
      [1, 5],
      [6, 9],
    ],
  );
  check(
    insert(
      [
        [1, 2],
        [3, 5],
        [6, 7],
        [8, 10],
        [12, 16],
      ],
      [4, 8],
    ),
    [
      [1, 2],
      [3, 10],
      [12, 16],
    ],
  );
  check(insert([], [5, 7]), [
    [5, 7],
  ]);
  check(
    insert(
      [
        [1, 5],
      ],
      [5, 7],
    ),
    [
      [1, 7],
    ],
  ); // touching endpoints merge
  check(
    insert(
      [
        [3, 5],
      ],
      [1, 2],
    ),
    [
      [1, 2],
      [3, 5],
    ],
  );
}
