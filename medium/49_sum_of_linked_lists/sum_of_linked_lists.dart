// Sum of Linked Lists: numbers stored least-significant digit first. Add with carry.
// O(max(n, m)) time, O(max(n, m)) space for the result.

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

LinkedList sumOfLinkedLists(LinkedList linkedListOne, LinkedList linkedListTwo) {
  final dummy = LinkedList(0);
  var tail = dummy;
  LinkedList? a = linkedListOne, b = linkedListTwo;
  var carry = 0;
  while (a != null || b != null || carry != 0) {
    final sum = (a?.value ?? 0) + (b?.value ?? 0) + carry;
    tail.next = LinkedList(sum % 10);
    tail = tail.next!;
    carry = sum ~/ 10;
    a = a?.next;
    b = b?.next;
  }
  return dummy.next!;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  // 1742 + 549 = 2291
  check(sumOfLinkedLists(LinkedList.fromList([2, 4, 7, 1]), LinkedList.fromList([9, 4, 5])).toList(), [1, 9, 2, 2]);
  // 99 + 1 = 100 (final carry creates a new node)
  check(sumOfLinkedLists(LinkedList.fromList([9, 9]), LinkedList.fromList([1])).toList(), [0, 0, 1]);
}
