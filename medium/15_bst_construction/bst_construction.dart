// BST Construction: insert, contains, remove (iterative).
// Average O(log n), worst O(n) time per operation; O(1) extra space.
// Duplicates go to the right subtree (right side holds values >= node).

class BST {
  BST(this.value);
  int value;
  BST? left;
  BST? right;

  BST insert(int value) {
    var node = this;
    while (true) {
      if (value < node.value) {
        if (node.left == null) {
          node.left = BST(value);
          return this;
        }
        node = node.left!;
      } else {
        if (node.right == null) {
          node.right = BST(value);
          return this;
        }
        node = node.right!;
      }
    }
  }

  bool contains(int value) {
    BST? node = this;
    while (node != null) {
      if (value == node.value) return true;
      node = value < node.value ? node.left : node.right;
    }
    return false;
  }

  /// Removes the first node found with [value]. A lone root is kept (a tree cannot be empty).
  BST remove(int value, [BST? parent]) {
    BST? node = this;
    while (node != null) {
      if (value < node.value) {
        parent = node;
        node = node.left;
      } else if (value > node.value) {
        parent = node;
        node = node.right;
      } else {
        if (node.left != null && node.right != null) {
          // Two children: copy the successor (min of right subtree), then delete it there.
          node.value = node.right!._minValue();
          node.right!.remove(node.value, node);
        } else if (parent == null) {
          // Root with at most one child: pull the child's contents up into the root object.
          final child = node.left ?? node.right;
          if (child != null) {
            node
              ..value = child.value
              ..left = child.left
              ..right = child.right;
          }
        } else {
          final child = node.left ?? node.right;
          if (identical(parent.left, node)) {
            parent.left = child;
          } else {
            parent.right = child;
          }
        }
        break;
      }
    }
    return this;
  }

  int _minValue() {
    var node = this;
    while (node.left != null) {
      node = node.left!;
    }
    return node.value;
  }

  List<int> inOrder() => [...?left?.inOrder(), value, ...?right?.inOrder()];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final bst = BST(10);
  for (final v in [5, 15, 2, 5, 13, 22, 1, 14, 12]) {
    bst.insert(v);
  }
  check(bst.inOrder(), [1, 2, 5, 5, 10, 12, 13, 14, 15, 22]);
  check(bst.contains(15), true);
  check(bst.contains(16), false);
  bst.remove(10); // root with two children
  check(bst.inOrder(), [1, 2, 5, 5, 12, 13, 14, 15, 22]);
  check(bst.value, 12);
  bst.remove(22).remove(1).remove(100);
  check(bst.inOrder(), [2, 5, 5, 12, 13, 14, 15]);
  final lone = BST(1)..insert(2);
  lone.remove(1);
  check(lone.inOrder(), [2]);
  check((BST(7)..remove(7)).inOrder(), [7]);
}
