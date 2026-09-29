// Repair BST: exactly two nodes had their values swapped. Find them via in-order traversal
// (the only inversions in the sequence) and swap back. O(n) time, O(h) space.

class BST {
  BST(this.value, [this.left, this.right]);
  int value;
  BST? left;
  BST? right;
}

BST repairBst(BST tree) {
  BST? first, second, prev;
  final stack = <BST>[];
  BST? node = tree;
  while (node != null || stack.isNotEmpty) {
    while (node != null) {
      stack.add(node);
      node = node.left;
    }
    final current = stack.removeLast();
    if (prev != null && prev.value > current.value) {
      first ??= prev; // first inversion: the bigger (earlier) element is misplaced
      second = current; // last inversion: the smaller (later) element is misplaced
    }
    prev = current;
    node = current.right;
  }
  final tmp = first!.value;
  first.value = second!.value;
  second.value = tmp;
  return tree;
}

List<int> inOrder(BST? t) => t == null ? [] : [...inOrder(t.left), t.value, ...inOrder(t.right)];

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  // Correct tree: 10(7(2(1),8), 20(14,22)); 7 and 20 swapped.
  final broken = BST(10, BST(20, BST(2, BST(1)), BST(8)), BST(7, BST(14), BST(22)));
  check(inOrder(repairBst(broken)), [1, 2, 7, 8, 10, 14, 20, 22]);
  // Adjacent swap in in-order sequence (only one inversion).
  final adjacent = BST(2, BST(3), BST(1));
  check(inOrder(repairBst(adjacent)), [1, 2, 3]);
}
