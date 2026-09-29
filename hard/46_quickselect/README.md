# Quickselect

**Difficulty:** Hard | **Category:** Searching | **Pattern:** Partition-based selection

## The problem

Given an array of distinct integers and a positive integer k, return the **k-th smallest** value (k = 1 is the minimum), without fully sorting. Aim for O(n) average time.

```
[8, 5, 2, 9, 7, 6, 3], k = 3  ->  5
```

## Step 1: Baselines

- Sort and index: O(n log n).
- Max-heap of size k: O(n log k).

Both are fine answers. Quickselect beats them on average.

## Step 2: Partitioning

Quicksort's **partition** step picks a pivot and rearranges the range so that smaller values are on its left and larger values on its right. The pivot ends up at its **final sorted position** `p`.

If `p == k - 1`, the pivot is the answer. If `p < k - 1`, the answer is on the right; otherwise on the left. **Unlike quicksort, only recurse into one side.**

## Step 3: Why O(n) on average

With a reasonably good pivot, each round shrinks the range by a constant fraction. The work is `n + n/2 + n/4 + ... <= 2n`: **O(n)**.

With consistently bad pivots (always the minimum or maximum), each round removes only one element: `n + (n-1) + ... = O(n^2)`. A fixed pivot choice (first or last element) triggers this on already sorted input. A **random pivot** makes the bad case astronomically unlikely.

For a guaranteed O(n), the **median of medians** pivot rule exists (large constant factor; mention it, do not code it).

## Step 4: Lomuto partition (used here)

```
partition(lo, hi, pivotIdx):
    swap pivot to the end (hi)
    store = lo
    for i in lo..hi-1:
        if a[i] < pivot: swap a[i], a[store]; store++
    swap a[store], a[hi]      # pivot into its final position
    return store
```

Invariant: `a[lo..store)` are smaller than the pivot; `a[store..i)` are not.

## Step 5: The code

<!-- CODE:START -->

Full source: [`quickselect.dart`](quickselect.dart) (run it with `dart run`).

```dart
// Quickselect: k-th smallest (1-based) in O(n) average time, O(n^2) worst, O(1) extra space.
// Random pivot + Lomuto partition, iterating on the side that contains index k - 1.

import 'dart:math';

int quickselect(List<int> array, int k) {
  final a = [...array];
  final target = k - 1;
  final rng = Random(42);
  var lo = 0, hi = a.length - 1;
  while (true) {
    final p = _partition(a, lo, hi, lo + rng.nextInt(hi - lo + 1));
    if (p == target) return a[p];
    if (p < target) {
      lo = p + 1;
    } else {
      hi = p - 1;
    }
  }
}

/// Moves a[pivotIdx] to its sorted position within [lo, hi] and returns that position.
int _partition(List<int> a, int lo, int hi, int pivotIdx) {
  _swap(a, pivotIdx, hi);
  final pivot = a[hi];
  var store = lo;
  for (var i = lo; i < hi; i++) {
    if (a[i] < pivot) _swap(a, i, store++);
  }
  _swap(a, store, hi);
  return store;
}

void _swap(List<int> a, int i, int j) {
  final t = a[i];
  a[i] = a[j];
  a[j] = t;
}
```

<!-- CODE:END -->

### Walkthrough

- `final a = [...array];` copies so the caller's array is not scrambled (costs O(n) space; mention that in-place is possible).
- `Random(42)` is seeded so test runs are reproducible; in production use an unseeded `Random()`.
- The loop narrows `[lo, hi]` to the side that contains index `k - 1`, iteratively (no recursion, O(1) extra space).

## Step 6: Dry run (k = 3, target index 2, pivot choices depend on the random generator)

One possible run: pick pivot 6. After partitioning, `[5, 2, 3]` are left of 6 and `[8, 9, 7]` right, and 6 is at index 3. Index 2 < 3: search the left part `[5, 2, 3]`. Pick pivot 3: `[2]` left, 3 at index 1, `[5]` right. Index 2 > 1: search right: a single element, 5, at index 2. Answer: 5.

## Complexity

| Case | Time |
|---|---|
| Average (random pivot) | O(n) |
| Worst | O(n^2) |
| Median-of-medians pivot | O(n) guaranteed |

Space: O(1) extra for the algorithm (O(n) here for the defensive copy).

## Common mistakes

- Recursing into both sides (that is quicksort, O(n log n)).
- Off-by-one between "k-th" (1-based) and index `k - 1`.
- Fixed pivots on sorted input.

## Follow-ups

1. **Kth Largest Element in an Array (LeetCode #215):** the k-th largest is the `(n - k + 1)`-th smallest.
2. **Top k elements:** after quickselect, the k smallest are in the first k positions (unsorted).
3. **Many duplicates:** use 3-way partitioning (Three Number Sort, medium 58).

## What to remember

Partition around a random pivot, then continue on the one side that contains the target index: O(n) on average.
