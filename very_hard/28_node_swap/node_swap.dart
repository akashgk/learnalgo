// Node Swap: swap every pair of adjacent nodes (by relinking, not by swapping values).
// Iterative with a dummy head. O(n) time, O(1) space.

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

LinkedList nodeSwap(LinkedList head) {
  final dummy = LinkedList(0, head);
  var prev = dummy;
  while (prev.next != null && prev.next!.next != null) {
    final first = prev.next!, second = prev.next!.next!;
    first.next = second.next;
    second.next = first;
    prev.next = second;
    prev = first; // first is now the second node of the swapped pair
  }
  return dummy.next!;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(nodeSwap(LinkedList.fromList([0, 1, 2, 3, 4, 5])).toList(), [1, 0, 3, 2, 5, 4]);
  check(nodeSwap(LinkedList.fromList([0, 1, 2])).toList(), [1, 0, 2]);
  check(nodeSwap(LinkedList(9)).toList(), [9]);
}
