// Longest Increasing Subsequence (strict), returning the subsequence itself.
// Patience sorting: tails[len] = index of the smallest tail of an increasing subsequence of
// length len + 1; binary search each element's position; keep predecessor links.
// O(n log n) time, O(n) space.

List<int> longestIncreasingSubsequence(List<int> array) {
  final tails = <int>[]; // indices into array
  final prev = List<int?>.filled(array.length, null);
  for (var i = 0; i < array.length; i++) {
    // First position whose tail value is >= array[i] (strictly increasing => lower bound).
    var lo = 0, hi = tails.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (array[tails[mid]] < array[i]) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    if (lo > 0) prev[i] = tails[lo - 1];
    if (lo == tails.length) {
      tails.add(i);
    } else {
      tails[lo] = i;
    }
  }
  final seq = <int>[];
  for (int? i = tails.isEmpty ? null : tails.last; i != null; i = prev[i]) {
    seq.add(array[i]);
  }
  return seq.reversed.toList();
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(longestIncreasingSubsequence([5, 7, -24, 12, 10, 2, 3, 12, 5, 6, 35]), [-24, 2, 3, 5, 6, 35]);
  check(longestIncreasingSubsequence([]), []);
  check(longestIncreasingSubsequence([3, 3, 3]), [3]);
  check(longestIncreasingSubsequence([10, 9, 2, 5, 3, 7, 101, 18]).length, 4);
}
