# Search For Range

**Difficulty:** Hard | **Category:** Searching | **Pattern:** Lower-bound binary search

## The problem

Given a sorted array of integers and a target, return `[firstIndex, lastIndex]` of the target, or `[-1, -1]` if it is not present. Run in O(log n).

```
[0, 1, 21, 33, 45, 45, 45, 45, 45, 45, 61, 71, 73], target = 45  ->  [4, 9]
```

## Step 1: The naive extension

Binary search for any 45, then walk left and right to the ends of the run. If the whole array is 45s, the walk is O(n). Not good enough.

## Step 2: Search for the boundaries directly

Define **lowerBound(x)** = the first index whose value is `>= x` (or n if none). Then:

- the first occurrence of the target is `lowerBound(target)`, provided the value there equals the target;
- the last occurrence is `lowerBound(target + 1) - 1` (for integers: the first value >= target + 1 is one past the last target).

Two binary searches: O(log n).

## Step 3: Writing lowerBound without off-by-one errors

Use a **half-open** range `[lo, hi)` with the invariant "the answer is in `[lo, hi]`" (`hi = n` means "not found"):

```
lo = 0, hi = n
while lo < hi:
    mid = (lo + hi) / 2
    if a[mid] < x: lo = mid + 1      # mid is too small; the answer is to the right
    else:          hi = mid          # mid might be the answer; keep it
return lo
```

When the loop ends, `lo == hi` is the boundary. Learn this one template; every "first/last/insertion position" problem is a variation of it.

## Step 4: The code

<!-- CODE:START -->

Full source: [`search_for_range.dart`](search_for_range.dart) (run it with `dart run`).

```dart
// Search For Range: first and last index of target in a sorted array, or [-1, -1].
// Two binary searches (lower bound and upper bound). O(log n) time, O(1) space.

List<int> searchForRange(List<int> array, int target) {
  /// First index whose value is >= [value] (array.length if none).
  int lowerBound(int value) {
    var lo = 0, hi = array.length; // half-open [lo, hi)
    while (lo < hi) {
      final mid = lo + (hi - lo) ~/ 2;
      if (array[mid] < value) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  final first = lowerBound(target);
  if (first == array.length || array[first] != target) return [-1, -1];
  return [first, lowerBound(target + 1) - 1];
}
```

<!-- CODE:END -->

### Walkthrough

- `lowerBound` is the half-open template.
- `first == array.length || array[first] != target` means the target is absent.
- `lowerBound(target + 1) - 1` gives the last occurrence.

## Step 5: Dry run: lowerBound(45)

Array indices 0..12.

| lo | hi | mid | a[mid] | action |
|---|---|---|---|---|
| 0 | 13 | 6 | 45 | not < 45: hi = 6 |
| 0 | 6 | 3 | 33 | < 45: lo = 4 |
| 4 | 6 | 5 | 45 | hi = 5 |
| 4 | 5 | 4 | 45 | hi = 4 |
| 4 | 4 | | | return 4 |

`lowerBound(46)` returns 10 (the index of 61), so the last 45 is at 9. Answer `[4, 9]`.

## Complexity

- **Time: O(log n)**.
- **Space: O(1)**.

## Common mistakes

- Mixing inclusive and half-open conventions (infinite loops or skipped elements).
- `lowerBound(target + 1)` only works for integers; for doubles or strings, write an **upperBound** (first index with value `> x`) by changing `<` to `<=`.

## Library equivalents

C++ `lower_bound` / `upper_bound`, Python `bisect_left` / `bisect_right`, Dart `lowerBound` in `package:collection`. Java's `Arrays.binarySearch` returns **any** matching index, not the first.

## Follow-ups

1. **Find First and Last Position of Element in Sorted Array (LeetCode #34).**
2. **Count occurrences:** `upperBound - lowerBound`.
3. **Search Insert Position (#35):** exactly `lowerBound`.

## What to remember

Search for boundaries, not for "a match". One half-open lower-bound template covers first, last, count, and insertion position.
