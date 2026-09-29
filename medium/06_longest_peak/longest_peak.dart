// Longest Peak: strictly increasing then strictly decreasing run, length >= 3.
// Find each peak tip, expand both ways, then jump past it. O(n) time, O(1) space.

int longestPeak(List<int> array) {
  var longest = 0;
  var i = 1;
  while (i < array.length - 1) {
    final isTip = array[i - 1] < array[i] && array[i] > array[i + 1];
    if (!isTip) {
      i++;
      continue;
    }
    var left = i - 1;
    while (left > 0 && array[left - 1] < array[left]) {
      left--;
    }
    var right = i + 1;
    while (right < array.length - 1 && array[right] > array[right + 1]) {
      right++;
    }
    final length = right - left + 1;
    if (length > longest) longest = length;
    i = right; // nothing between the tip and `right` can be a tip
  }
  return longest;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(longestPeak([1, 2, 3, 3, 4, 0, 10, 6, 5, -1, -3, 2, 3]), 6);
  check(longestPeak([1, 3, 2]), 3);
  check(longestPeak([1, 2, 3, 4]), 0);
  check(longestPeak([5, 4, 3, 2, 1, 2, 10, 12]), 0);
  check(longestPeak([1, 2, 2, 1]), 0);
}
