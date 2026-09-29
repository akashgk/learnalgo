// Move Element To End (in place, order of others not required).
// Two pointers: right pointer skips values already equal to toMove; swap on the left.
// O(n) time, O(1) space.

List<int> moveElementToEnd(List<int> array, int toMove) {
  var i = 0, j = array.length - 1;
  while (i < j) {
    while (i < j && array[j] == toMove) {
      j--;
    }
    if (array[i] == toMove) {
      array[i] = array[j];
      array[j] = toMove;
    }
    i++;
  }
  return array;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(moveElementToEnd([2, 1, 2, 2, 2, 3, 4, 2], 2), [4, 1, 3, 2, 2, 2, 2, 2]);
  check(moveElementToEnd([], 3), []);
  check(moveElementToEnd([1, 2, 4, 5, 3], 3), [1, 2, 4, 5, 3]);
  check(moveElementToEnd([3, 3, 3], 3), [3, 3, 3]);
}
