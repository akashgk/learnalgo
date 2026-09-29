# Three Number Sort

**Difficulty:** Medium | **Category:** Sorting | **Pattern:** Dutch national flag (3-way partition)

## Problem
Given an array containing only values from a 3-element `order` list, sort it in place so that all occurrences of `order[0]` come first, then `order[1]`, then `order[2]`. Not every value has to appear.

## Building up the logic
1. Counting sort: count each of the three values and overwrite. O(n) time, two passes, O(1) space. A perfectly good first answer.
2. **One pass (Dijkstra's Dutch national flag):** keep three regions with pointers `lo`, `mid`, `hi`:
   - `[0, lo)` holds `first`
   - `[lo, mid)` holds `second`
   - `[mid, hi]` is unexamined
   - `(hi, end]` holds `third`
3. Look at `array[mid]`:
   - `first`: swap into `lo`, advance both `lo` and `mid` (the value swapped out of `lo` is a known `second`).
   - `second`: already in place, advance `mid`.
   - `third`: swap with `hi`, decrement `hi`, but **do not** advance `mid`, because the value that came from `hi` has not been examined yet. This is the usual bug.
4. Stop when `mid > hi`.

## Complexity
- Time: O(n), one pass.
- Space: O(1).

## Interview notes
- LeetCode #75 (Sort Colors). 3-way partitioning is also how quicksort handles many duplicate keys efficiently.
- Dart note: `final [first, second, _] = order;` destructures a list with a wildcard.
