// Breadth-first Search on a tree-like graph: return names in level order.
// O(v + e) time, O(v) space.

import 'dart:collection';

class Node {
  Node(this.name, [List<Node>? children]) : children = children ?? [];
  final String name;
  final List<Node> children;

  List<String> breadthFirstSearch() {
    final out = <String>[];
    final queue = Queue<Node>()..add(this);
    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      out.add(node.name);
      queue.addAll(node.children);
    }
    return out;
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final graph = Node('A', [
    Node('B', [Node('E'), Node('F', [Node('I'), Node('J')])]),
    Node('C'),
    Node('D', [Node('G', [Node('K')]), Node('H')]),
  ]);
  check(graph.breadthFirstSearch(), ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K']);
}
