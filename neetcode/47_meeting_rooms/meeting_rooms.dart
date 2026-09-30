// Meeting Rooms: can one person attend all meetings (no two overlap)? A meeting ending at t and
// another starting at t do not conflict. Sort by start and check neighbors.
// O(n log n) time, O(n) space for the sorted copy.

bool canAttendMeetings(List<List<int>> intervals) {
  final sorted = [...intervals]..sort((a, b) => a[0].compareTo(b[0]));
  for (var i = 1; i < sorted.length; i++) {
    if (sorted[i][0] < sorted[i - 1][1]) return false; // starts before the previous one ends
  }
  return true;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    canAttendMeetings([
      [0, 30],
      [5, 10],
      [15, 20],
    ]),
    false,
  );
  check(
    canAttendMeetings([
      [7, 10],
      [2, 4],
    ]),
    true,
  );
  check(
    canAttendMeetings([
      [1, 5],
      [5, 8],
    ]),
    true,
  ); // back to back
  check(canAttendMeetings([]), true);
}
