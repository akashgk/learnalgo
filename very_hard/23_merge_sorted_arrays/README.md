# Merge Sorted Arrays

**Difficulty:** Very Hard | **Category:** Heaps | **Pattern:** K-way merge with a min-heap

## Problem
Given k arrays, each sorted ascending, return a single sorted array containing all their elements.

## Building up the logic
1. Concatenate and sort: O(N log N). Ignores that inputs are sorted.
2. **Scan the fronts:** at each step, the next output element is the smallest among the k current front elements. Finding it by scanning is O(k) per element: O(N * k).
3. **Min-heap of fronts:** keep one `(value, arrayIndex, elementIndex)` entry per array. Pop the minimum, output it, and push the next element from the same array. O(log k) per element.
4. **Divide and conquer alternative:** merge arrays in pairs (like merge sort's upper levels): log k rounds, each touching all N elements. Also O(N log k), and no heap needed.

## Complexity
| Approach | Time | Space |
|---|---|---|
| Concatenate + sort | O(N log N) | O(N) |
| Linear scan of fronts | O(N * k) | O(N + k) |
| Min-heap / pairwise merge | O(N log k) | O(N + k) |

## Interview notes
- LeetCode #23 (Merge k Sorted Lists). External sorting of files too large for memory uses exactly this k-way merge on sorted chunks; mentioning it connects the question to real systems.
