// Task Scheduler: tasks (letters) each take one unit; two identical tasks need at least n units
// between them (idle allowed). Minimum total units.
// Counting formula built around the most frequent task. O(T) time, O(1) space (26 counters).

int leastInterval(List<String> tasks, int n) {
  final count = List<int>.filled(26, 0);
  for (final t in tasks) {
    count[t.codeUnitAt(0) - 65]++;
  }
  final maxCount = count.reduce((a, b) => a > b ? a : b);
  final tiedForMax = count.where((c) => c == maxCount).length;
  // (maxCount - 1) full frames of length n + 1, then a final partial frame holding the tied tasks.
  final framed = (maxCount - 1) * (n + 1) + tiedForMax;
  // If there are more tasks than frame slots, no idling is ever needed.
  return framed > tasks.length ? framed : tasks.length;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(leastInterval(['A', 'A', 'A', 'B', 'B', 'B'], 2), 8); // A B _ A B _ A B
  check(leastInterval(['A', 'C', 'A', 'B', 'D', 'B'], 1), 6);
  check(leastInterval(['A', 'A', 'A', 'B', 'B', 'B'], 0), 6);
  check(leastInterval(['A', 'A', 'A', 'A', 'A', 'A', 'B', 'C', 'D', 'E', 'F', 'G'], 2), 16);
  check(leastInterval(['A', 'A', 'A', 'B', 'B', 'B', 'C', 'C', 'C', 'D', 'D', 'E'], 2), 12);
}
