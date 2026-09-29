// Max Subset Sum No Adjacent (House Robber). best(i) = max(best(i-1), best(i-2) + a[i]).
// O(n) time, O(1) space.

int maxSubsetSumNoAdjacent(List<int> array) {
  var prev2 = 0, prev1 = 0; // best sums ending before i-1 and before i
  for (final x in array) {
    final current = prev1 > prev2 + x ? prev1 : prev2 + x;
    prev2 = prev1;
    prev1 = current;
  }
  return prev1;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(maxSubsetSumNoAdjacent([75, 105, 120, 75, 90, 135]), 330); // 75 + 120 + 135
  check(maxSubsetSumNoAdjacent([]), 0);
  check(maxSubsetSumNoAdjacent([1]), 1);
  check(maxSubsetSumNoAdjacent([7, 10, 12, 7, 9, 14]), 33);
}
