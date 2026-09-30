// Daily Temperatures: for each day, how many days until a strictly warmer day (0 if never)?
// Monotonic stack of indices still waiting for a warmer day. O(n) time, O(n) space.

List<int> dailyTemperatures(List<int> temps) {
  final answer = List<int>.filled(temps.length, 0);
  final waiting = <int>[]; // indices; their temperatures are non-increasing from bottom to top
  for (var i = 0; i < temps.length; i++) {
    // Today answers every waiting day that is colder than today.
    while (waiting.isNotEmpty && temps[waiting.last] < temps[i]) {
      final day = waiting.removeLast();
      answer[day] = i - day;
    }
    waiting.add(i);
  }
  return answer;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(dailyTemperatures([73, 74, 75, 71, 69, 72, 76, 73]), [1, 1, 4, 2, 1, 1, 0, 0]);
  check(dailyTemperatures([30, 40, 50, 60]), [1, 1, 1, 0]);
  check(dailyTemperatures([30, 60, 90]), [1, 1, 0]);
  check(dailyTemperatures([50, 50, 50]), [0, 0, 0]); // equal is not warmer
}
