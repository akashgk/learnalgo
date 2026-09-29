// Max Profit With K Transactions (buy then sell, at most k times, no overlapping holdings).
// profit[t][d] = max(profit[t][d-1], prices[d] + max_{x<d}(profit[t-1][x] - prices[x])).
// The inner max is tracked incrementally. O(n * k) time, O(n) space (two rows).

int maxProfitWithKTransactions(List<int> prices, int k) {
  if (prices.isEmpty || k == 0) return 0;
  var prev = List<int>.filled(prices.length, 0); // t - 1 transactions
  for (var t = 1; t <= k; t++) {
    final curr = List<int>.filled(prices.length, 0);
    var bestBuy = -prices[0]; // max over x < d of prev[x] - prices[x]
    for (var d = 1; d < prices.length; d++) {
      final sellToday = prices[d] + bestBuy;
      curr[d] = curr[d - 1] > sellToday ? curr[d - 1] : sellToday;
      final buyToday = prev[d] - prices[d];
      if (buyToday > bestBuy) bestBuy = buyToday;
    }
    prev = curr;
  }
  return prev.last;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(maxProfitWithKTransactions([5, 11, 3, 50, 60, 90], 2), 93); // (5->11) + (3->90)
  check(maxProfitWithKTransactions([], 1), 0);
  check(maxProfitWithKTransactions([5, 4, 3], 3), 0);
  check(maxProfitWithKTransactions([1, 10], 5), 9);
}
