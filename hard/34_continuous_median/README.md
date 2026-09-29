# Continuous Median

**Difficulty:** Hard | **Category:** Heaps | **Pattern:** Two heaps (lower max-heap, upper min-heap)

## Problem
Implement a class that receives integers one by one via `insert(number)` and can always return the median of everything inserted so far (average of the two middle values for an even count) in O(1).

## Building up the logic
1. Keeping a sorted list: insertion is O(n) (shifting), median O(1).
2. The median only depends on the **boundary** between the lower half and the upper half. You need fast access to the largest of the lower half and the smallest of the upper half.
3. So keep the lower half in a **max-heap** and the upper half in a **min-heap**. Invariants:
   - every element in `lower` <= every element in `upper`;
   - their sizes differ by at most 1.
4. **Insert:** push into `lower` if the number is below `lower`'s max, else into `upper`. Then, if one heap is more than one larger, move its top to the other.
5. **Median:** equal sizes -> average of both tops; otherwise the top of the larger heap.

## Complexity
- insert: O(log n).
- getMedian: O(1).
- Space: O(n).

## Interview notes
- LeetCode #295 (Find Median from Data Stream). Follow-ups: sliding-window median (#480, needs deletions: lazy deletion with a hash map of pending removals, or an ordered multiset); "if all numbers are in [0, 100]" (bucket counts, O(1) insert).
