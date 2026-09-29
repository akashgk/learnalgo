# Find Minimum in Rotated Sorted Array

**Difficulty:** Medium | **Category:** Binary search | **Pattern:** Binary search on a rotated array (compare with the right end) | **Source:** LeetCode 153; Striver A2Z, NeetCode 150

## The problem

A sorted array of **distinct** values was rotated at an unknown pivot (for example `[0, 1, 2, 4, 5, 6, 7]` became `[4, 5, 6, 7, 0, 1, 2]`). Find the minimum in O(log n).

```
[3, 4, 5, 1, 2]        ->  1
[4, 5, 6, 7, 0, 1, 2]  ->  0
[11, 13, 15, 17]       ->  11    (rotated by 0, or by n)
```

## Step 1: Picture it

A rotated sorted array is **two ascending runs**, and every value in the left run is greater than every value in the right run:

```
 7 .
6 .          left run:  4 5 6 7
5 .
4 .                     the drop
         2 .
       1 .   right run: 0 1 2
     0 .
```

The minimum is the first element of the right run (or `nums[0]` if there is no rotation).

## Step 2: Brute force

Linear scan for the minimum, or for the drop `nums[i] > nums[i + 1]`: O(n).

## Step 3: What does one comparison tell us?

Compare `nums[mid]` with `nums[hi]` (the right end of the current range):

- `nums[mid] > nums[hi]`: mid is in the **left** run (values in the left run are bigger than everything in the right run). The minimum is **strictly right** of mid: `lo = mid + 1`.
- `nums[mid] < nums[hi]`: mid..hi is ascending, so mid is in the right run or the range is sorted. The minimum is **at mid or left of it**: `hi = mid`. (Not `mid - 1`: mid itself might be the minimum.)

The loop runs while `lo < hi` and ends with `lo == hi` at the minimum. The invariant, "the minimum is in `[lo, hi]`", holds after every step, and the range shrinks every step (`mid < hi` always because `mid` rounds down).

**Why compare with `hi`, not `lo`?** With `nums[mid] > nums[lo]` you cannot tell "mid is in the left run of a rotated array" (answer to the right) from "the whole range is sorted" (answer is `lo`, to the left). Comparing with `hi` has no such ambiguity. This is the step most people get wrong.

## Step 4: The code

<!-- CODE:START -->

Full source: [`find_minimum_in_rotated_sorted_array.dart`](find_minimum_in_rotated_sorted_array.dart) (run it with `dart run`).

```dart
// Find Minimum in Rotated Sorted Array (distinct values).
// Binary search comparing mid with the right end. O(log n) time, O(1) space.

int findMin(List<int> nums) {
  var lo = 0, hi = nums.length - 1;
  // Invariant: the minimum is always inside [lo, hi].
  while (lo < hi) {
    final mid = lo + (hi - lo) ~/ 2;
    if (nums[mid] > nums[hi]) {
      // The drop (rotation point) is strictly to the right of mid.
      lo = mid + 1;
    } else {
      // nums[mid..hi] is sorted, so the minimum is at mid or to its left.
      hi = mid;
    }
  }
  return nums[lo];
}
```

<!-- CODE:END -->

### Walkthrough

- `mid = lo + (hi - lo) ~/ 2` rounds down, so `mid < hi` whenever `lo < hi`, and `hi = mid` always shrinks the range.
- Values are distinct, so `nums[mid] == nums[hi]` only when `mid == hi`, which cannot happen inside the loop. The `else` branch is the `<` case.

## Step 5: Dry run

`[4, 5, 6, 7, 0, 1, 2]`:

| lo | hi | mid | nums[mid] vs nums[hi] | action |
|---|---|---|---|---|
| 0 | 6 | 3 | 7 > 2 | lo = 4 |
| 4 | 6 | 5 | 1 < 2 | hi = 5 |
| 4 | 5 | 4 | 0 < 1 | hi = 4 |
| 4 | 4 | | | return nums[4] = **0** |

## Complexity

- Time: **O(log n)**.
- Space: **O(1)**.

## Edge cases

- Not rotated: every comparison takes `hi = mid`, ending at index 0.
- Two elements `[2, 1]`: mid = 0, 2 > 1, lo = 1.
- One element: the loop does not run.

## Common mistakes

- Comparing with `nums[lo]`.
- `hi = mid - 1` (skips the minimum when mid is the minimum).
- `while (lo <= hi)` with `hi = mid`: infinite loop when `lo == hi`.

## Follow-ups you should be ready for

1. **With duplicates (LeetCode 154).** When `nums[mid] == nums[hi]`, you cannot tell which side; do `hi--` (safe because `nums[hi]` has a copy at mid). Worst case becomes O(n), for example `[1, 1, 1, 0, 1]`.
2. **Search for a target in a rotated array (LeetCode 33).** See AlgoExpert hard 44 Shifted Binary Search: decide which half is sorted, then check whether the target lies in it.
3. **How many times was it rotated?** The index of the minimum.

## What to remember

In a rotated sorted array, compare `mid` with the **right end**: bigger means you are in the left run and the minimum is to the right; smaller means the minimum is at mid or to its left.
