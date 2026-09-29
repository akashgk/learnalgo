// Smallest Difference: pair (one from each array) with the smallest absolute difference.
// Sort both, then advance the pointer at the smaller value. O(n log n + m log m) time.

List<int> smallestDifference(List<int> arrayOne, List<int> arrayTwo) {
  final a = [...arrayOne]..sort();
  final b = [...arrayTwo]..sort();
  var i = 0, j = 0;
  var best = <int>[];
  var bestDiff = double.maxFinite.toInt();
  while (i < a.length && j < b.length) {
    final x = a[i], y = b[j];
    final diff = (x - y).abs();
    if (diff < bestDiff) {
      bestDiff = diff;
      best = [x, y];
    }
    if (x == y) return best; // cannot beat 0
    if (x < y) {
      i++; // only increasing x can close the gap
    } else {
      j++;
    }
  }
  return best;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(smallestDifference([-1, 5, 10, 20, 28, 3], [26, 134, 135, 15, 17]), [28, 26]);
  check(smallestDifference([10, 1000], [-1441, -124, -25, 1014, 1500, 660, 410, 245, 530]), [1000, 1014]);
  check(smallestDifference([1, 2, 3], [3]), [3, 3]);
}
