// Linked List Palindrome: find the middle, reverse the second half, compare, restore.
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

bool linkedListPalindrome(LinkedList head) {
  // Slow ends at the start of the second half (the middle node for odd lengths).
  var slow = head;
  LinkedList? fast = head;
  while (fast != null && fast.next != null) {
    slow = slow.next!;
    fast = fast.next!.next;
  }
  final secondHead = _reverse(slow);
  var isPalindrome = true;
  LinkedList? a = head, b = secondHead;
  while (b != null) {
    if (a!.value != b.value) {
      isPalindrome = false;
      break;
    }
    a = a.next;
    b = b.next;
  }
  _reverse(secondHead); // restore the original list for the caller
  return isPalindrome;
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
  final list = LinkedList.fromList([0, 1, 2, 2, 1, 0]);
  check(linkedListPalindrome(list), true);
  check(list.toList(), [0, 1, 2, 2, 1, 0]); // restored
  check(linkedListPalindrome(LinkedList.fromList([1, 2, 3, 2, 1])), true);
  check(linkedListPalindrome(LinkedList.fromList([1, 2])), false);
  check(linkedListPalindrome(LinkedList(7)), true);
}
