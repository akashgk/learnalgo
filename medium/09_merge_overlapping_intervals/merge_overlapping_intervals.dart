// Merge Overlapping Intervals. Sort by start, then extend or append.
// O(n log n) time, O(n) space.

List<List<int>> mergeOverlappingIntervals(List<List<int>> intervals) {
  final sorted = [...intervals]..sort((a, b) => a[0].compareTo(b[0]));
  final merged = <List<int>>[];
  for (final [start, end] in sorted) {
    if (merged.isNotEmpty && start <= merged.last[1]) {
      if (end > merged.last[1]) merged.last[1] = end;
    } else {
      merged.add([start, end]);
    }
  }
  return merged;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    mergeOverlappingIntervals([
      [1, 2],
      [3, 5],
      [4, 7],
      [6, 8],
      [9, 10],
    ]),
    [
      [1, 2],
      [3, 8],
      [9, 10],
    ],
  );
  check(
    mergeOverlappingIntervals([
      [1, 22],
      [-20, 30],
    ]),
    [
      [-20, 30],
    ],
  );
  check(
    mergeOverlappingIntervals([
      [1, 10],
      [2, 3],
    ]),
    [
      [1, 10],
    ],
  ); // containment
  check(
    mergeOverlappingIntervals([
      [1, 2],
      [2, 3],
    ]),
    [
      [1, 3],
    ],
  ); // touching counts
}
