// Juice Bottling (rod cutting): prices[i] = price of a bottle holding i units.
// Total juice = prices.length - 1 units. Maximize revenue; return bottle sizes (ascending).
// O(n^2) time, O(n) space.

List<int> juiceBottling(List<int> prices) {
  final n = prices.length - 1;
  final best = List<int>.filled(n + 1, 0);
  final firstBottle = List<int>.filled(n + 1, 0);
  for (var units = 1; units <= n; units++) {
    // Default: one bottle holding everything. Guarantees a valid (non-zero) first bottle even
    // when no split earns more, e.g. all prices 0; otherwise reconstruction would never end.
    best[units] = prices[units];
    firstBottle[units] = units;
    for (var size = 1; size < units; size++) {
      final revenue = prices[size] + best[units - size];
      if (revenue > best[units]) {
        best[units] = revenue;
        firstBottle[units] = size;
      }
    }
  }
  final sizes = <int>[];
  for (var left = n; left > 0; left -= firstBottle[left]) {
    sizes.add(firstBottle[left]);
  }
  return sizes..sort();
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(juiceBottling([0, 1, 3, 2]), [1, 2]); // 1 + 3 = 4 beats one bottle of 3 (2)
  check(juiceBottling([0, 2, 5, 6]), [1, 2]); // 2 + 5 = 7
  check(juiceBottling([0, 1, 5, 8, 9, 10, 17, 17, 20]), [2, 6]); // CLRS rod cutting: 22
  check(juiceBottling([0, 1, 6, 10, 11]), [2, 2]); // greedy by ratio would pick [1, 3] = 11
  check(juiceBottling([0, 0, 0]), [2]); // all prices 0: any bottling is optimal
  check(juiceBottling([0]), <int>[]);
}
