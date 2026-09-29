// Find Loop: return the node where a linked list's cycle begins (a loop is guaranteed).
// Floyd's tortoise and hare. O(n) time, O(1) space.

class LinkedList {
  LinkedList(this.value, [this.next]);
  int value;
  LinkedList? next;
}

LinkedList findLoop(LinkedList head) {
  var slow = head.next!, fast = head.next!.next!;
  while (!identical(slow, fast)) {
    slow = slow.next!;
    fast = fast.next!.next!;
  }
  // Meeting point is k steps (the tail length, mod loop size) before the loop start.
  var p = head;
  while (!identical(p, fast)) {
    p = p.next!;
    fast = fast.next!;
  }
  return p;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  // 0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9 -> back to 4
  final nodes = List.generate(10, LinkedList.new);
  for (var i = 0; i < 9; i++) {
    nodes[i].next = nodes[i + 1];
  }
  nodes[9].next = nodes[4];
  check(findLoop(nodes[0]).value, 4);
  final self = LinkedList(1);
  self.next = self;
  check(findLoop(self).value, 1);
}
