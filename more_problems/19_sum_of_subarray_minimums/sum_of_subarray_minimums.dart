// Sum of Subarray Minimums: sum of min(sub) over every contiguous subarray (LeetCode returns it mod 1e9+7).
// Contribution technique: arr[i] is the minimum of left[i] * right[i] subarrays, where the
// spans come from the previous smaller and next smaller-or-equal elements (monotonic stack).
// O(n) time, O(n) space.

const mod = 1000000007;

int sumSubarrayMins(List<int> arr) {
  final n = arr.length;
  final left = List<int>.filled(n, 0); // choices for the left end: i - previous strictly smaller index
  final right = List<int>.filled(n, 0); // choices for the right end: next smaller-or-equal index - i
  final stack = <int>[];
  for (var i = 0; i < n; i++) {
    while (stack.isNotEmpty && arr[stack.last] >= arr[i]) {
      stack.removeLast();
    }
    left[i] = stack.isEmpty ? i + 1 : i - stack.last;
    stack.add(i);
  }
  stack.clear();
  for (var i = n - 1; i >= 0; i--) {
    while (stack.isNotEmpty && arr[stack.last] > arr[i]) {
      stack.removeLast();
    }
    right[i] = stack.isEmpty ? n - i : stack.last - i;
    stack.add(i);
  }
  // Ties: left spans stop at a strictly smaller value, right spans at a smaller-or-equal one,
  // so a subarray whose minimum occurs several times is counted once, by its rightmost copy.
  var total = 0;
  for (var i = 0; i < n; i++) {
    total = (total + arr[i] * left[i] * right[i]) % mod;
  }
  return total;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(sumSubarrayMins([3, 1, 2, 4]), 17);
  check(sumSubarrayMins([11, 81, 94, 43, 3]), 444);
  check(sumSubarrayMins([2, 2]), 6); // [2], [2], [2, 2]: counted once each
  check(sumSubarrayMins([1]), 1);
}
