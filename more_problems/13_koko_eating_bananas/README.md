# Koko Eating Bananas

**Difficulty:** Medium | **Category:** Binary search | **Pattern:** Binary search on the answer | **Source:** LeetCode 875; Striver A2Z, NeetCode 150

## The problem

There are piles of bananas. Koko picks an integer speed `k`. Each hour she chooses one pile and eats `k` bananas from it (if the pile has fewer, she finishes it and waits for the rest of the hour). Find the **minimum** `k` that lets her finish all piles within `h` hours. It is guaranteed that `h >= number of piles`.

```
piles = [3, 6, 7, 11], h = 8          ->  4
piles = [30, 11, 23, 4, 20], h = 5    ->  30
piles = [30, 11, 23, 4, 20], h = 6    ->  23
```

## Step 1: Work an example by hand

At speed `k`, a pile of `p` takes `ceil(p / k)` hours (piles cannot be shared within an hour). Total hours is the sum. For `[3, 6, 7, 11]`:

| k | hours per pile | total |
|---|---|---|
| 1 | 3, 6, 7, 11 | 27 |
| 3 | 1, 2, 3, 4 | 10 |
| 4 | 1, 2, 2, 3 | **8** |
| 5 | 1, 2, 2, 3 | 8 |
| 11 | 1, 1, 1, 1 | 4 |

The smallest k with total <= 8 is 4.

## Step 2: Brute force

Try `k = 1, 2, 3, ...` until the total fits. The answer is at most `max(piles)` (at that speed each pile takes one hour, and `h >= piles.length`). O(n * max(piles)): with piles up to 10^9, far too slow.

## Step 3: Notice the monotonicity

**Eating faster never takes longer.** `hours(k)` is non-increasing in `k`. So the predicate "k is fast enough" is:

```
k:       1     2     3     4     5   ...   11
ok?    false false false true  true  ...  true
```

We want the **first true**. That is binary search, not over an array, but over the **range of possible answers** `[1, max(piles)]`. Each probe costs one O(n) feasibility check.

This pattern, **binary search on the answer**, applies whenever:

1. You can check whether a candidate answer is feasible, and
2. Feasibility is monotone in the candidate.

Split Array Largest Sum (more_problems 14) and Aggressive Cows (15) are the same template.

## Step 4: The template for "first true"

```
lo = smallest possible, hi = largest possible (known feasible)
while lo < hi:
  mid = lo + (hi - lo) ~/ 2      // round down
  if feasible(mid): hi = mid      // mid might be the answer
  else:             lo = mid + 1  // mid is not
return lo
```

Rounding down matters: with `lo + 1 == hi`, `mid == lo`, and either branch shrinks the range. (For "last true", round up; see Aggressive Cows.)

## Step 5: The code

<!-- CODE:START -->

Full source: [`koko_eating_bananas.dart`](koko_eating_bananas.dart) (run it with `dart run`).

```dart
// Koko Eating Bananas: smallest integer eating speed k so that all piles are finished within h hours.
// Each hour Koko eats up to k bananas from one pile. Binary search on the answer.
// O(n log M) time where M is the largest pile, O(1) space.

int minEatingSpeed(List<int> piles, int h) {
  var lo = 1, hi = piles.reduce((a, b) => a > b ? a : b);
  // hoursAt(k) is non-increasing in k, so "finishes in time" is monotone: false...false true...true.
  while (lo < hi) {
    final mid = lo + (hi - lo) ~/ 2;
    if (_hoursAt(piles, mid) <= h) {
      hi = mid; // mid works; the answer is mid or smaller
    } else {
      lo = mid + 1; // mid is too slow
    }
  }
  return lo;
}

int _hoursAt(List<int> piles, int k) {
  var hours = 0;
  for (final p in piles) {
    hours += (p + k - 1) ~/ k; // ceil(p / k) without floating point
  }
  return hours;
}
```

<!-- CODE:END -->

### Walkthrough

- `hi = max(piles)` is always feasible, so the answer is in `[1, hi]`.
- `_hoursAt` computes `ceil(p / k)` as `(p + k - 1) ~/ k`, avoiding floating point.
- `lo` ends at the smallest feasible speed.

## Step 6: Dry run

`[3, 6, 7, 11]`, h = 8:

| lo | hi | mid | hours(mid) | feasible? | action |
|---|---|---|---|---|---|
| 1 | 11 | 6 | 1 + 1 + 2 + 2 = 6 | yes | hi = 6 |
| 1 | 6 | 3 | 1 + 2 + 3 + 4 = 10 | no | lo = 4 |
| 4 | 6 | 5 | 1 + 2 + 2 + 3 = 8 | yes | hi = 5 |
| 4 | 5 | 4 | 1 + 2 + 2 + 3 = 8 | yes | hi = 4 |
| 4 | 4 | | | | return **4** |

## Complexity

- Time: **O(n log M)**, M = largest pile. log2(10^9) is about 30 probes.
- Space: **O(1)**.

## Edge cases

- `h == piles.length`: the answer is `max(piles)`.
- Huge `h`: the answer is 1.
- Large values: `hours` can be as big as the total number of bananas; Dart ints are 64-bit, so no overflow.

## Common mistakes

- Using `p ~/ k` instead of the ceiling.
- Setting `lo = 0`: speed 0 is meaningless, and a probe at `mid = 0` divides by zero (for example when every pile has 1 banana, so `hi = 1`).
- Searching over indices of `piles` instead of over speeds.

## Follow-ups you should be ready for

1. **Minimum days to make m bouquets (LeetCode 1482), capacity to ship packages in D days (LeetCode 1011), smallest divisor given a threshold (LeetCode 1283).** All the same template; Striver's A2Z binary search section is mostly this pattern.
2. **Can you tighten `lo`?** `lo = ceil(total / h)` is a valid lower bound and saves a few probes.

## What to remember

When the question is "the minimum X such that something works", and "works" is monotone in X, binary search over X with a feasibility check.
