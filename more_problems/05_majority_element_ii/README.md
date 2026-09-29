# Majority Element II

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Extended Boyer-Moore voting | **Source:** LeetCode 229; Striver A2Z

## The problem

Return every value that appears **more than n/3 times** in an array of length n. Target: O(n) time, O(1) space.

```
[3, 2, 3]                  ->  [3]
[1, 2]                     ->  [1, 2]
[1, 1, 1, 3, 3, 2, 2, 2]   ->  [1, 2]      (n = 8, need > 2 occurrences)
[1, 2, 3, 4]               ->  []
```

"More than n/3" means `count > n ~/ 3` with integer division.

## Step 1: How many answers can there be?

At most **two**. If three values each appeared more than n/3 times, together they would exceed n elements. This bound is what makes O(1) space possible: we only ever need to track two candidates.

## Step 2: Brute force

Count with a hash map, return keys with count > n/3. O(n) time, **O(n) space**. Fine as a first answer. The follow-up is always "now O(1) space".

## Step 3: Recall the n/2 version (Boyer-Moore voting)

For "more than n/2" (AlgoExpert medium 13 Majority Element): keep one candidate and a counter. Same value: +1. Different value: -1. Counter at 0: adopt the new value. The intuition is **cancellation**: each decrement pairs one copy of the candidate with one different value and throws both away. A value with more than half the elements cannot be completely cancelled.

## Step 4: Generalize to n/3

Keep **two** candidates. When a value matches neither and both counters are positive, **decrement both**. That throws away **three distinct values** at once (one copy of each candidate plus the new value).

Why does a true answer survive? Each "throw away three distinct" step removes at most **one** copy of any particular value. The number of such steps is at most n/3 (each removes 3 elements). A value with more than n/3 copies therefore cannot be fully cancelled, so it must end as one of the two candidates.

But the converse is false: a surviving candidate might **not** be a majority (for `[1, 2, 3, 4]`: 1 and 2 are adopted, 3 cancels both, 4 is adopted, so the candidates end as 4 and 2, and neither appears more than once). So a **second pass verifies** each candidate's actual count.

### Order of the branches matters

```
if x == c1: n1++
elif x == c2: n2++
elif n1 == 0: adopt x as c1
elif n2 == 0: adopt x as c2
else: n1--, n2--
```

The "matches a candidate" checks must come **before** the "adopt" checks. Otherwise, with `n1 == 0` and `x == c2`, you would adopt `x` as `c1` too and end up with both candidates equal, losing a slot.

## Step 5: The code

<!-- CODE:START -->

Full source: [`majority_element_ii.dart`](majority_element_ii.dart) (run it with `dart run`).

```dart
// Majority Element II: all values appearing more than n/3 times.
// Extended Boyer-Moore voting with two candidates, then a verification pass.
// O(n) time, O(1) space.

List<int> majorityElementII(List<int> nums) {
  int? c1, c2;
  var n1 = 0, n2 = 0;
  for (final x in nums) {
    if (x == c1) {
      n1++;
    } else if (x == c2) {
      n2++;
    } else if (n1 == 0) {
      c1 = x;
      n1 = 1;
    } else if (n2 == 0) {
      c2 = x;
      n2 = 1;
    } else {
      // x differs from both candidates: cancel one copy of each of the three values.
      n1--;
      n2--;
    }
  }
  // Voting only guarantees that the true answers are among the candidates; verify them.
  final result = <int>[];
  for (final c in [c1, c2]) {
    if (c != null && nums.where((x) => x == c).length > nums.length ~/ 3) result.add(c);
  }
  return result..sort();
}
```

<!-- CODE:END -->

### Walkthrough

- `int? c1, c2` starts as null so no real value accidentally matches an uninitialized candidate (a common bug when initializing to 0 and the array contains 0).
- The voting loop is exactly the branch order above.
- The verification loop recounts each non-null candidate in O(n). The result is sorted only to make the output deterministic.

## Step 6: Dry run

`[1, 1, 1, 3, 3, 2, 2, 2]`:

| x | action | c1 (n1) | c2 (n2) |
|---|---|---|---|
| 1 | adopt c1 | 1 (1) | - (0) |
| 1 | match c1 | 1 (2) | - (0) |
| 1 | match c1 | 1 (3) | - (0) |
| 3 | adopt c2 | 1 (3) | 3 (1) |
| 3 | match c2 | 1 (3) | 3 (2) |
| 2 | cancel | 1 (2) | 3 (1) |
| 2 | cancel | 1 (1) | 3 (0) |
| 2 | adopt c2 (n2 == 0) | 1 (1) | 2 (1) |

Candidates 1 and 2. Verify: 1 appears 3 times, 2 appears 3 times, both > 8 ~/ 3 = 2. Answer `[1, 2]`.

## Complexity

- Time: **O(n)**: one voting pass plus two counting passes.
- Space: **O(1)**.

## Edge cases

| Input | Expected | Why |
|---|---|---|
| `[1]` | `[1]` | 1 > 0 |
| `[1, 2]` | `[1, 2]` | each 1 > 0 |
| `[1, 2, 3, 4]` | `[]` | candidates fail verification |
| `[2, 2, 1, 3]` | `[2]` | 2 > 1 |

## Common mistakes

- Skipping the verification pass.
- Checking "adopt" before "match" (both candidates become the same value).
- Initializing candidates to 0 instead of null.

## Follow-ups you should be ready for

1. **More than n/k.** Keep k - 1 candidates (Misra-Gries). O(nk) time, O(k) space.
2. **Streaming, one pass, approximate.** Misra-Gries gives frequency estimates with bounded error without the second pass.
3. **Why not sort?** Sorting gives O(n log n); values at positions n/3 and 2n/3 are the only possible answers. Mention it as the middle option.

## What to remember

"More than n/k" allows at most k - 1 answers. Cancel groups of k distinct values; true answers survive; always verify survivors.
