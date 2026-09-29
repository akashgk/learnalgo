# Laptop Rentals

**Difficulty:** Hard | **Category:** Heaps | **Pattern:** Interval overlap: min-heap of end times or sweep line

## Problem
Given rental intervals `[start, end)` for students, return the minimum number of laptops the school needs so every rental gets one. A laptop returned at time `t` can be handed to a rental starting at `t`.

## Building up the logic
1. The answer is the **maximum number of intervals overlapping at any moment**.
2. **Heap approach:** sort intervals by start. Keep a min-heap of end times of laptops in use. For each interval, if the earliest end `<= start`, reuse that laptop (pop). Push the new end. The heap's maximum size is the answer. O(n log n).
3. **Sweep line (this code):** sort starts and ends separately. Walk starts in order; before counting a start, retire every end `<= start`. Track the maximum in-use count. Also O(n log n), no heap needed.
4. Why separating starts and ends is valid: we only care how many intervals are active at each moment, not which ones.
5. The `<=` in the retire loop encodes the "returned at t can be reused at t" rule; with closed intervals it would be `<`.

## Complexity
- Time: O(n log n).
- Space: O(n).

## Interview notes
- LeetCode #253 (Meeting Rooms II). One of the most asked interval problems at Google, Meta, and Amazon. Be ready to present both the heap and sweep versions and explain the boundary rule.
