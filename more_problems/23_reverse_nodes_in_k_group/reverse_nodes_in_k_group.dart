// Reverse Nodes in k-Group: reverse every consecutive block of k nodes; a final block
// shorter than k stays as is. Iterative, relinking in place. O(n) time, O(1) space.

class ListNode {
  ListNode(this.value, [this.next]);
  int value;
  ListNode? next;
}

ListNode? reverseKGroup(ListNode? head, int k) {
  final dummy = ListNode(0, head);
  var groupPrev = dummy; // node just before the current group
  while (true) {
    // Find the k-th node of this group; stop if the group is incomplete.
    ListNode? kth = groupPrev;
    for (var i = 0; i < k && kth != null; i++) {
      kth = kth.next;
    }
    if (kth == null) break;
    final groupNext = kth.next; // first node after the group
    // Standard reversal, but the reversed tail links to groupNext instead of null.
    ListNode? prev = groupNext;
    var cur = groupPrev.next;
    while (cur != groupNext) {
      final next = cur!.next;
      cur.next = prev;
      prev = cur;
      cur = next;
    }
    // The old first node is now the last node of the group.
    final oldFirst = groupPrev.next!;
    groupPrev.next = kth;
    groupPrev = oldFirst;
  }
  return dummy.next;
}

ListNode? fromList(List<int> values) {
  ListNode? head;
  for (final v in values.reversed) {
    head = ListNode(v, head);
  }
  return head;
}

List<int> toList(ListNode? head) => [for (var c = head; c != null; c = c.next) c.value];

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(toList(reverseKGroup(fromList([1, 2, 3, 4, 5]), 2)), [2, 1, 4, 3, 5]);
  check(toList(reverseKGroup(fromList([1, 2, 3, 4, 5]), 3)), [3, 2, 1, 4, 5]);
  check(toList(reverseKGroup(fromList([1, 2, 3, 4, 5, 6]), 3)), [3, 2, 1, 6, 5, 4]);
  check(toList(reverseKGroup(fromList([1, 2, 3]), 1)), [1, 2, 3]);
  check(toList(reverseKGroup(fromList([1, 2]), 3)), [1, 2]);
  check(toList(reverseKGroup(null, 2)), []);
}
