// Best Time to Buy and Sell Stock with Cooldown: unlimited transactions, one share at a time, and
// after a sell you must wait one day before buying again.
// State machine DP over three states at the end of each day:
//   hold  = holding a share
//   sold  = just sold today (so tomorrow is a cooldown)
//   rest  = not holding, free to buy tomorrow
// O(n) time, O(1) space.

int maxProfit(List<int> prices) {
  if (prices.isEmpty) return 0;
  var hold = -prices[0], sold = 0, rest = 0;
  for (var i = 1; i < prices.length; i++) {
    final p = prices[i];
    final newHold = hold > rest - p ? hold : rest - p; // keep holding, or buy (only from rest)
    final newSold = hold + p; // sell today
    final newRest = rest > sold ? rest : sold; // stay out, or finish yesterday's cooldown
    hold = newHold;
    sold = newSold;
    rest = newRest;
  }
  return sold > rest ? sold : rest; // ending while holding is never better
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(maxProfit([1, 2, 3, 0, 2]), 3); // buy, sell, cooldown, buy, sell
  check(maxProfit([1]), 0);
  check(maxProfit([1, 2, 4]), 3);
  check(maxProfit([2, 1]), 0);
  check(maxProfit([6, 1, 6, 4, 3, 0, 2]), 7); // 1 -> 6, cooldown, 0 -> 2
}
