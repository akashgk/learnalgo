// Depth-first Search on an n-ary tree (acyclic graph). Returns node names in preorder.
// O(v + e) time, O(v) space.

class Node {
  Node(this.name, [List<Node>? children]) : children = children ?? [];
  final String name;
  final List<Node> children;

  Node addChild(String name) {
    children.add(Node(name));
    return this;
  }

  List<String> depthFirstSearch([List<String>? out]) {
    final result = out ?? <String>[];
    result.add(name);
    for (final child in children) {
      child.depthFirstSearch(result);
    }
    return result;
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  //         A
  //      /  |  \
  //     B   C   D
  //    / \     / \
  //   E   F   G   H
  //      / \   \
  //     I   J   K
  final graph = Node('A', [
    Node('B', [Node('E'), Node('F', [Node('I'), Node('J')])]),
    Node('C'),
    Node('D', [Node('G', [Node('K')]), Node('H')]),
  ]);
  check(graph.depthFirstSearch(), ['A', 'B', 'E', 'F', 'I', 'J', 'C', 'D', 'G', 'K', 'H']);
  check((Node('X')..addChild('Y')).depthFirstSearch(), ['X', 'Y']);
}
