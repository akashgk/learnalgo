# Linked List Construction

**Difficulty:** Medium | **Category:** Linked Lists | **Pattern:** Doubly linked list pointer surgery

## The problem

Implement a doubly linked list class with `head` and `tail` pointers and these methods:

- `setHead(node)`, `setTail(node)`;
- `insertBefore(node, nodeToInsert)`, `insertAfter(node, nodeToInsert)`;
- `insertAtPosition(position, nodeToInsert)` (1-based);
- `removeNodesWithValue(value)`, `remove(node)`;
- `containsNodeWithValue(value)`.

If a node being inserted is **already in the list**, it must be **moved** (removed from its old position first).

## Step 1: Design: build on two primitives

Most methods are special cases of two operations:

- `remove(node)`: unlink a node from wherever it is;
- `insertBefore(node, x)` / `insertAfter(node, x)`: link `x` next to `node`.

Then:

- `setHead(x)` = `insertBefore(head, x)` (or make it the only node if the list is empty);
- `setTail(x)` = `insertAfter(tail, x)`;
- `insertAtPosition(p, x)` = walk to the p-th node and `insertBefore` it (or `setTail` if the list is shorter).

Writing a few primitives carefully and reusing them is far less error-prone than writing seven independent methods.

## Step 2: remove(node): four things to update

```
before:  prev <-> node <-> next
after:   prev <-> next
```

1. If `node` is the head, the head becomes `node.next`.
2. If `node` is the tail, the tail becomes `node.prev`.
3. `prev.next = next` (if prev exists).
4. `next.prev = prev` (if next exists).
5. Clear `node.prev` and `node.next`, so the node can be reinserted cleanly.

## Step 3: insertBefore(node, x): order matters

```
before:  p <-> node          after:  p <-> x <-> node
```

1. Remove `x` first (handles "move").
2. `x.prev = node.prev; x.next = node;`
3. If `node` was the head, `x` becomes the head; otherwise `node.prev.next = x`.
4. `node.prev = x`.

Step 4 must come last: step 3 still reads the **old** `node.prev`. Updating pointers in the wrong order is the classic bug here.

Edge case: inserting the list's only node relative to itself. Removing it would empty the list; just return.

## Step 4: The code

<!-- CODE:START -->

Full source: [`linked_list_construction.dart`](linked_list_construction.dart) (run it with `dart run`).

```dart
// Doubly Linked List Construction with head/tail. All operations O(1) except those that
// search or walk to a position (O(n)). Inserting an existing node moves it.

class Node {
  Node(this.value);
  int value;
  Node? prev;
  Node? next;
}

class DoublyLinkedList {
  Node? head;
  Node? tail;

  void setHead(Node node) {
    if (head == null) {
      head = tail = node;
      return;
    }
    insertBefore(head!, node);
  }

  void setTail(Node node) {
    if (tail == null) {
      setHead(node);
      return;
    }
    insertAfter(tail!, node);
  }

  void insertBefore(Node node, Node nodeToInsert) {
    if (identical(nodeToInsert, head) && identical(nodeToInsert, tail)) return; // only node
    remove(nodeToInsert);
    nodeToInsert
      ..prev = node.prev
      ..next = node;
    if (node.prev == null) {
      head = nodeToInsert;
    } else {
      node.prev!.next = nodeToInsert;
    }
    node.prev = nodeToInsert;
  }

  void insertAfter(Node node, Node nodeToInsert) {
    if (identical(nodeToInsert, head) && identical(nodeToInsert, tail)) return;
    remove(nodeToInsert);
    nodeToInsert
      ..prev = node
      ..next = node.next;
    if (node.next == null) {
      tail = nodeToInsert;
    } else {
      node.next!.prev = nodeToInsert;
    }
    node.next = nodeToInsert;
  }

  /// 1-based position. Position past the end appends at the tail.
  void insertAtPosition(int position, Node nodeToInsert) {
    if (position == 1) {
      setHead(nodeToInsert);
      return;
    }
    var node = head;
    for (var p = 1; node != null && p < position; p++) {
      node = node.next;
    }
    if (node == null) {
      setTail(nodeToInsert);
    } else {
      insertBefore(node, nodeToInsert);
    }
  }

  void removeNodesWithValue(int value) {
    var node = head;
    while (node != null) {
      final next = node.next; // save before unlinking
      if (node.value == value) remove(node);
      node = next;
    }
  }

  void remove(Node node) {
    if (identical(node, head)) head = head!.next;
    if (identical(node, tail)) tail = tail!.prev;
    node.prev?.next = node.next;
    node.next?.prev = node.prev;
    node
      ..prev = null
      ..next = null;
  }

  bool containsNodeWithValue(int value) {
    for (var n = head; n != null; n = n.next) {
      if (n.value == value) return true;
    }
    return false;
  }

  List<int> toList() => [for (var n = head; n != null; n = n.next) n.value];
  List<int> toListBackward() => [for (var n = tail; n != null; n = n.prev) n.value];
}
```

<!-- CODE:END -->

### Walkthrough

- `setHead` / `setTail` handle the empty list first, then delegate.
- `insertBefore` / `insertAfter` implement Step 3 (mirrored for "after").
- `insertAtPosition` walks `position - 1` steps; if it falls off the end, it appends.
- `removeNodesWithValue` saves `next` **before** calling `remove`, because `remove` clears the node's pointers.
- `remove` uses Dart's null-aware `?.` to update neighbors only if they exist.
- `toList` / `toListBackward` (test helpers) check both directions, which catches broken `prev` pointers.

## Step 5: Dry run: moving an existing node

List `4 <-> 1 <-> 2 <-> 3a <-> 3b <-> 5`; call `insertBefore(5, 3a)`:

| step | list |
|---|---|
| remove(3a) | 4 <-> 1 <-> 2 <-> 3b <-> 5 |
| 3a.prev = 3b, 3a.next = 5 | (3a points into the list) |
| 3b.next = 3a | 4 <-> 1 <-> 2 <-> 3b <-> 3a -> 5 |
| 5.prev = 3a | 4 <-> 1 <-> 2 <-> 3b <-> 3a <-> 5 |

## Complexity

| Operation | Time |
|---|---|
| setHead, setTail, insertBefore, insertAfter, remove | O(1) |
| insertAtPosition | O(p) |
| removeNodesWithValue, containsNodeWithValue | O(n) |

Space: O(1) per operation.

## Common mistakes

- Forgetting to update `head`/`tail` when removing or inserting at the ends.
- Overwriting a pointer before reading it.
- Not handling "insert a node that is already in the list".

## Design alternative: sentinel nodes

Keep permanent dummy `head` and `tail` nodes. Every real node then always has a non-null `prev` and `next`, which removes almost all null checks. LRU Cache (very hard 24) uses this.

## Follow-ups

1. **LRU Cache (very hard 24):** a hash map plus exactly this doubly linked list.
2. **Design Linked List (LeetCode #707).**

## What to remember

Write `remove` and `insertBefore/After` carefully (draw the boxes, order the pointer updates), then build everything else from them.
