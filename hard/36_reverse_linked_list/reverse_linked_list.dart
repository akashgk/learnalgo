// Reverse Linked List in place. Three pointers. O(n) time, O(1) space.

class LinkedList {
  LinkedList(this.value, [this.next]);
  int value;
  LinkedList? next;

  static LinkedList fromList(List<int> values) {
    LinkedList? head;
    for (final v in values.reversed) {
      head = LinkedList(v, head);
    }
    return head!;
  }

  List<int> toList() => [for (LinkedList? n = this; n != null; n = n.next) n.value];
}

LinkedList reverseLinkedList(LinkedList head) {
  LinkedList? prev;
  LinkedList? current = head;
  while (current != null) {
    final next = current.next; // save before overwriting
    current.next = prev;
    prev = current;
    current = next;
  }
  return prev!;
}

/// Recursive version: O(n) stack space.
LinkedList reverseRecursive(LinkedList head) {
  final rest = head.next;
  if (rest == null) return head;
  final newHead = reverseRecursive(rest);
  rest.next = head; // the old next is now the tail of the reversed rest
  head.next = null;
  return newHead;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(reverseLinkedList(LinkedList.fromList([0, 1, 2, 3, 4, 5])).toList(), [5, 4, 3, 2, 1, 0]);
  check(reverseRecursive(LinkedList.fromList([0, 1, 2])).toList(), [2, 1, 0]);
  check(reverseLinkedList(LinkedList(7)).toList(), [7]);
}
