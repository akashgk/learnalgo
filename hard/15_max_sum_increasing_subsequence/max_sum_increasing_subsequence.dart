// Max Sum Increasing Subsequence: strictly increasing subsequence with the largest sum.
// Returns [sum, subsequence]. DP over "ending at i" with predecessor links. O(n^2) time, O(n) space.

List<Object> maxSumIncreasingSubsequence(List<int> array) {
  final sums = [...array];
  final prev = List<int?>.filled(array.length, null);
  var bestIdx = 0;
  for (var i = 0; i < array.length; i++) {
    for (var j = 0; j < i; j++) {
      if (array[j] < array[i] && sums[j] + array[i] > sums[i]) {
        sums[i] = sums[j] + array[i];
        prev[i] = j;
      }
    }
    if (sums[i] > sums[bestIdx]) bestIdx = i;
  }
  final seq = <int>[];
  for (int? i = bestIdx; i != null; i = prev[i]) {
    seq.add(array[i]);
  }
  return [sums[bestIdx], seq.reversed.toList()];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(maxSumIncreasingSubsequence([10, 70, 20, 30, 50, 11, 30]), [110, [10, 20, 30, 50]]);
  check(maxSumIncreasingSubsequence([-1]), [-1, [-1]]);
  check(maxSumIncreasingSubsequence([5, 4, 3, 2, 1]), [5, [5]]);
  check(maxSumIncreasingSubsequence([-5, -4, -3, -2, -1]), [-1, [-1]]);
}
