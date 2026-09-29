// Calendar Matching: two people's meetings and daily bounds ("HH:MM"). Return all free slots
// of at least `duration` minutes available to both. Convert to minutes, add bound blocks,
// merge all busy intervals, collect gaps. O(c1 + c2) time and space (inputs are sorted).

List<List<String>> calendarMatching(
  List<List<String>> calendar1,
  List<String> dailyBounds1,
  List<List<String>> calendar2,
  List<String> dailyBounds2,
  int meetingDuration,
) {
  int toMin(String t) {
    final [h, m] = t.split(':').map(int.parse).toList();
    return h * 60 + m;
  }

  String toTime(int m) => '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}';

  List<List<int>> withBounds(List<List<String>> cal, List<String> bounds) => [
    [0, toMin(bounds[0])], // busy before the day starts
    for (final [s, e] in cal) [toMin(s), toMin(e)],
    [toMin(bounds[1]), 24 * 60], // busy after the day ends
  ];

  final a = withBounds(calendar1, dailyBounds1), b = withBounds(calendar2, dailyBounds2);
  // Merge the two sorted lists (like merge sort), then merge overlapping intervals.
  final all = <List<int>>[];
  var i = 0, j = 0;
  while (i < a.length || j < b.length) {
    if (j == b.length || (i < a.length && a[i][0] <= b[j][0])) {
      all.add(a[i++]);
    } else {
      all.add(b[j++]);
    }
  }
  final merged = <List<int>>[];
  for (final [s, e] in all) {
    if (merged.isNotEmpty && s <= merged.last[1]) {
      if (e > merged.last[1]) merged.last[1] = e;
    } else {
      merged.add([s, e]);
    }
  }
  return [
    for (var k = 1; k < merged.length; k++)
      if (merged[k][0] - merged[k - 1][1] >= meetingDuration) [toTime(merged[k - 1][1]), toTime(merged[k][0])],
  ];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    calendarMatching(
      [
        ['9:00', '10:30'],
        ['12:00', '13:00'],
        ['16:00', '18:00'],
      ],
      ['9:00', '20:00'],
      [
        ['10:00', '11:30'],
        ['12:30', '14:30'],
        ['14:30', '15:00'],
        ['16:00', '17:00'],
      ],
      ['10:00', '18:30'],
      30,
    ),
    [
      ['11:30', '12:00'],
      ['15:00', '16:00'],
      ['18:00', '18:30'],
    ],
  );
}
