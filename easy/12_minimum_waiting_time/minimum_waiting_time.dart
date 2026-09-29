// Minimum Waiting Time
// Greedy: run shortest queries first. Each query's duration is waited on by every query after it.
// O(n log n) time, O(1) extra space (sorting a copy here).

int minimumWaitingTime(List<int> queries) {
  final sorted = [...queries]..sort();
  var total = 0;
  for (var i = 0; i < sorted.length; i++) {
    final queriesLeft = sorted.length - 1 - i;
    total += sorted[i] * queriesLeft;
  }
  return total;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(minimumWaitingTime([3, 2, 1, 2, 6]), 17);
  check(minimumWaitingTime([1]), 0);
  check(minimumWaitingTime([5, 1, 4]), 6); // order 1,4,5: waits 0 + 1 + 5
}
