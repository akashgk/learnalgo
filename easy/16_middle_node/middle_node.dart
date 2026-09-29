// Middle Node
// Slow/fast pointers: fast moves 2, slow moves 1. When fast finishes, slow is in the middle.
// For even length this returns the second of the two middle nodes. O(n) time, O(1) space.

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
}

LinkedList middleNode(LinkedList linkedList) {
  var slow = linkedList;
  LinkedList? fast = linkedList;
  while (fast != null && fast.next != null) {
    slow = slow.next!;
    fast = fast.next!.next;
  }
  return slow;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(middleNode(LinkedList.fromList([2, 7, 3, 5])!).value, 3);
  check(middleNode(LinkedList.fromList([1, 2, 3])!).value, 2);
  check(middleNode(LinkedList.fromList([1])!).value, 1);
}
