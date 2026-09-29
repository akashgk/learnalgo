// Merging Linked Lists: return the node where two singly linked lists intersect, or null.
// Two pointers that switch to the other list's head at the end meet at the intersection
// after at most n + m steps. O(n + m) time, O(1) space.

class LinkedList {
  LinkedList(this.value, [this.next]);
  int value;
  LinkedList? next;
}

LinkedList? mergingLinkedLists(LinkedList one, LinkedList two) {
  LinkedList? a = one, b = two;
  while (!identical(a, b)) {
    a = a == null ? two : a.next;
    b = b == null ? one : b.next;
  }
  return a; // the shared node, or null if both reached the end together
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final shared = LinkedList(1, LinkedList(9, LinkedList(10)));
  final one = LinkedList(2, LinkedList(3, shared));
  final two = LinkedList(8, LinkedList(7, LinkedList(6, shared)));
  check(mergingLinkedLists(one, two)?.value, 1);
  check(mergingLinkedLists(LinkedList(1), LinkedList(2)), null);
}
