# Subarray Sum Equals K

**Difficulty:** Medium | **Category:** Arrays / Hashing | **Pattern:** Prefix sum + hash map of counts | **Source:** LeetCode 560; Striver A2Z

## The problem

Count the contiguous, non-empty subarrays whose sum equals `k`. Values can be **negative**.

```
[1, 1, 1], k = 2                   ->  2
[1, 2, 3], k = 3                   ->  2      ([1, 2] and [3])
[3, 4, 7, 2, -3, 1, 4, 2], k = 7   ->  4
```

### Clarifying questions to ask

| Question | Why it matters |
|---|---|
| Can values be negative or zero? | **The key question.** If all values are positive, a sliding window works in O(1) space. With negatives it does not. |
| Count, or return the subarrays? | Returning all of them can be O(n^2) output. |
| Overflow? | Prefix sums can exceed 32 bits in other languages; Dart ints are 64-bit. |

## Step 1: Why the obvious sliding window fails

For positive numbers: grow the window while the sum is below k, shrink it while above. That relies on "adding an element increases the sum". With `-3` in the array, adding an element can **decrease** the sum, so when the window is too big you do not know whether to shrink or grow. The monotonicity is gone, so we need a different tool.

## Step 2: Brute force

Fix the start `i`, extend the end `j`, keep a running sum:

```dart
for (i...) { var s = 0; for (j = i...) { s += a[j]; if (s == k) count++; } }
```

O(n^2) time, O(1) space. (Recomputing each sum from scratch would be O(n^3); the running sum is the first optimization.)

## Step 3: Optimize with prefix sums

Define `P[j]` = sum of the first `j` elements (`P[0] = 0`). The sum of the subarray from index `i` to `j - 1` is `P[j] - P[i]`. So:

```
sum(i..j-1) == k   <=>   P[i] == P[j] - k
```

For each end position `j`, the number of subarrays ending there with sum k equals **the number of earlier prefix sums equal to `P[j] - k`**. This is the Two Number Sum idea again: we are searching for a complement among values seen so far. A hash map from prefix sum to **how many times it has occurred** answers that in O(1).

**Why a count, not a set?** With zeros or negatives, the same prefix sum can occur several times, and each occurrence is a different start index, so a different subarray. `[1, -1, 0]` with k = 0 has three answers for exactly this reason.

**Why seed the map with `{0: 1}`?** It represents the empty prefix `P[0] = 0`. Without it, subarrays that start at index 0 would never be counted.

## Step 4: The code

<!-- CODE:START -->

Full source: [`subarray_sum_equals_k.dart`](subarray_sum_equals_k.dart) (run it with `dart run`).

```dart
// Subarray Sum Equals K: count contiguous subarrays whose sum is exactly k.
// Prefix sums + hash map of "how many times has each prefix sum occurred". O(n) time, O(n) space.
// Works with negative numbers (a sliding window does not).

int subarraySum(List<int> nums, int k) {
  final seen = <int, int>{0: 1}; // the empty prefix, so subarrays starting at index 0 count
  var prefix = 0, count = 0;
  for (final x in nums) {
    prefix += x;
    // A subarray (i, j] sums to k exactly when prefix[i] == prefix[j] - k.
    count += seen[prefix - k] ?? 0;
    seen[prefix] = (seen[prefix] ?? 0) + 1;
  }
  return count;
}
```

<!-- CODE:END -->

### Walkthrough

- `seen = {0: 1}`: one empty prefix.
- `prefix += x`: running prefix sum `P[j]`.
- `count += seen[prefix - k] ?? 0`: all earlier start points that make a subarray summing to k.
- `seen[prefix] += 1` **after** the lookup, so a subarray is never empty. (With k = 0, looking up after inserting would count the empty subarray.)

## Step 5: Dry run

`[3, 4, 7, 2, -3, 1, 4, 2]`, k = 7:

| x | prefix | prefix - k | seen[prefix - k] | count | seen after |
|---|---|---|---|---|---|
| 3 | 3 | -4 | 0 | 0 | {0:1, 3:1} |
| 4 | 7 | 0 | 1 | 1 | + 7:1 |
| 7 | 14 | 7 | 1 | 2 | + 14:1 |
| 2 | 16 | 9 | 0 | 2 | + 16:1 |
| -3 | 13 | 6 | 0 | 2 | + 13:1 |
| 1 | 14 | 7 | 1 | 3 | 14:2 |
| 4 | 18 | 11 | 0 | 3 | + 18:1 |
| 2 | 20 | 13 | 1 | **4** | + 20:1 |

The four subarrays: `[3, 4]`, `[7]`, `[7, 2, -3, 1]`, `[1, 4, 2]`.

## Complexity

- Time: **O(n)** expected (hash map operations).
- Space: **O(n)** for the map.

## Edge cases

| Input | Expected | Note |
|---|---|---|
| `[]` | 0 | |
| `[1, -1, 0]`, k = 0 | 3 | repeated prefix sum 0 must be counted with multiplicity |
| `[0, 0]`, k = 0 | 3 | `[0]`, `[0]`, `[0, 0]` |

## Common mistakes

- Using a sliding window (wrong with negatives).
- Using a set instead of counts.
- Forgetting the `{0: 1}` seed.
- Inserting before looking up.

## Follow-ups you should be ready for

1. **Longest subarray with sum k (AlgoExpert hard 06 is the positive-only version).** Store the **first** index of each prefix sum instead of a count.
2. **Subarray sum divisible by k (LeetCode 974).** Key the map by `prefix mod k` (normalize negatives).
3. **Count subarrays with XOR equal to k (Striver).** Identical, with `^` instead of `+` and `prefix ^ k` as the complement.
4. **Binary array, O(1) space.** more_problems 17 uses the atMost trick.
5. **2-D version: submatrices summing to target (LeetCode 1074).** Fix a pair of rows, compress columns, and run this algorithm.

## What to remember

"Subarray sum equals k" = "two prefix sums differ by k". Walk once, look up the complement among earlier prefix sums in a map of counts, seeded with the empty prefix.
