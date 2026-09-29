// Number Of Ways To Make Change (unbounded coins, order does not matter).
// ways[a] += ways[a - coin], iterating coins in the OUTER loop to count combinations.
// O(n * d) time, O(n) space.

int numberOfWaysToMakeChange(int n, List<int> denoms) {
  final ways = List<int>.filled(n + 1, 0)..[0] = 1;
  for (final coin in denoms) {
    for (var amount = coin; amount <= n; amount++) {
      ways[amount] += ways[amount - coin];
    }
  }
  return ways[n];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(numberOfWaysToMakeChange(6, [1, 5]), 2); // 1x6, 1x1 + 1x5
  check(numberOfWaysToMakeChange(10, [1, 5, 10, 25]), 4);
  check(numberOfWaysToMakeChange(0, [2, 3]), 1);
  check(numberOfWaysToMakeChange(7, [2, 4]), 0);
}
