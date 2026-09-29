// Aggressive Cows (also: Magnetic Force Between Two Balls).
// Place c cows in stalls (given positions) maximizing the minimum distance between any two cows.
// Sort, then binary search on the answer with a greedy placement check. O(n log n + n log D) time.

int aggressiveCows(List<int> stalls, int cows) {
  final s = [...stalls]..sort();
  var lo = 1, hi = s.last - s.first;
  // canPlace(d) is monotone: true...true false...false. Find the last true.
  while (lo < hi) {
    final mid = lo + (hi - lo + 1) ~/ 2; // round up, or lo = mid could loop forever
    if (_canPlace(s, cows, mid)) {
      lo = mid; // mid works; try larger
    } else {
      hi = mid - 1;
    }
  }
  return lo;
}

/// Greedy: put a cow in the first stall, then in each next stall at least [d] away.
bool _canPlace(List<int> s, int cows, int d) {
  var placed = 1, last = s[0];
  for (var i = 1; i < s.length && placed < cows; i++) {
    if (s[i] - last >= d) {
      placed++;
      last = s[i];
    }
  }
  return placed >= cows;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(aggressiveCows([1, 2, 8, 4, 9], 3), 3); // 1, 4, 8 (or 1, 4, 9)
  check(aggressiveCows([0, 3, 4, 7, 10, 9], 4), 3);
  check(aggressiveCows([1, 2, 3, 4, 7], 3), 3);
  check(aggressiveCows([5, 4, 3, 2, 1, 1000000000], 2), 999999999);
  check(aggressiveCows([1, 2], 2), 1);
}
