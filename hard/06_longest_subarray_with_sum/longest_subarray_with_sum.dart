// Longest Subarray With Sum (non-negative integers): sliding window.
// Returns [start, end] of the longest subarray summing to target, or [] if none.
// O(n) time, O(1) space. (For arrays with negatives, see the prefix-sum map below.)

List<int> longestSubarrayWithSum(List<int> array, int targetSum) {
  var best = <int>[];
  var sum = 0, left = 0;
  for (var right = 0; right < array.length; right++) {
    sum += array[right];
    while (sum > targetSum && left < right) {
      sum -= array[left++];
    }
    if (sum == targetSum && (best.isEmpty || right - left > best[1] - best[0])) {
      best = [left, right];
    }
  }
  return best;
}

/// Works with negative numbers: first index of each prefix sum. O(n) time, O(n) space.
List<int> longestSubarrayWithSumAnySign(List<int> array, int targetSum) {
  final firstIndex = <int, int>{0: -1};
  var best = <int>[], sum = 0;
  for (var i = 0; i < array.length; i++) {
    sum += array[i];
    final start = firstIndex[sum - targetSum];
    if (start != null && (best.isEmpty || i - (start + 1) > best[1] - best[0])) {
      best = [start + 1, i];
    }
    firstIndex.putIfAbsent(sum, () => i); // keep the earliest index for the longest span
  }
  return best;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(longestSubarrayWithSum([1, 2, 15, 3, 4, 5, 6, 7, 8], 30), [
    0,
    5,
  ]); // 1+2+15+3+4+5; [4, 8] also sums to 30 but is shorter
  check(longestSubarrayWithSumAnySign([1, 2, 15, 3, 4, 5, 6, 7, 8], 30), [
    0,
    5,
  ]); // 1+2+15+3+4+5; [4, 8] also sums to 30 but is shorter
  check(longestSubarrayWithSum([0, 0, 5, 0, 0], 5), [0, 4]);
  check(longestSubarrayWithSum([1, 2, 3], 7), []);
  check(longestSubarrayWithSumAnySign([3, -1, -2, 5], 0), [0, 2]);
}
