# Median Of Two Sorted Arrays

**Difficulty:** Very Hard | **Category:** Searching | **Pattern:** Binary search on a partition

## The problem

Given two sorted arrays of integers (together non-empty), return the **median** of all their elements combined, in **O(log(min(n, m)))** time.

```
[1, 3, 4, 5] and [2, 3, 6, 7]  ->  3.5    (combined: 1 2 3 3 4 5 6 7)
[10, 20] and [1, 2, 3]          ->  3.0    (combined: 1 2 3 10 20)
```

## Step 1: Baselines

- Merge both arrays fully and take the middle: O(n + m).
- Merge only until the middle: still O(n + m).

The required logarithmic time means we cannot even look at most elements. We need to binary search for something.

## Step 2: Reframe: the median is a partition

The median splits the combined sorted list into a **left half** and a **right half** of equal size (the left gets one extra element when the total is odd). Suppose the left half takes the first `i` elements of array `a` and the first `j` elements of array `b`:

```
i + j = (n + m + 1) / 2        (integer division)
```

So choosing `i` determines `j`. The only unknown is `i`.

## Step 3: When is a partition correct?

Both arrays are sorted, so the left half is valid (every left element <= every right element) iff the four **boundary** values satisfy:

```
a[i - 1] <= b[j]     and     b[j - 1] <= a[i]
```

(Use -infinity for a missing element on the left and +infinity for a missing element on the right, for example when `i == 0`.)

If `a[i - 1] > b[j]`, we took **too many** from `a`: decrease `i`. If `b[j - 1] > a[i]`, we took **too few**: increase `i`. That monotonic decision is exactly what binary search needs.

## Step 4: Reading off the median

Once the partition is correct:

- odd total: the median is the largest left element, `max(a[i - 1], b[j - 1])`;
- even total: the average of that and the smallest right element, `min(a[i], b[j])`.

## Step 5: Search the smaller array

Binary search `i` over the **smaller** array (range `0..n`). Then `j = half - i` is always within `0..m`, so no index can go out of range. This is why the complexity is O(log(min(n, m))).

## Step 6: The code

<!-- CODE:START -->

Full source: [`median_of_two_sorted_arrays.dart`](median_of_two_sorted_arrays.dart) (run it with `dart run`).

```dart
// Median Of Two Sorted Arrays in O(log(min(n, m))).
// Binary search a partition of the smaller array so the left halves together hold
// (n + m + 1) / 2 elements and every left element <= every right element.

double medianOfTwoSortedArrays(List<int> arrayOne, List<int> arrayTwo) {
  final (a, b) = arrayOne.length <= arrayTwo.length ? (arrayOne, arrayTwo) : (arrayTwo, arrayOne);
  final n = a.length, m = b.length;
  final half = (n + m + 1) ~/ 2;
  var lo = 0, hi = n;
  while (lo <= hi) {
    final i = (lo + hi) ~/ 2; // elements taken from a
    final j = half - i; // elements taken from b
    final aLeft = i == 0 ? double.negativeInfinity : a[i - 1].toDouble();
    final aRight = i == n ? double.infinity : a[i].toDouble();
    final bLeft = j == 0 ? double.negativeInfinity : b[j - 1].toDouble();
    final bRight = j == m ? double.infinity : b[j].toDouble();
    if (aLeft <= bRight && bLeft <= aRight) {
      final leftMax = aLeft > bLeft ? aLeft : bLeft;
      if ((n + m).isOdd) return leftMax;
      final rightMin = aRight < bRight ? aRight : bRight;
      return (leftMax + rightMin) / 2;
    }
    if (aLeft > bRight) {
      hi = i - 1; // took too many from a
    } else {
      lo = i + 1; // took too few from a
    }
  }
  throw ArgumentError('inputs must be sorted');
}
```

<!-- CODE:END -->

### Walkthrough

- The record assignment makes `a` the shorter array.
- `half = (n + m + 1) ~/ 2` is the size of the left half.
- Each iteration computes the four boundary values (with infinities at the edges) and checks the partition.
- Adjust `hi` or `lo` depending on which boundary condition failed.

## Step 7: Dry runs

`a = [1, 3, 4, 5]`, `b = [2, 3, 6, 7]`, half = 4:

| lo | hi | i | j | aLeft | aRight | bLeft | bRight | valid? |
|---|---|---|---|---|---|---|---|---|
| 0 | 4 | 2 | 2 | 3 | 4 | 3 | 6 | yes: even total, (max(3,3) + min(4,6)) / 2 = **3.5** |

`a = [10, 20]`, `b = [1, 2, 3]`, half = 3:

| lo | hi | i | j | aLeft | aRight | bLeft | bRight | action |
|---|---|---|---|---|---|---|---|---|
| 0 | 2 | 1 | 2 | 10 | 20 | 2 | 3 | 10 > 3: too many from a, hi = 0 |
| 0 | 0 | 0 | 3 | -inf | 10 | 3 | +inf | valid: odd total, max(-inf, 3) = **3** |

## Complexity

- **Time: O(log(min(n, m)))**.
- **Space: O(1)**.

## Common mistakes

- Binary searching the larger array (j can go out of range).
- Forgetting the infinity sentinels at the edges.
- Mixing up which half gets the extra element for odd totals.

## Alternative: k-th smallest of two sorted arrays

Find the k-th smallest by comparing the `k/2`-th elements of both arrays and discarding `k/2` elements from the array with the smaller one. O(log(n + m)). Often easier to derive under pressure; the median is the k-th smallest for `k = (n + m + 1) / 2` (and the next one for even totals).

## What to remember

The median is a partition. Binary search how many elements the left half takes from the smaller array, and check the four boundary values.
