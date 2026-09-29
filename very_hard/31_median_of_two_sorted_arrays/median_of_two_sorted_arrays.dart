// Median Of Two Sorted Arrays in O(log(min(n, m))).
// Binary search a partition of the smaller array so the left halves together hold
// (n + m + 1) / 2 elements and every left element <= every right element.

double medianOfTwoSortedArrays(List<int> arrayOne, List<int> arrayTwo) {
  final (a, b) = arrayOne.length <= arrayTwo.length ? (arrayOne, arrayTwo) : (arrayTwo, arrayOne);
  final n = a.length, m = b.length;
  final half = (n + m + 1) ~/ 2;
  var lo = 0, hi = n;
  while (lo <= hi) {
    final i = (lo + hi) ~/ 2; // elements taken from a
    final j = half - i; // elements taken from b
    final aLeft = i == 0 ? double.negativeInfinity : a[i - 1].toDouble();
    final aRight = i == n ? double.infinity : a[i].toDouble();
    final bLeft = j == 0 ? double.negativeInfinity : b[j - 1].toDouble();
    final bRight = j == m ? double.infinity : b[j].toDouble();
    if (aLeft <= bRight && bLeft <= aRight) {
      final leftMax = aLeft > bLeft ? aLeft : bLeft;
      if ((n + m).isOdd) return leftMax;
      final rightMin = aRight < bRight ? aRight : bRight;
      return (leftMax + rightMin) / 2;
    }
    if (aLeft > bRight) {
      hi = i - 1; // took too many from a
    } else {
      lo = i + 1; // took too few from a
    }
  }
  throw ArgumentError('inputs must be sorted');
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(medianOfTwoSortedArrays([1, 3, 4, 5], [2, 3, 6, 7]), 3.5);
  check(medianOfTwoSortedArrays([1, 3], [2]), 2.0);
  check(medianOfTwoSortedArrays([], [1, 2, 3, 4]), 2.5);
  check(medianOfTwoSortedArrays([10, 20], [1, 2, 3]), 3.0);
}
