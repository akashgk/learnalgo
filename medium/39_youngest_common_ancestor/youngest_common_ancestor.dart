// Youngest Common Ancestor in an ancestral tree (each node has an `ancestor` pointer).
// Equalize depths, then climb together. O(d) time, O(1) space.

class AncestralTree {
  AncestralTree(this.name, [this.ancestor]);
  final String name;
  AncestralTree? ancestor;
}

AncestralTree youngestCommonAncestor(AncestralTree top, AncestralTree one, AncestralTree two) {
  int depth(AncestralTree node) {
    var d = 0;
    for (var n = node; !identical(n, top); n = n.ancestor!) {
      d++;
    }
    return d;
  }

  var a = one, b = two;
  var da = depth(a), db = depth(b);
  while (da > db) {
    a = a.ancestor!;
    da--;
  }
  while (db > da) {
    b = b.ancestor!;
    db--;
  }
  while (!identical(a, b)) {
    a = a.ancestor!;
    b = b.ancestor!;
  }
  return a;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  //          A
  //       /     \
  //      B       C
  //    /   \   /   \
  //   D     E F     G
  //  / \
  // H   I
  final a = AncestralTree('A');
  final b = AncestralTree('B', a), c = AncestralTree('C', a);
  final d = AncestralTree('D', b), e = AncestralTree('E', b);
  final f = AncestralTree('F', c), g = AncestralTree('G', c);
  final h = AncestralTree('H', d), i = AncestralTree('I', d);
  check(youngestCommonAncestor(a, e, i).name, 'B');
  check(youngestCommonAncestor(a, h, g).name, 'A');
  check(youngestCommonAncestor(a, h, i).name, 'D');
  check(youngestCommonAncestor(a, b, h).name, 'B'); // a node is its own ancestor
  check(youngestCommonAncestor(a, f, f).name, 'F');
  check(youngestCommonAncestor(a, e, g).name, 'A');
}
