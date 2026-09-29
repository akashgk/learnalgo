# Min Heap Construction

**Difficulty:** Medium | **Category:** Heaps | **Pattern:** Array-backed binary heap

## Problem
Implement a `MinHeap` class backed by an array, supporting: `buildHeap(array)`, `insert(value)`, `remove()` (remove and return the minimum), `peek()`, `siftUp`, and `siftDown`.

## Building up the logic
1. **Shape:** a complete binary tree stored level by level in an array. For index `i`: children at `2i + 1` and `2i + 2`, parent at `(i - 1) ~/ 2`. No pointers needed.
2. **Heap property:** every parent <= its children, so the minimum is at index 0.
3. **insert:** append at the end (keeps the shape complete), then **sift up**: swap with the parent while smaller. O(log n).
4. **remove:** swap the root with the last element, pop the last (the old minimum), then **sift down** the new root: swap with the smaller child while larger than it. Always choosing the **smaller** child is what keeps the property. O(log n).
5. **buildHeap:** calling insert n times costs O(n log n). Instead, sift down every non-leaf node from the last parent `(n - 2) ~/ 2` back to the root. This is O(n) because most nodes are near the bottom and sift down only a short distance. The sum `n/4 * 1 + n/8 * 2 + n/16 * 3 + ...` converges to O(n). Being able to explain this is a strong signal.

## Complexity
| Operation | Time |
|---|---|
| buildHeap | O(n) |
| insert | O(log n) |
| remove | O(log n) |
| peek | O(1) |

Space: O(1) extra (in place).

## Interview notes
- Dart has no heap in the core SDK (`PriorityQueue` lives in `package:collection`). In an interview, say which library you would use, and be ready to write this class from memory, since several hard problems in this repo (Laptop Rentals, Continuous Median, Merge Sorted Arrays, Dijkstra) need one.
- Max heap: flip the comparisons, or store negated values in a min heap.
