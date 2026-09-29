# Binary Search

**Difficulty:** Easy | **Category:** Searching | **Pattern:** Binary search

## The problem

Given a sorted array of integers and a target integer, return the index of the target in the array, or -1 if it is not present.

```
array = [0, 1, 21, 33, 45, 45, 61, 71, 72, 73], target = 33  ->  3
target = 70  ->  -1
```

## Step 1: Work an example by hand

Think of looking up a word in a paper dictionary. You open it near the middle. If your word comes earlier alphabetically, you throw away the entire second half and repeat on the first half. Each look halves what is left.

For target 33 in the array above (indices 0 to 9):

- Middle index 4 holds 45. 33 < 45, so the target can only be in indices 0..3.
- Middle of 0..3 is index 1, holding 1. 33 > 1, so it must be in 2..3.
- Middle of 2..3 is index 2, holding 21. 33 > 21, so check 3..3.
- Index 3 holds 33. Found.

Four comparisons instead of up to ten.

## Step 2: Brute force

Linear scan: O(n). It ignores that the array is sorted, which is the whole point of the question.

## Step 3: The invariant

Binary search is short but notoriously easy to get subtly wrong. The cure is to choose an **invariant** and make every line obey it:

> If the target is in the array, it is at an index in `[lo, hi]` (both ends **inclusive**).

Everything follows from that sentence:

- Start: `lo = 0`, `hi = n - 1` (the whole array).
- Continue while the range is non-empty: `while (lo <= hi)`.
- If `array[mid] < target`: the target is right of `mid`, and `mid` itself is ruled out: `lo = mid + 1`.
- If `array[mid] > target`: `hi = mid - 1`.
- When `lo > hi`, the range is empty: the target is absent.

The other common convention is half-open `[lo, hi)`: `hi = n`, `while (lo < hi)`, `hi = mid`. Both are correct. Bugs come from **mixing** them, for example `while (lo < hi)` with `hi = mid - 1`.

### Computing the middle

`mid = lo + (hi - lo) ~/ 2` instead of `(lo + hi) ~/ 2`. In languages with 32-bit ints (Java, C++), `lo + hi` can overflow for huge arrays. This was a real bug in the Java standard library for nine years. Dart's 64-bit ints make it irrelevant here, but interviewers like hearing that you know it.

## Step 4: The code

<!-- CODE:START -->

Full source: [`binary_search.dart`](binary_search.dart) (run it with `dart run`).

```dart
// Binary Search on a sorted array. Returns index or -1. O(log n) time, O(1) space.

int binarySearch(List<int> array, int target) {
  var lo = 0, hi = array.length - 1;
  while (lo <= hi) {
    final mid = lo + (hi - lo) ~/ 2; // avoids overflow in fixed-width languages
    final value = array[mid];
    if (value == target) return mid;
    if (value < target) {
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return -1;
}
```

<!-- CODE:END -->

### Walkthrough

- `var lo = 0, hi = array.length - 1;` covers the whole array, inclusive.
- `while (lo <= hi)` means the range still has at least one element.
- `if (value == target) return mid;` found.
- `lo = mid + 1` / `hi = mid - 1` shrink the range and always exclude `mid`, which guarantees progress (the loop cannot get stuck).

## Step 5: Dry run

Target 70 (absent):

| lo | hi | mid | array[mid] | action |
|---|---|---|---|---|
| 0 | 9 | 4 | 45 | 45 < 70: lo = 5 |
| 5 | 9 | 7 | 71 | 71 > 70: hi = 6 |
| 5 | 6 | 5 | 45 | 45 < 70: lo = 6 |
| 6 | 6 | 6 | 61 | 61 < 70: lo = 7 |
| 7 | 6 | | | lo > hi: return -1 |

## Complexity

- **Time: O(log n)**. Each iteration halves the range. After k iterations at most `n / 2^k` elements remain; that reaches 1 when `k = log2(n)`. For a million elements, about 20 comparisons.
- **Space: O(1)** iterative. A recursive version uses O(log n) stack.

## Edge cases

- Empty array: `hi = -1`, loop never runs, return -1.
- Target smaller than everything or larger than everything.
- Duplicates (`45, 45`): returns **some** matching index, not necessarily the first. For the first or last occurrence, see Search For Range (hard 45).

## Common mistakes

- `while (lo < hi)` with the inclusive convention: never checks the last remaining element.
- `lo = mid` instead of `mid + 1`: infinite loop when `hi = lo + 1`.
- Using binary search on unsorted data.

## Variants you must be able to derive from this template

| Variant | Change | Repo problem |
|---|---|---|
| First / last occurrence | keep searching left/right after a match | hard 45 Search For Range |
| Insertion position (lower bound) | half-open range, return `lo` | hard 45 |
| Rotated sorted array | decide which half is sorted first | hard 44 Shifted Binary Search |
| Monotonic predicate | search for the first index where a condition becomes true | hard 47 Index Equals Value |
| Search on the answer | binary search over possible answers with a feasibility check | very hard 32 Optimal Assembly Line |

## What to remember

Write the invariant ("the target, if present, is in `[lo, hi]`") before the code, then make every line consistent with it.
