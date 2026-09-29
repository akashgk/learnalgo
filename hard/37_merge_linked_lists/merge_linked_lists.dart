// Merge Linked Lists: merge two sorted lists in place (relinking nodes, no new nodes).
// Dummy head + tail pointer. O(n + m) time, O(1) space.

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

LinkedList mergeLinkedLists(LinkedList headOne, LinkedList headTwo) {
  final dummy = LinkedList(0);
  var tail = dummy;
  LinkedList? a = headOne, b = headTwo;
  while (a != null && b != null) {
    if (a.value <= b.value) {
      tail.next = a;
      a = a.next;
    } else {
      tail.next = b;
      b = b.next;
    }
    tail = tail.next!;
  }
  tail.next = a ?? b; // attach whatever remains
  return dummy.next!;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final merged = mergeLinkedLists(LinkedList.fromList([2, 6, 7, 8]), LinkedList.fromList([1, 3, 4, 5, 9, 10]));
  check(merged.toList(), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  check(mergeLinkedLists(LinkedList(1), LinkedList(1)).toList(), [1, 1]);
}
