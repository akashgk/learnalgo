# Shifted Binary Search

**Difficulty:** Hard | **Category:** Searching | **Pattern:** Binary search on a rotated array

## The problem

A sorted array of **distinct** integers has been **shifted** (rotated) by an unknown amount: some prefix was moved to the end. Given a target, return its index, or -1 if absent, in O(log n) time.

```
array = [45, 61, 71, 72, 73, 0, 1, 21, 33, 37], target = 33  ->  8
```

## Step 1: What rotation does to a sorted array

A rotated sorted array consists of **two sorted runs**: `45 61 71 72 73` and `0 1 21 33 37`. There is exactly one "drop" (73 to 0).

Plain binary search fails: comparing the target with the middle no longer tells you which half it is in.

## Step 2: One half is always sorted

Pick `mid`. The drop is in at most one of the two halves `[lo, mid]` and `[mid, hi]`. So **at least one half is fully sorted**, and you can tell which:

- if `array[lo] <= array[mid]`, the left half `[lo, mid]` is sorted;
- otherwise the right half `[mid, hi]` is sorted.

In a sorted half you can test membership exactly with its two endpoints. So:

- If the left half is sorted and `array[lo] <= target < array[mid]`: search left. Otherwise search right.
- If the right half is sorted and `array[mid] < target <= array[hi]`: search right. Otherwise search left.

Each step still discards half of the range: O(log n).

## Step 3: The code

<!-- CODE:START -->

Full source: [`shifted_binary_search.dart`](shifted_binary_search.dart) (run it with `dart run`).

```dart
// Shifted Binary Search: sorted array of distinct ints rotated by an unknown amount.
// At every step one half is sorted; decide if the target lies in it. O(log n) time, O(1) space.

int shiftedBinarySearch(List<int> array, int target) {
  var lo = 0, hi = array.length - 1;
  while (lo <= hi) {
    final mid = lo + (hi - lo) ~/ 2;
    if (array[mid] == target) return mid;
    if (array[lo] <= array[mid]) {
      // left half [lo, mid] is sorted
      if (array[lo] <= target && target < array[mid]) {
        hi = mid - 1;
      } else {
        lo = mid + 1;
      }
    } else {
      // right half [mid, hi] is sorted
      if (array[mid] < target && target <= array[hi]) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
  }
  return -1;
}
```

<!-- CODE:END -->

### Walkthrough

- Standard inclusive binary search loop.
- `array[lo] <= array[mid]` uses `<=` because `lo` can equal `mid` (a range of one or two elements), and a single element is trivially sorted.
- The range tests use strict comparisons with `array[mid]` because `mid` itself was already checked.

## Step 4: Dry run (target 33)

| lo | hi | mid (value) | sorted half | target in it? | action |
|---|---|---|---|---|---|
| 0 | 9 | 4 (73) | left (45 <= 73) | 45 <= 33? no | lo = 5 |
| 5 | 9 | 7 (21) | left (0 <= 21) | 0 <= 33 < 21? no | lo = 8 |
| 8 | 9 | 8 (33) | | found | return 8 |

## Complexity

- **Time: O(log n)**.
- **Space: O(1)**.

## Common mistakes

- Using `<` in `array[lo] <= array[mid]` (breaks when `lo == mid`).
- Forgetting that the target might equal an endpoint of the sorted half (use `<=` on the outer endpoint).

## Follow-ups

1. **Search in Rotated Sorted Array (LeetCode #33).**
2. **With duplicates (#81):** when `array[lo] == array[mid] == array[hi]`, you cannot tell which half is sorted; shrink both ends by one. The worst case becomes O(n).
3. **Find the minimum / the rotation point (#153):** binary search comparing `array[mid]` with `array[hi]`.

## What to remember

In a rotated sorted array, one half around `mid` is always sorted; decide whether the target lies in that sorted half by checking its endpoints.
