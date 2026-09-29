// Next Permutation: rearrange into the next lexicographically greater order, in place.
// If none exists (fully descending), wrap to the smallest order. O(n) time, O(1) space.

void nextPermutation(List<int> a) {
  final n = a.length;
  // 1. Find the pivot: the rightmost i with a[i] < a[i + 1]. Everything after it is non-increasing.
  var i = n - 2;
  while (i >= 0 && a[i] >= a[i + 1]) {
    i--;
  }
  if (i >= 0) {
    // 2. Swap the pivot with the rightmost element that is strictly greater than it.
    var j = n - 1;
    while (a[j] <= a[i]) {
      j--;
    }
    _swap(a, i, j);
  }
  // 3. The suffix is still non-increasing; reverse it to make it the smallest possible.
  _reverse(a, i + 1, n - 1);
}

void _swap(List<int> a, int i, int j) {
  final t = a[i];
  a[i] = a[j];
  a[j] = t;
}

void _reverse(List<int> a, int lo, int hi) {
  while (lo < hi) {
    _swap(a, lo++, hi--);
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  List<int> next(List<int> a) {
    nextPermutation(a);
    return a;
  }

  check(next([1, 2, 3]), [1, 3, 2]);
  check(next([3, 2, 1]), [1, 2, 3]); // last permutation wraps around
  check(next([1, 1, 5]), [1, 5, 1]);
  check(next([2, 3, 6, 5, 4, 1]), [2, 4, 1, 3, 5, 6]);
  check(next([1, 5, 1]), [5, 1, 1]); // duplicates: swap with a strictly greater element
  check(next([7]), [7]);
}
