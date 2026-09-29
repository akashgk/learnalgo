# Smallest Difference

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Sort both + two pointers

## The problem

Given two non-empty arrays of integers, find the pair of numbers (one from each array) whose absolute difference is closest to zero. Return `[numberFromFirst, numberFromSecond]`. Assume only one best pair.

```
arrayOne = [-1, 5, 10, 20, 28, 3]
arrayTwo = [26, 134, 135, 15, 17]
->  [28, 26]   (difference 2)
```

## Step 1: Work an example by hand

Sort both: `A = [-1, 3, 5, 10, 20, 28]`, `B = [15, 17, 26, 134, 135]`.

Imagine both on one number line. The closest pair must be two numbers that are **neighbors** when the arrays are merged. Walking both arrays together (like merging them) lets you look at every such neighboring pair once.

Stand at `-1` (A) and `15` (B). The difference is 16. To shrink the gap, which pointer should move? Moving in B makes the B value bigger (the gap grows). Only moving in A, toward bigger values, can shrink it. So advance A.

## Step 2: Brute force

Compare every pair: O(n * m).

## Step 3: Optimize

Sort both arrays, pointers `i` in A and `j` in B, both at 0. Repeat until one array runs out:

1. Compute `|A[i] - B[j]|` and keep it if it is the best so far.
2. If `A[i] == B[j]`: difference 0, cannot be beaten, return.
3. If `A[i] < B[j]`: advance `i` (the smaller value must increase).
4. Else: advance `j`.

**Why is discarding safe?** Suppose `A[i] < B[j]`. For any later `B[k]` (k > j), `B[k] >= B[j]`, so `|A[i] - B[k]| >= |A[i] - B[j]|`. `A[i]`'s best remaining partner is `B[j]`, which we just checked. `A[i]` is finished; discard it. Symmetric when `A[i] > B[j]`.

## Step 4: The code

<!-- CODE:START -->

Full source: [`smallest_difference.dart`](smallest_difference.dart) (run it with `dart run`).

```dart
// Smallest Difference: pair (one from each array) with the smallest absolute difference.
// Sort both, then advance the pointer at the smaller value. O(n log n + m log m) time.

List<int> smallestDifference(List<int> arrayOne, List<int> arrayTwo) {
  final a = [...arrayOne]..sort();
  final b = [...arrayTwo]..sort();
  var i = 0, j = 0;
  var best = <int>[];
  var bestDiff = double.maxFinite.toInt();
  while (i < a.length && j < b.length) {
    final x = a[i], y = b[j];
    final diff = (x - y).abs();
    if (diff < bestDiff) {
      bestDiff = diff;
      best = [x, y];
    }
    if (x == y) return best; // cannot beat 0
    if (x < y) {
      i++; // only increasing x can close the gap
    } else {
      j++;
    }
  }
  return best;
}
```

<!-- CODE:END -->

### Walkthrough

- Both arrays are copied and sorted.
- `var bestDiff = double.maxFinite.toInt();` is a safe "infinity" (it becomes the maximum 64-bit integer on native Dart).
- The loop runs while both pointers are in range.
- `if (x == y) return best;` exits early on a perfect match.
- `if (x < y) i++; else j++;` moves the pointer at the smaller value.

## Step 5: Dry run

`A = [-1, 3, 5, 10, 20, 28]`, `B = [15, 17, 26, 134, 135]`:

| i (A[i]) | j (B[j]) | diff | best | move |
|---|---|---|---|---|
| 0 (-1) | 0 (15) | 16 | [-1, 15] | i++ |
| 1 (3) | 0 (15) | 12 | [3, 15] | i++ |
| 2 (5) | 0 (15) | 10 | [5, 15] | i++ |
| 3 (10) | 0 (15) | 5 | [10, 15] | i++ |
| 4 (20) | 0 (15) | 5 | unchanged (not smaller) | j++ |
| 4 (20) | 1 (17) | 3 | [20, 17] | j++ |
| 4 (20) | 2 (26) | 6 | | i++ |
| 5 (28) | 2 (26) | 2 | [28, 26] | j++ |
| 5 (28) | 3 (134) | 106 | | i++, A exhausted |

Return `[28, 26]`.

## Complexity

- **Time: O(n log n + m log m)** for sorting; the scan is O(n + m).
- **Space: O(1)** extra if sorting in place (O(n + m) here because of copies).

## Alternative

Sort only the **smaller** array and binary search it for each element of the larger one: O((n + m) log(min(n, m))). Better when one array is tiny.

## Common mistakes

- Moving both pointers, or moving the pointer at the larger value.
- Initializing the best difference with a small number or with 0.
- Returning the pair in the wrong order (first array's number first).

## Follow-ups

1. **k closest pairs:** use a min-heap of candidate pairs (LeetCode #373 pattern).
2. **Three arrays, minimize max - min of a triple:** three pointers, always advance the pointer at the minimum.
3. **Closest to a target sum across two arrays:** sort one ascending and one descending, or reuse the two-pointer idea from Sweet And Savory (medium 14).

## What to remember

With two sorted lists, a merge-style walk visits all "neighboring" pairs. Always advance the pointer at the smaller value when you want to close a gap.
