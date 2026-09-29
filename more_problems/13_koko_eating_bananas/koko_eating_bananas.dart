// Koko Eating Bananas: smallest integer eating speed k so that all piles are finished within h hours.
// Each hour Koko eats up to k bananas from one pile. Binary search on the answer.
// O(n log M) time where M is the largest pile, O(1) space.

int minEatingSpeed(List<int> piles, int h) {
  var lo = 1, hi = piles.reduce((a, b) => a > b ? a : b);
  // hoursAt(k) is non-increasing in k, so "finishes in time" is monotone: false...false true...true.
  while (lo < hi) {
    final mid = lo + (hi - lo) ~/ 2;
    if (_hoursAt(piles, mid) <= h) {
      hi = mid; // mid works; the answer is mid or smaller
    } else {
      lo = mid + 1; // mid is too slow
    }
  }
  return lo;
}

int _hoursAt(List<int> piles, int k) {
  var hours = 0;
  for (final p in piles) {
    hours += (p + k - 1) ~/ k; // ceil(p / k) without floating point
  }
  return hours;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(minEatingSpeed([3, 6, 7, 11], 8), 4);
  check(minEatingSpeed([30, 11, 23, 4, 20], 5), 30); // h == number of piles: must eat the largest in one hour
  check(minEatingSpeed([30, 11, 23, 4, 20], 6), 23);
  check(minEatingSpeed([1, 1, 1], 10), 1);
  check(minEatingSpeed([1000000000], 2), 500000000);
}
