// Non-Constructible Change
// Sort coins; keep `change` = every amount in [1, change] is constructible.
// If the next coin > change + 1, then change + 1 is the answer. O(n log n) time, O(1) extra space.

int nonConstructibleChange(List<int> coins) {
  final sorted = [...coins]..sort();
  var change = 0;
  for (final coin in sorted) {
    if (coin > change + 1) break;
    change += coin;
  }
  return change + 1;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(nonConstructibleChange([5, 7, 1, 1, 2, 3, 22]), 20);
  check(nonConstructibleChange([1, 1, 1, 1, 1]), 6);
  check(nonConstructibleChange([]), 1);
  check(nonConstructibleChange([2]), 1);
  check(nonConstructibleChange([1, 2, 4]), 8);
}
