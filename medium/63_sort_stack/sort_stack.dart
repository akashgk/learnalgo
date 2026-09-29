// Sort Stack using only push/pop/peek/isEmpty and recursion (no extra data structures).
// Pop everything, then insert each value back into its sorted position recursively.
// O(n^2) time, O(n) recursion space. The top of the stack ends up as the largest value.

List<int> sortStack(List<int> stack) {
  if (stack.isEmpty) return stack;
  final top = stack.removeLast();
  sortStack(stack);
  _insertInSortedOrder(stack, top);
  return stack;
}

void _insertInSortedOrder(List<int> stack, int value) {
  if (stack.isEmpty || stack.last <= value) {
    stack.add(value);
    return;
  }
  final top = stack.removeLast();
  _insertInSortedOrder(stack, value);
  stack.add(top);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(sortStack([-5, 2, -2, 4, 3, 1]), [-5, -2, 1, 2, 3, 4]);
  check(sortStack([]), []);
  check(sortStack([3, 3, 1]), [1, 3, 3]);
}
