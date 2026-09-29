// Min Height BST from a sorted array of distinct integers.
// Recursively take the middle element as root. O(n) time, O(n) space.

class BST {
  BST(this.value);
  int value;
  BST? left;
  BST? right;
}

BST? minHeightBst(List<int> array) => _build(array, 0, array.length - 1);

BST? _build(List<int> a, int lo, int hi) {
  if (lo > hi) return null;
  final mid = (lo + hi) ~/ 2;
  return BST(a[mid])
    ..left = _build(a, lo, mid - 1)
    ..right = _build(a, mid + 1, hi);
}

int height(BST? t) => t == null ? 0 : 1 + [height(t.left), height(t.right)].reduce((a, b) => a > b ? a : b);
List<int> inOrder(BST? t) => t == null ? [] : [...inOrder(t.left), t.value, ...inOrder(t.right)];

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final array = [1, 2, 5, 7, 10, 13, 14, 15, 22];
  final tree = minHeightBst(array);
  check(inOrder(tree), array);
  check(height(tree), 4); // ceil(log2(9 + 1)) = 4
  check(tree!.value, 10);
  check(minHeightBst([]), null);
}
