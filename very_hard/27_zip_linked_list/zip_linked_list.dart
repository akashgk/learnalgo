// Zip Linked List: 1 -> n -> 2 -> n-1 -> 3 -> ... in place.
// Split at the middle, reverse the second half, interleave. O(n) time, O(1) space.

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

LinkedList zipLinkedList(LinkedList head) {
  if (head.next == null || head.next!.next == null) return head;
  // First half keeps the extra node for odd lengths.
  var slow = head;
  LinkedList? fast = head;
  while (fast!.next != null && fast.next!.next != null) {
    slow = slow.next!;
    fast = fast.next!.next;
  }
  LinkedList? second = _reverse(slow.next!);
  slow.next = null;
  LinkedList? first = head;
  while (first != null && second != null) {
    final firstNext = first.next, secondNext = second.next;
    first.next = second;
    second.next = firstNext;
    first = firstNext;
    second = secondNext;
  }
  return head;
}

LinkedList _reverse(LinkedList head) {
  LinkedList? prev;
  LinkedList? cur = head;
  while (cur != null) {
    final next = cur.next;
    cur.next = prev;
    prev = cur;
    cur = next;
  }
  return prev!;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(zipLinkedList(LinkedList.fromList([1, 2, 3, 4, 5, 6])).toList(), [1, 6, 2, 5, 3, 4]);
  check(zipLinkedList(LinkedList.fromList([1, 2, 3, 4, 5])).toList(), [1, 5, 2, 4, 3]);
  check(zipLinkedList(LinkedList.fromList([1, 2])).toList(), [1, 2]);
  check(zipLinkedList(LinkedList(1)).toList(), [1]);
}
