// Best Time to Buy and Sell Stock (one transaction).
// Single pass tracking the cheapest price so far. O(n) time, O(1) space.

int maxProfit(List<int> prices) {
  var minPrice = 1 << 62; // cheapest buy seen so far
  var best = 0; // not trading is allowed, so profit never goes below 0
  for (final p in prices) {
    if (p < minPrice) minPrice = p;
    if (p - minPrice > best) best = p - minPrice;
  }
  return best;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(maxProfit([7, 1, 5, 3, 6, 4]), 5); // buy at 1, sell at 6
  check(maxProfit([7, 6, 4, 3, 1]), 0); // prices only fall
  check(maxProfit([2, 4, 1]), 2); // the later minimum 1 has no sell day after it
  check(maxProfit([]), 0);
  check(maxProfit([5]), 0);
}
