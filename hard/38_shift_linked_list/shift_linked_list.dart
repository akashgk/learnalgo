// Shift Linked List by k (positive: move tail nodes to the front; negative: move head nodes
// to the back). Find length and tail, cut at the right spot, reconnect.
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

LinkedList shiftLinkedList(LinkedList head, int k) {
  var length = 1;
  var tail = head;
  while (tail.next != null) {
    tail = tail.next!;
    length++;
  }
  final offset = k % length; // Dart % is non-negative: -1 % 6 == 5, i.e. shift forward by 5
  if (offset == 0) return head;
  // New tail is at position length - offset - 1 (0-based).
  var newTail = head;
  for (var i = 0; i < length - offset - 1; i++) {
    newTail = newTail.next!;
  }
  final newHead = newTail.next!;
  newTail.next = null;
  tail.next = head;
  return newHead;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  List<int> run(int k) => shiftLinkedList(LinkedList.fromList([0, 1, 2, 3, 4, 5]), k).toList();
  check(run(2), [4, 5, 0, 1, 2, 3]);
  check(run(-2), [2, 3, 4, 5, 0, 1]);
  check(run(6), [0, 1, 2, 3, 4, 5]);
  check(run(8), [4, 5, 0, 1, 2, 3]);
  check(run(-1), [1, 2, 3, 4, 5, 0]);
}
