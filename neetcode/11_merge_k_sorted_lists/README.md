# Merge k Sorted Lists

**Difficulty:** Hard | **Category:** Linked List / Heap | **Pattern:** k-way merge with a min-heap, or pairwise divide and conquer | **Source:** LeetCode 23; NeetCode 150, Blind 75

## The problem

Merge `k` sorted linked lists into one sorted linked list.

```
[1 -> 4 -> 5, 1 -> 3 -> 4, 2 -> 6]  ->  1 -> 1 -> 2 -> 3 -> 4 -> 4 -> 5 -> 6
```

AlgoExpert very_hard 23 Merge Sorted Arrays is the same problem on arrays.

## Step 1: Brute force options

1. **Collect all values, sort, rebuild:** O(N log N) for N total nodes, O(N) space. Ignores that the lists are already sorted.
2. **Merge one list at a time** into a running result: the result grows, so the total work is about `N * k / 2`: **O(N * k)**.

## Step 2: Where is the waste?

At each step, the next output node is the **smallest current head** among k lists. Brute force finds it by scanning all k heads: O(k) per node, O(N * k) total.

A **min-heap** of the k heads gives the smallest in O(log k), and replacing it with its successor is another O(log k). Total **O(N log k)**.

## Step 3: Alternative with the same bound: merge in pairs

Merge lists 1+2, 3+4, 5+6, ... then merge the results in pairs again, like the merge phase of merge sort. There are `log k` rounds, and each round touches every node once: **O(N log k)**, with only O(k) extra space for the list of heads (no heap needed).

Both are good answers. The heap version generalizes to streams; the pairwise version is simple and allocation-free per node.

## Step 4: The code

<!-- CODE:START -->

Full source: [`merge_k_sorted_lists.dart`](merge_k_sorted_lists.dart) (run it with `dart run`).

```dart
// Merge k Sorted Lists: merge k sorted linked lists into one sorted list.
// Min-heap holding the current head of each list: pop the smallest, push its successor.
// O(N log k) time for N total nodes, O(k) extra space.

class ListNode {
  ListNode(this.value, [this.next]);
  int value;
  ListNode? next;
}

ListNode? mergeKLists(List<ListNode?> lists) {
  final heap = _MinHeap<ListNode>((a, b) => a.value.compareTo(b.value));
  for (final head in lists) {
    if (head != null) heap.push(head);
  }
  final dummy = ListNode(0);
  var tail = dummy;
  while (heap.isNotEmpty) {
    final node = heap.pop(); // smallest head among all lists
    tail.next = node;
    tail = node;
    if (node.next != null) heap.push(node.next!); // its list's next candidate
  }
  return dummy.next;
}

/// Alternative: divide and conquer, merging lists in pairs round by round. Also O(N log k) time:
/// log k rounds, each touching every node once. O(k) extra space for the list of heads.
ListNode? mergeKListsPairwise(List<ListNode?> lists) {
  if (lists.isEmpty) return null;
  var current = [...lists];
  while (current.length > 1) {
    current = [
      for (var i = 0; i < current.length; i += 2)
        i + 1 < current.length ? _mergeTwo(current[i], current[i + 1]) : current[i],
    ];
  }
  return current[0];
}

ListNode? _mergeTwo(ListNode? a, ListNode? b) {
  final dummy = ListNode(0);
  var tail = dummy;
  while (a != null && b != null) {
    if (a.value <= b.value) {
      tail.next = a;
      a = a.next;
    } else {
      tail.next = b;
      b = b.next;
    }
    tail = tail.next!;
  }
  tail.next = a ?? b;
  return dummy.next;
}

class _MinHeap<T> {
  _MinHeap(this._compare);
  final int Function(T, T) _compare;
  final _items = <T>[];

  bool get isNotEmpty => _items.isNotEmpty;

  void push(T item) {
    _items.add(item);
    var i = _items.length - 1;
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (_compare(_items[parent], _items[i]) <= 0) break;
      _swap(i, parent);
      i = parent;
    }
  }

  T pop() {
    final top = _items.first;
    final last = _items.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = last;
      var i = 0;
      while (true) {
        final l = 2 * i + 1, r = l + 1;
        var m = i;
        if (l < _items.length && _compare(_items[l], _items[m]) < 0) m = l;
        if (r < _items.length && _compare(_items[r], _items[m]) < 0) m = r;
        if (m == i) break;
        _swap(i, m);
        i = m;
      }
    }
    return top;
  }

  void _swap(int i, int j) {
    final t = _items[i];
    _items[i] = _items[j];
    _items[j] = t;
  }
}

ListNode? fromList(List<int> values) {
  ListNode? head;
  for (final v in values.reversed) {
    head = ListNode(v, head);
  }
  return head;
}

List<int> toList(ListNode? head) => [for (var c = head; c != null; c = c.next) c.value];
```

<!-- CODE:END -->

### Walkthrough of `mergeKLists`

- Push every non-null head.
- Repeatedly pop the smallest node, append it to the result, and push its `next` if any.
- Nodes are relinked, not copied: O(1) extra per node.

### Walkthrough of `mergeKListsPairwise`

- Each round builds a new list of heads, merging neighbors; an odd one out passes through.
- `_mergeTwo` is the standard two-list merge with a dummy head (AlgoExpert hard 37 Merge Linked Lists).

## Step 5: Dry run (heap)

Lists A = 1 4 5, B = 1 3 4, C = 2 6. Heap contents shown by value:

| step | pop | push (successor) | heap after |
|---|---|---|---|
| 1 | 1 (A) | 4 (A) | 1 (B), 2 (C), 4 (A) |
| 2 | 1 (B) | 3 (B) | 2 (C), 3 (B), 4 (A) |
| 3 | 2 (C) | 6 (C) | 3 (B), 4 (A), 6 (C) |
| 4 | 3 (B) | 4 (B) | 4 (A), 4 (B), 6 (C) |
| 5, 6 | 4 (A), 4 (B), in either order | 5 (A); B is exhausted | 5 (A), 6 (C) |
| 7 | 5 (A) | none | 6 (C) |
| 8 | 6 (C) | none | empty |

Output: `1 1 2 3 4 4 5 6`. Which of two equal values pops first does not matter.

## Complexity

| Approach | Time | Extra space |
|---|---|---|
| Collect and sort | O(N log N) | O(N) |
| Merge one by one | O(N * k) | O(1) |
| Min-heap | **O(N log k)** | O(k) |
| Pairwise merging | **O(N log k)** | O(k) |

## Edge cases

- `k = 0` or all lists empty: null.
- Some lists empty: skipped when building the heap.
- One list: returned as is.

## Common mistakes

- Pushing all N nodes into the heap at once (O(N log N), and O(N) memory).
- Forgetting to push the successor after popping.
- In the pairwise version, dropping the last list when k is odd.

## Follow-ups you should be ready for

1. **Streaming / external sort.** k sorted files merged with a heap of k file cursors: this is exactly how external merge sort works.
2. **Kth smallest element in k sorted lists / a sorted matrix.** Same heap, stop after k pops.
3. **Smallest range covering elements from k lists (LeetCode 632).** Heap of heads plus the current maximum.

## What to remember

Merging k sorted sequences costs O(N log k): either a heap of the k current heads, or log k rounds of pairwise merges.
