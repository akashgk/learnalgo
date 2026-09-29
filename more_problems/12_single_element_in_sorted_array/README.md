# Single Element in a Sorted Array

**Difficulty:** Medium | **Category:** Binary search | **Pattern:** Binary search on a structural property (pair alignment) | **Source:** LeetCode 540; Striver A2Z

## The problem

A sorted array has every value exactly twice, except one value that appears once. Find it in **O(log n)** time and O(1) space.

```
[1, 1, 2, 3, 3, 4, 4, 8, 8]  ->  2
[3, 3, 7, 7, 10, 11, 11]     ->  10
```

## Step 1: Easy answers that are too slow

- XOR of everything: pairs cancel, the single value remains. O(n). Elegant, but it ignores that the array is sorted, and the problem asks for O(log n).
- Scan pairs `(0,1), (2,3), ...` until a pair does not match. O(n).

"Sorted" plus "O(log n)" means binary search. But we are not searching for a value. What is the **monotone property** to search on?

## Step 2: Find the monotone property

Write indices under the first example:

```
value:  1 1 2 3 3 4 4 8 8
index:  0 1 2 3 4 5 6 7 8
```

**Before** the single element, pairs start at **even** indices: (0,1). **After** it, everything is shifted by one, and pairs start at **odd** indices: (3,4), (5,6), (7,8).

So for any even index `i`:

- if `nums[i] == nums[i + 1]`, the pairing is still intact at `i`: the single element is **after** `i + 1`.
- otherwise, the pairing is already broken: the single element is **at `i` or before it**.

That condition is false...false, then true...true as `i` moves right: a monotone predicate, which is exactly what binary search needs.

## Step 3: Make mid even

Only even indices give a clean test, so if `mid` is odd, step back one: `mid--`. Then compare `nums[mid]` with `nums[mid + 1]`.

- Intact: `lo = mid + 2` (skip the whole pair).
- Broken: `hi = mid`.

The search space always has odd length (the single element plus whole pairs), `lo` stays even, and the loop ends at `lo == hi`, the single element.

## Step 4: The code

<!-- CODE:START -->

Full source: [`single_element_in_sorted_array.dart`](single_element_in_sorted_array.dart) (run it with `dart run`).

```dart
// Single Element in a Sorted Array: every value appears twice except one. Find it.
// Binary search on pair alignment: before the single element, pairs start at even indices;
// after it, at odd indices. O(log n) time, O(1) space.

int singleNonDuplicate(List<int> nums) {
  var lo = 0, hi = nums.length - 1;
  while (lo < hi) {
    var mid = lo + (hi - lo) ~/ 2;
    if (mid.isOdd) mid--; // look at the pair that should start at an even index
    if (nums[mid] == nums[mid + 1]) {
      // Pairing is still intact up to mid + 1: the single element is to the right.
      lo = mid + 2;
    } else {
      // Pairing is already broken at mid: the single element is mid or to its left.
      hi = mid;
    }
  }
  return nums[lo];
}
```

<!-- CODE:END -->

### Walkthrough

- `if (mid.isOdd) mid--;` aligns mid to the start of a would-be pair. `lo` and `hi` are always even (they start at 0 and n - 1, n is odd, and they only move by even amounts or to an even mid), so inside the loop the aligned mid is at most `hi - 2`, and `nums[mid + 1]` is always in range.
- `lo = mid + 2` jumps over the intact pair.
- `hi = mid` keeps mid, since mid itself may be the single element.

## Step 5: Dry run

`[1, 1, 2, 3, 3, 4, 4, 8, 8]`:

| lo | hi | mid (aligned) | nums[mid], nums[mid+1] | action |
|---|---|---|---|---|
| 0 | 8 | 4 | 3, 4 (broken) | hi = 4 |
| 0 | 4 | 2 | 2, 3 (broken) | hi = 2 |
| 0 | 2 | 1 -> 0 | 1, 1 (intact) | lo = 2 |
| 2 | 2 | | | return **2** |

## Complexity

- Time: **O(log n)**.
- Space: **O(1)**.

## Edge cases

- Single element array: loop does not run.
- Single element first (`[1, 2, 2]`) or last (`[1, 1, 2]`): both handled by the same rules.

## Common mistakes

- Comparing `nums[mid]` with `nums[mid - 1]` and `nums[mid + 1]` with many special cases. Aligning mid to even removes all of them.
- `hi = mid - 1` (can skip the answer).
- Forgetting to align and getting the direction backwards for odd mid.

## Follow-ups you should be ready for

1. **The XOR trick for mid.** `mid ^ 1` is mid's partner index (even -> +1, odd -> -1). Then the test is `nums[mid] == nums[mid ^ 1]` without aligning.
2. **Unsorted array.** XOR everything, O(n); see more_problems 49 for the version with two singles.

## What to remember

Binary search works on any **monotone predicate over indices**, not only on values. Here the predicate is "pairs still start at even indices".
