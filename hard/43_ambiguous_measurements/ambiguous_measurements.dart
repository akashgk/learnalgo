// Ambiguous Measurements: each cup, when filled, yields an amount in [low, high].
// Can a combination of fills guarantee a total within [low, high] target range?
// Memoized recursion over (targetLow, targetHigh). O(low * high * n) time, O(low * high) space.

bool ambiguousMeasurements(List<List<int>> cups, int low, int high) {
  final memo = <(int, int), bool>{};

  /// Can pours whose combined total is guaranteed to land in [lo, hi] be chosen?
  bool canMeasure(int lo, int hi) {
    final key = (lo, hi);
    final cached = memo[key];
    if (cached != null) return cached;
    var ok = false;
    for (final [cupLow, cupHigh] in cups) {
      if (cupLow >= lo && cupHigh <= hi) {
        ok = true; // this single pour is guaranteed to finish inside the range
        break;
      }
      if (cupHigh >= hi) continue; // pouring it leaves no room for anything else
      // After this pour, the rest must land in [lo - cupLow, hi - cupHigh] (lower clamped to 0).
      if (canMeasure(lo - cupLow > 0 ? lo - cupLow : 0, hi - cupHigh)) {
        ok = true;
        break;
      }
    }
    return memo[key] = ok;
  }

  return canMeasure(low, high);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(ambiguousMeasurements([[200, 210], [450, 465], [800, 850]], 2100, 2300), true);
  check(ambiguousMeasurements([[1, 3], [2, 4], [5, 6]], 100, 101), false);
  check(ambiguousMeasurements([[1, 1]], 3, 3), true);
  check(ambiguousMeasurements([[5, 7]], 10, 13), false); // two pours give [10, 14]
  check(ambiguousMeasurements([[5, 7]], 10, 14), true);
}
