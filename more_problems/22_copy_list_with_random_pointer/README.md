# Copy List with Random Pointer

**Difficulty:** Medium | **Category:** Linked lists | **Pattern:** Hash map old -> new, or interleave copies | **Source:** LeetCode 138; Striver A2Z, NeetCode 150

## The problem

Each node has `next` and `random` pointers; `random` points to any node in the list or null. Return a **deep copy**: brand-new nodes, with `next` and `random` pointing into the **copy**, never into the original.

```
7 -> 13 -> 11 -> 10 -> 1
random:  7 -> null, 13 -> 7, 11 -> 1, 10 -> 11, 1 -> 7
```

## Step 1: Why it is not just a list copy

Copying `next` is easy: walk and create nodes. The problem is `random`: when copying node 11, its random target (1) has not been created yet. And even when a target exists, you need to know **which copy** corresponds to it. The whole problem is: **given an original node, find its copy.**

## Step 2: Approach A, hash map (the one to lead with)

Two passes:

1. Create a copy of every node, storing `copies[original] = copy`.
2. For every original `x`: `copies[x].next = copies[x.next]`, `copies[x].random = copies[x.random]`.

The map answers "find its copy" in O(1). O(n) time, O(n) extra space. Clean, hard to get wrong.

## Step 3: Approach B, O(1) extra space by interleaving

Where else can we store "the copy of X" so we can find it from X in O(1)? **In `X.next` itself.** Weave each copy directly after its original:

```
7 -> 7' -> 13 -> 13' -> 11 -> 11' -> 10 -> 10' -> 1 -> 1'
```

Now "the copy of X" is `X.next`. Three passes:

1. **Weave:** insert `X'` after each `X`.
2. **Random pointers:** `X'.random = X.random?.next`. `X.random` is an original node, and its `.next` is its copy.
3. **Unweave:** restore `X.next` to the next original, and link the copies together.

The output list does not count as extra space, so this is O(1) extra.

## Step 4: The code

<!-- CODE:START -->

Full source: [`copy_list_with_random_pointer.dart`](copy_list_with_random_pointer.dart) (run it with `dart run`).

```dart
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
```

<!-- CODE:END -->

### Walkthrough of `copyRandomList`

- Pass 1 advances with `cur = cur.next!.next`: skip over the copy just inserted.
- Pass 2 uses `cur.random?.next`: null random stays null.
- Pass 3 uses a dummy head for the copy list. For each original `cur`, its copy is `cur.next`; `cur.next = copy.next` restores the original link, and the copy is appended to the result.
- The original list is fully restored, which the tests check. Leaving the input modified is a bug interviewers look for.

### Walkthrough of `copyRandomListWithMap`

- `copies[cur.next]` for the last node looks up `null`, which returns null, exactly right.
- `encode` and `build` in the file exist only for testing: they turn a list into `[value, randomIndex]` pairs.

## Step 5: Dry run (interleaving)

List `A(1) -> B(2)`, `A.random = B`, `B.random = B`.

| Pass | State |
|---|---|
| weave | `A -> A' -> B -> B'` |
| random | `A'.random = A.random.next = B.next = B'`; `B'.random = B.random.next = B'` |
| unweave | originals `A -> B`; copies `A' -> B'` with randoms `B'`, `B'` |

## Complexity

| Approach | Time | Extra space |
|---|---|---|
| Hash map | O(n) | O(n) |
| Interleave | O(n) | O(1) |

## Edge cases

- Empty list: null.
- Random pointing to itself: `X.random.next` is `X'`, correct.
- All randoms null.

## Common mistakes

- Setting `copy.random = original.random` (points into the original list: a shallow copy).
- In the interleave version, setting `random` during the unweave pass, after some `next` links are already restored (the `X.random.next` trick then breaks).
- Not restoring the original list.

## Follow-ups you should be ready for

1. **Clone Graph (LeetCode 133).** The same hash map old -> new, with BFS or DFS.
2. **Copy a binary tree with random pointers (LeetCode 1485).** Same map idea.
3. **Recursive version.** `copy(x) = memo[x] ??= Node(x.value)..next = copy(x.next)..random = copy(x.random)`; beware recursion depth on long lists.

## What to remember

Deep copy of a pointer structure = "map each original to its copy". A hash map is the general tool; interleaving hides the map inside the `next` pointers for O(1) space.
