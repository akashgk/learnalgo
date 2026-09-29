// Rearrange Linked List around k: nodes < k, then == k, then > k, keeping relative order
// within each group (stable). Three sublists joined at the end. O(n) time, O(1) space.

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

LinkedList rearrangeLinkedList(LinkedList head, int k) {
  final lessHead = LinkedList(0), equalHead = LinkedList(0), greaterHead = LinkedList(0);
  var less = lessHead, equal = equalHead, greater = greaterHead;
  LinkedList? node = head;
  while (node != null) {
    final next = node.next;
    node.next = null;
    if (node.value < k) {
      less = less.next = node;
    } else if (node.value == k) {
      equal = equal.next = node;
    } else {
      greater = greater.next = node;
    }
    node = next;
  }
  greater.next = null;
  equal.next = greaterHead.next;
  less.next = equalHead.next ?? greaterHead.next;
  return lessHead.next ?? equalHead.next ?? greaterHead.next!;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(rearrangeLinkedList(LinkedList.fromList([3, 0, 5, 2, 1, 4]), 3).toList(), [0, 2, 1, 3, 5, 4]);
  check(rearrangeLinkedList(LinkedList.fromList([5, 6, 7]), 1).toList(), [5, 6, 7]);
  check(rearrangeLinkedList(LinkedList.fromList([3, 1, 3, 2]), 10).toList(), [3, 1, 3, 2]);
  check(rearrangeLinkedList(LinkedList.fromList([4, 1, 4]), 4).toList(), [1, 4, 4]);
}
