// Remove Kth Node From End (in place). Two pointers k apart.
// The head must stay the same object, so removing the head copies the next node into it.
// O(n) time, O(1) space.

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

void removeKthNodeFromEnd(LinkedList head, int k) {
  LinkedList? lead = head;
  for (var i = 0; i < k; i++) {
    lead = lead!.next;
  }
  if (lead == null) {
    // k == length: remove the head by copying the second node into it.
    head
      ..value = head.next!.value
      ..next = head.next!.next;
    return;
  }
  var trail = head;
  while (lead!.next != null) {
    lead = lead.next;
    trail = trail.next!;
  }
  trail.next = trail.next!.next; // trail is just before the node to delete
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final list = LinkedList.fromList(List.generate(10, (i) => i));
  removeKthNodeFromEnd(list, 4);
  check(list.toList(), [0, 1, 2, 3, 4, 5, 7, 8, 9]);
  final list2 = LinkedList.fromList([0, 1, 2]);
  removeKthNodeFromEnd(list2, 3);
  check(list2.toList(), [1, 2]);
  final list3 = LinkedList.fromList([0, 1, 2]);
  removeKthNodeFromEnd(list3, 1);
  check(list3.toList(), [0, 1]);
}
