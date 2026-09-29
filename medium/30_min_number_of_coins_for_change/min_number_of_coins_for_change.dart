// Min Number Of Coins For Change (unbounded). minCoins[a] = min(minCoins[a - c] + 1).
// Return -1 if impossible. O(n * d) time, O(n) space.

int minNumberOfCoinsForChange(int n, List<int> denoms) {
  const inf = 1 << 62;
  final minCoins = List<int>.filled(n + 1, inf)..[0] = 0;
  for (final coin in denoms) {
    for (var amount = coin; amount <= n; amount++) {
      final candidate = minCoins[amount - coin] + 1;
      if (minCoins[amount - coin] != inf && candidate < minCoins[amount]) {
        minCoins[amount] = candidate;
      }
    }
  }
  return minCoins[n] == inf ? -1 : minCoins[n];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(minNumberOfCoinsForChange(7, [1, 5, 10]), 3); // 5 + 1 + 1
  check(minNumberOfCoinsForChange(6, [1, 3, 4]), 2); // 3 + 3 (greedy 4+1+1 = 3 coins is wrong)
  check(minNumberOfCoinsForChange(0, [1, 2]), 0);
  check(minNumberOfCoinsForChange(3, [2]), -1);
}
