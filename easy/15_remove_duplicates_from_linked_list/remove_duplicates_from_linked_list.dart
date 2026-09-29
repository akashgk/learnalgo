// Remove Duplicates From Linked List (sorted list).
// For each node, skip all following nodes with the same value. O(n) time, O(1) space.

class LinkedList {
  LinkedList(this.value, [this.next]);
  int value;
  LinkedList? next;

  static LinkedList? fromList(List<int> values) {
    LinkedList? head;
    for (final v in values.reversed) {
      head = LinkedList(v, head);
    }
    return head;
  }

  List<int> toList() => [for (LinkedList? n = this; n != null; n = n.next) n.value];
}

LinkedList removeDuplicatesFromLinkedList(LinkedList linkedList) {
  LinkedList? current = linkedList;
  while (current != null) {
    var nextDistinct = current.next;
    while (nextDistinct != null && nextDistinct.value == current.value) {
      nextDistinct = nextDistinct.next;
    }
    current.next = nextDistinct;
    current = nextDistinct;
  }
  return linkedList;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final list = LinkedList.fromList([1, 1, 3, 4, 4, 4, 5, 6, 6])!;
  check(removeDuplicatesFromLinkedList(list).toList(), [1, 3, 4, 5, 6]);
  check(removeDuplicatesFromLinkedList(LinkedList.fromList([2, 2, 2])!).toList(), [2]);
}
