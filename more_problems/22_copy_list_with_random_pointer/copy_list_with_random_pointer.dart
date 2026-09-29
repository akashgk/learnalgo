// Copy List with Random Pointer: deep-copy a linked list whose nodes also have a random pointer.
// Interleaving trick: weave each copy right after its original, set random pointers
// (copy.random = original.random.next), then unweave. O(n) time, O(1) extra space.

class Node {
  Node(this.value);
  int value;
  Node? next;
  Node? random;
}

Node? copyRandomList(Node? head) {
  // 1. A -> B -> C  becomes  A -> A' -> B -> B' -> C -> C'
  for (var cur = head; cur != null; cur = cur.next!.next) {
    final copy = Node(cur.value)..next = cur.next;
    cur.next = copy;
  }
  // 2. The copy of X.random is X.random.next.
  for (var cur = head; cur != null; cur = cur.next!.next) {
    cur.next!.random = cur.random?.next;
  }
  // 3. Separate the two lists, restoring the original.
  final dummy = Node(0);
  var tail = dummy;
  for (var cur = head; cur != null; cur = cur.next) {
    final copy = cur.next!;
    cur.next = copy.next;
    tail.next = copy;
    tail = copy;
  }
  return dummy.next;
}

/// Alternative: hash map original -> copy. O(n) time, O(n) space; easier to get right.
Node? copyRandomListWithMap(Node? head) {
  final copies = <Node, Node>{};
  for (var cur = head; cur != null; cur = cur.next) {
    copies[cur] = Node(cur.value);
  }
  for (var cur = head; cur != null; cur = cur.next) {
    copies[cur]!
      ..next = copies[cur.next]
      ..random = copies[cur.random];
  }
  return copies[head];
}

/// Encodes a list as [[value, randomIndex or null], ...] for comparison.
List<List<int?>> encode(Node? head) {
  final index = <Node, int>{};
  var i = 0;
  for (var cur = head; cur != null; cur = cur.next) {
    index[cur] = i++;
  }
  return [
    for (var cur = head; cur != null; cur = cur.next) [cur.value, cur.random == null ? null : index[cur.random]],
  ];
}

Node? build(List<List<int?>> spec) {
  final nodes = [for (final s in spec) Node(s[0]!)];
  for (var i = 0; i < nodes.length; i++) {
    if (i + 1 < nodes.length) nodes[i].next = nodes[i + 1];
    if (spec[i][1] != null) nodes[i].random = nodes[spec[i][1]!];
  }
  return nodes.isEmpty ? null : nodes[0];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final spec = [
    [7, null],
    [13, 0],
    [11, 4],
    [10, 2],
    [1, 0],
  ];
  for (final copyFn in [copyRandomList, copyRandomListWithMap]) {
    final head = build(spec);
    final copy = copyFn(head);
    check(encode(copy), spec);
    check(encode(head), spec); // the original is left intact
    // Deep copy: no node is shared.
    final originals = <Node>{for (var c = head; c != null; c = c.next) c};
    var shared = false;
    for (var c = copy; c != null; c = c.next) {
      if (originals.contains(c)) shared = true;
    }
    check(shared, false);
  }
  check(copyRandomList(null), null);
  check(
    encode(
      copyRandomList(
        build([
          [1, 0],
        ]),
      ),
    ),
    [
      [1, 0],
    ],
  ); // random points to itself
}
