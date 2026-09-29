# Split Array Largest Sum (Book Allocation)

**Difficulty:** Hard | **Category:** Binary search | **Pattern:** Binary search on the answer + greedy check | **Source:** LeetCode 410; Striver A2Z (as Book Allocation / Painter's Partition)

## The problem

Split an array of non-negative integers into `k` non-empty **contiguous** parts so that the **largest part sum is as small as possible**. Return that minimized largest sum.

```
[7, 2, 5, 10, 8], k = 2   ->  18    ([7, 2, 5] | [10, 8])
[1, 2, 3, 4, 5], k = 2    ->  9     ([1, 2, 3] | [4, 5])
```

Striver's **Book Allocation**: pages of books in order, `k` students, each student gets a contiguous run of books, minimize the maximum pages any student reads. Same problem. **Painter's Partition** is the same problem with boards and painters.

## Step 1: Brute force

Try every placement of `k - 1` cut points among `n - 1` gaps: `C(n - 1, k - 1)` splits, each O(n) to evaluate. Exponential.

A DP also works: `dp[i][j]` = best answer for the first `i` elements in `j` parts, O(n^2 * k). Worth mentioning; the binary search is better.

## Step 2: Flip the question

Instead of "what is the best cap?", ask **"given a cap C, can we split into at most k parts with every part sum <= C?"**

That question has a simple greedy answer: walk left to right, keep adding elements to the current part, and start a new part only when adding the next element would exceed C. This uses the **fewest parts** possible for that cap.

**Why is greedy optimal for the check?** Making a part end earlier never helps: the next part would just have to hold more. Formally, for any valid split, the greedy's i-th part ends at or after that split's i-th part (induction), so greedy never needs more parts.

**Why "at most k" and not "exactly k"?** If we can do it with fewer than k parts, we can split any part further (every part has at least one element and values are non-negative, so splitting never increases a part sum), as long as there are at least k elements.

## Step 3: Monotonicity

If cap C works, any bigger cap also works. So feasibility is false...false true...true over C. Binary search for the first true, between:

- `lo = max(nums)`: every element must fit in some part.
- `hi = sum(nums)`: one part holds everything.

## Step 4: The code

<!-- CODE:START -->

Full source: [`split_array_largest_sum.dart`](split_array_largest_sum.dart) (run it with `dart run`).

```dart
// Split Array Largest Sum (also: Book Allocation, Painter's Partition).
// Split nums into k non-empty contiguous parts minimizing the largest part sum.
// Binary search on the answer with a greedy feasibility check. O(n log S) time, O(1) space.

int splitArray(List<int> nums, int k) {
  // The answer lies between the largest single element and the total sum.
  var lo = nums.reduce((a, b) => a > b ? a : b);
  var hi = nums.reduce((a, b) => a + b);
  while (lo < hi) {
    final mid = lo + (hi - lo) ~/ 2;
    if (_partsNeeded(nums, mid) <= k) {
      hi = mid; // a cap of mid is achievable with at most k parts
    } else {
      lo = mid + 1;
    }
  }
  return lo;
}

/// Greedy: fill each part as much as possible without exceeding [cap].
/// Returns the minimum number of parts needed so that no part exceeds [cap].
int _partsNeeded(List<int> nums, int cap) {
  var parts = 1, current = 0;
  for (final x in nums) {
    if (current + x > cap) {
      parts++;
      current = x;
    } else {
      current += x;
    }
  }
  return parts;
}
```

<!-- CODE:END -->

### Walkthrough

- `_partsNeeded` is the greedy: `current + x > cap` starts a new part with `x`. Because `cap >= max(nums)`, a single element always fits.
- The binary search is the "first true" template (round mid down, `hi = mid` on success).

## Step 5: Dry run

`[7, 2, 5, 10, 8]`, k = 2, search range [10, 32]:

| lo | hi | mid | greedy parts | parts <= 2? | action |
|---|---|---|---|---|---|
| 10 | 32 | 21 | [7,2,5] [10,8] = 2 | yes | hi = 21 |
| 10 | 21 | 15 | [7,2,5] [10] [8] = 3 | no | lo = 16 |
| 16 | 21 | 18 | [7,2,5] [10,8] = 2 | yes | hi = 18 |
| 16 | 18 | 17 | [7,2,5] [10] [8] = 3 | no | lo = 18 |
| 18 | 18 | | | | return **18** |

## Complexity

- Time: **O(n log S)**, S = sum of the array.
- Space: **O(1)**.

## Edge cases

- `k == n`: each element alone, answer = max.
- `k == 1`: answer = sum.
- Zeros in the array: fine, they never force a new part.
- Book Allocation variant: if `k > n` (more students than books), return -1; the greedy cannot create more parts than elements.

## Common mistakes

- `lo = 0` or `lo = min(nums)`: the greedy then meets an element bigger than the cap and produces nonsense (an element alone in a part still exceeds the cap).
- Testing `parts == k` instead of `parts <= k`.
- Trying sliding windows or sorting: the parts must stay contiguous and in order.

## Follow-ups you should be ready for

1. **Return the split itself.** Run the greedy once more with the final cap and record the boundaries.
2. **Capacity to Ship Packages Within D Days (LeetCode 1011).** Identical.
3. **Minimize the maximum distance to gas station (Striver), Kth missing positive, median of row-wise sorted matrix.** Other "binary search on the answer" problems in the same sheet section.

## What to remember

"Minimize the maximum" (or "maximize the minimum") is a strong hint for binary search on the answer. Turn the optimization into a yes/no question that a greedy can answer.
