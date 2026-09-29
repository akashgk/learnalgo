// Doubly Linked List Construction with head/tail. All operations O(1) except those that
// search or walk to a position (O(n)). Inserting an existing node moves it.

class Node {
  Node(this.value);
  int value;
  Node? prev;
  Node? next;
}

class DoublyLinkedList {
  Node? head;
  Node? tail;

  void setHead(Node node) {
    if (head == null) {
      head = tail = node;
      return;
    }
    insertBefore(head!, node);
  }

  void setTail(Node node) {
    if (tail == null) {
      setHead(node);
      return;
    }
    insertAfter(tail!, node);
  }

  void insertBefore(Node node, Node nodeToInsert) {
    if (identical(nodeToInsert, head) && identical(nodeToInsert, tail)) return; // only node
    remove(nodeToInsert);
    nodeToInsert
      ..prev = node.prev
      ..next = node;
    if (node.prev == null) {
      head = nodeToInsert;
    } else {
      node.prev!.next = nodeToInsert;
    }
    node.prev = nodeToInsert;
  }

  void insertAfter(Node node, Node nodeToInsert) {
    if (identical(nodeToInsert, head) && identical(nodeToInsert, tail)) return;
    remove(nodeToInsert);
    nodeToInsert
      ..prev = node
      ..next = node.next;
    if (node.next == null) {
      tail = nodeToInsert;
    } else {
      node.next!.prev = nodeToInsert;
    }
    node.next = nodeToInsert;
  }

  /// 1-based position. Position past the end appends at the tail.
  void insertAtPosition(int position, Node nodeToInsert) {
    if (position == 1) {
      setHead(nodeToInsert);
      return;
    }
    var node = head;
    for (var p = 1; node != null && p < position; p++) {
      node = node.next;
    }
    if (node == null) {
      setTail(nodeToInsert);
    } else {
      insertBefore(node, nodeToInsert);
    }
  }

  void removeNodesWithValue(int value) {
    var node = head;
    while (node != null) {
      final next = node.next; // save before unlinking
      if (node.value == value) remove(node);
      node = next;
    }
  }

  void remove(Node node) {
    if (identical(node, head)) head = head!.next;
    if (identical(node, tail)) tail = tail!.prev;
    node.prev?.next = node.next;
    node.next?.prev = node.prev;
    node
      ..prev = null
      ..next = null;
  }

  bool containsNodeWithValue(int value) {
    for (var n = head; n != null; n = n.next) {
      if (n.value == value) return true;
    }
    return false;
  }

  List<int> toList() => [for (var n = head; n != null; n = n.next) n.value];
  List<int> toListBackward() => [for (var n = tail; n != null; n = n.prev) n.value];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final list = DoublyLinkedList();
  final nodes = [
    for (var v in [1, 2, 3, 3, 4, 5, 6]) Node(v),
  ];
  for (final n in nodes.take(5)) {
    list.setTail(n);
  }
  check(list.toList(), [1, 2, 3, 3, 4]);
  list.setHead(nodes[4]); // moves 4 to the front
  check(list.toList(), [4, 1, 2, 3, 3]);
  list.setTail(nodes[5]); // value 5
  list.insertBefore(nodes[5], nodes[2]); // moves the first 3 right before 5
  check(list.toList(), [4, 1, 2, 3, 3, 5]);
  check(identical(nodes[5].prev, nodes[2]), true);
  list.insertAtPosition(1, nodes[6]); // value 6
  check(list.toList(), [6, 4, 1, 2, 3, 3, 5]);
  list.removeNodesWithValue(3);
  check(list.toList(), [6, 4, 1, 2, 5]);
  list.remove(nodes[1]); // value 2
  check(list.toList(), [6, 4, 1, 5]);
  check(list.toListBackward(), [5, 1, 4, 6]);
  check(list.containsNodeWithValue(5), true);
  check(list.containsNodeWithValue(3), false);
  list.insertAtPosition(10, Node(9));
  check(list.toList(), [6, 4, 1, 5, 9]);
}
