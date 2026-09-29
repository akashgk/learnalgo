// Next Greater Element in a circular array (-1 if none).
// Monotonic decreasing stack of indices, iterate twice around. O(n) time, O(n) space.

List<int> nextGreaterElement(List<int> array) {
  final n = array.length;
  final result = List<int>.filled(n, -1);
  final stack = <int>[]; // indices whose next greater element is not found yet
  for (var k = 0; k < 2 * n; k++) {
    final i = k % n;
    while (stack.isNotEmpty && array[stack.last] < array[i]) {
      result[stack.removeLast()] = array[i];
    }
    if (k < n) stack.add(i); // only push each index once
  }
  return result;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(nextGreaterElement([2, 5, -3, -4, 6, 7, 2]), [5, 6, 6, 6, 7, -1, 5]);
  check(nextGreaterElement([5, 4, 3]), [-1, 5, 5]);
  check(nextGreaterElement([]), []);
}
