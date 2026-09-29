// Radix Sort (LSD, base 10) for non-negative integers, using a stable counting sort per digit.
// O(d * (n + b)) time, O(n + b) space; d = digits of the max value, b = 10.

List<int> radixSort(List<int> array) {
  if (array.isEmpty) return array;
  final maxValue = array.reduce((a, b) => a > b ? a : b);
  for (var place = 1; maxValue ~/ place > 0; place *= 10) {
    _countingSortByDigit(array, place);
  }
  return array;
}

void _countingSortByDigit(List<int> a, int place) {
  final counts = List<int>.filled(10, 0);
  for (final x in a) {
    counts[(x ~/ place) % 10]++;
  }
  for (var d = 1; d < 10; d++) {
    counts[d] += counts[d - 1]; // prefix sums: end position of each digit bucket
  }
  final out = List<int>.filled(a.length, 0);
  for (var i = a.length - 1; i >= 0; i--) {
    // iterate backwards to keep the sort stable
    final d = (a[i] ~/ place) % 10;
    out[--counts[d]] = a[i];
  }
  a.setAll(0, out);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(radixSort([8762, 654, 3008, 345, 87, 65, 234, 12, 2]), [2, 12, 65, 87, 234, 345, 654, 3008, 8762]);
  check(radixSort([]), []);
  check(radixSort([0, 0, 10]), [0, 0, 10]);
}
