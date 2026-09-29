# Max Sum Increasing Subsequence

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** "Ending at i" DP with reconstruction (LIS family)

## The problem

Given a non-empty array of integers, find the **strictly increasing subsequence** (not necessarily contiguous) with the greatest sum. Return `[sum, subsequence]`.

```
[10, 70, 20, 30, 50, 11, 30]  ->  [110, [10, 20, 30, 50]]
```

Note that the longest increasing subsequence and the max-sum one can differ: `[10, 70]` sums to 80 with only 2 elements, while `[10, 20, 30, 50]` sums to 110.

## Step 1: Brute force

Try all 2^n subsequences, keep the increasing ones, take the best sum. Exponential.

## Step 2: Choose the subproblem

"Best increasing subsequence within the first i elements" does not combine easily: extending it requires knowing its **last value**. The standard fix (as in Kadane's algorithm) is to require the subsequence to **end at index i**:

`S[i]` = the greatest sum of an increasing subsequence that **ends with `a[i]`**.

## Step 3: Recurrence

A subsequence ending at `a[i]` is either just `[a[i]]`, or some increasing subsequence ending at an earlier `a[j] < a[i]`, extended by `a[i]`:

```
S[i] = a[i] + max(0, max over j < i with a[j] < a[i] of S[j])
answer = max over i of S[i]
```

(The `max(0, ...)` matters for negative numbers: never extend a negative-sum subsequence.)

## Step 4: Reconstruction

To return the subsequence itself, store `prev[i]` = the index `j` that gave the best extension (or none). Walk back from the index with the best sum, then reverse.

## Step 5: The code

<!-- CODE:START -->

Full source: [`max_sum_increasing_subsequence.dart`](max_sum_increasing_subsequence.dart) (run it with `dart run`).

```dart
// Max Sum Increasing Subsequence: strictly increasing subsequence with the largest sum.
// Returns [sum, subsequence]. DP over "ending at i" with predecessor links. O(n^2) time, O(n) space.

List<Object> maxSumIncreasingSubsequence(List<int> array) {
  final sums = [...array];
  final prev = List<int?>.filled(array.length, null);
  var bestIdx = 0;
  for (var i = 0; i < array.length; i++) {
    for (var j = 0; j < i; j++) {
      if (array[j] < array[i] && sums[j] + array[i] > sums[i]) {
        sums[i] = sums[j] + array[i];
        prev[i] = j;
      }
    }
    if (sums[i] > sums[bestIdx]) bestIdx = i;
  }
  final seq = <int>[];
  for (int? i = bestIdx; i != null; i = prev[i]) {
    seq.add(array[i]);
  }
  return [sums[bestIdx], seq.reversed.toList()];
}
```

<!-- CODE:END -->

### Walkthrough

- `sums = [...array]` initializes each `S[i]` to "just `a[i]`".
- The inner loop tries extending every earlier smaller element. It only updates when that is strictly better, which also implements the `max(0, ...)` rule automatically (extending a negative sum is never better than `a[i]` alone).
- `bestIdx` tracks the end of the best subsequence.
- The reconstruction loop follows `prev` pointers backward; `.reversed` puts the sequence in order.

## Step 6: Dry run

| i | a[i] | best j (value) | S[i] | prev |
|---|---|---|---|---|
| 0 | 10 | none | 10 | - |
| 1 | 70 | 0 (10) | 80 | 0 |
| 2 | 20 | 0 (10) | 30 | 0 |
| 3 | 30 | 2 (20) | 60 | 2 |
| 4 | 50 | 3 (30) | **110** | 3 |
| 5 | 11 | 0 (10) | 21 | 0 |
| 6 | 30 | 2 (20): 30 + 30 = 60 beats 21 + 30 = 51 | 60 | 2 |

Best: index 4, sum 110. Walk back: 4 -> 3 -> 2 -> 0: values `50, 30, 20, 10`, reversed `[10, 20, 30, 50]`.

## Complexity

- **Time: O(n^2)**.
- **Space: O(n)**.

A faster O(n log n) version exists: process elements in order and use a Fenwick tree (or segment tree) over the compressed values to query "maximum sum among values smaller than a[i]". Worth mentioning for large n.

## Common mistakes

- Returning `S[n-1]` instead of the maximum over all i.
- Using `<=` (the subsequence must be strictly increasing).
- Forgetting to reverse the reconstructed sequence.

## Follow-ups

1. **Longest Increasing Subsequence (very hard 14):** the length version, with an O(n log n) patience-sorting solution.
2. **Russian Doll Envelopes (LeetCode #354)**, **Disk Stacking (hard 20):** the same DP over a partial order.

## What to remember

For subsequence problems, define the DP as "best answer ending exactly at i", extend from every compatible earlier j, and keep predecessor pointers to reconstruct.
