# Three Number Sum

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Sort + two pointers

## The problem

Given an array of **distinct** integers and a target sum, return **all** triplets that add up to the target. Each triplet must be in ascending order, and the list of triplets must be sorted ascending (by first number, then second).

```
array = [12, 3, 1, 2, -6, 5, -8, 6], target = 0
->  [[-8, 2, 6], [-8, 3, 5], [-6, 1, 5]]
```

### Clarifying questions

- Distinct values? (Yes here. LeetCode #15 allows duplicates, which adds deduplication logic; see Follow-ups.)
- All triplets or just one? (All.)
- May I sort / mutate the input? (Sorting is expected; this code sorts a copy.)

## Step 1: Work an example by hand

Sort first: `[-8, -6, 1, 2, 3, 5, 6, 12]`. Fix the smallest number, `-8`. Now you need two **other** numbers (to its right) that sum to `0 - (-8) = 8`. That is **Two Number Sum** on the rest of the array, with target 8.

In the sorted remainder `[-6, 1, 2, 3, 5, 6, 12]`, two pointers find `2 + 6` and `3 + 5`. Then fix `-6` and look for pairs summing to 6 in `[1, 2, 3, 5, 6, 12]`: `1 + 5`. And so on.

**Reduce the new problem to one you already know.** That is the key move of this problem.

## Step 2: Brute force

Three nested loops over `i < j < k`, check each sum, collect matches, then sort the output. **O(n^3)** time.

## Step 3: Optimize

**Bottleneck:** for fixed `i` and `j`, the innermost loop searches for the value `target - a[i] - a[j]`. We could replace it with a hash set lookup (O(n^2) time, O(n) space). That works, but producing the triplets in the required sorted order and avoiding duplicates gets fiddly.

**Better: sort, then two pointers for each `i`.**

1. Sort the array: O(n log n).
2. For each index `i` (the smallest element of the triplet):
   - `lo = i + 1`, `hi = n - 1`.
   - While `lo < hi`: compute `sum = a[i] + a[lo] + a[hi]`.
     - `sum == target`: record, then move **both** pointers.
     - `sum < target`: need a bigger sum: `lo++`.
     - `sum > target`: need a smaller sum: `hi--`.

**Why move both pointers after a match?** With distinct values, keeping `lo` and only moving `hi` makes `a[hi]` smaller, so the sum drops below the target; keeping `hi` and moving `lo` makes it bigger. Neither can match again. Moving both is safe and saves a step.

**Why is the output automatically sorted?** `i` increases, and for a fixed `i`, `lo` only increases. Every triplet is `[a[i], a[lo], a[hi]]` with `a[i] < a[lo] < a[hi]`, produced in increasing order of `(a[i], a[lo])`.

**Why is it correct to discard?** Same argument as Two Number Sum: if the sum is too small, `a[lo]` combined with the largest remaining `a[hi]` is still too small, so `a[lo]` cannot be in any triplet with this `a[i]`.

## Step 4: The code

<!-- CODE:START -->

Full source: [`three_number_sum.dart`](three_number_sum.dart) (run it with `dart run`).

```dart
// Three Number Sum: all triplets (ascending, distinct values) summing to target.
// Sort, fix one element, two-pointer the rest. O(n^2) time, O(n) space for output.

List<List<int>> threeNumberSum(List<int> array, int targetSum) {
  final a = [...array]..sort();
  final triplets = <List<int>>[];
  for (var i = 0; i < a.length - 2; i++) {
    var lo = i + 1, hi = a.length - 1;
    while (lo < hi) {
      final sum = a[i] + a[lo] + a[hi];
      if (sum == targetSum) {
        triplets.add([a[i], a[lo], a[hi]]);
        lo++;
        hi--;
      } else if (sum < targetSum) {
        lo++;
      } else {
        hi--;
      }
    }
  }
  return triplets;
}
```

<!-- CODE:END -->

### Walkthrough

- `final a = [...array]..sort();` sorts a copy.
- `for (var i = 0; i < a.length - 2; i++)` stops two before the end because we need two more numbers after `i`.
- `var lo = i + 1, hi = a.length - 1;` searches only to the right of `i`, so each triplet is found once, with `i` as its smallest element.
- The three branches implement Step 3 exactly.

## Step 5: Dry run

Sorted: `[-8, -6, 1, 2, 3, 5, 6, 12]`, target 0.

`i = 0` (value -8):

| lo (val) | hi (val) | sum | action |
|---|---|---|---|
| 1 (-6) | 7 (12) | -2 | lo++ |
| 2 (1) | 7 (12) | 5 | hi-- |
| 2 (1) | 6 (6) | -1 | lo++ |
| 3 (2) | 6 (6) | 0 | record [-8, 2, 6]; lo++, hi-- |
| 4 (3) | 5 (5) | 0 | record [-8, 3, 5]; lo++, hi-- |
| 5 | 4 | | stop |

`i = 1` (value -6):

| lo (val) | hi (val) | sum | action |
|---|---|---|---|
| 2 (1) | 7 (12) | 7 | hi-- |
| 2 (1) | 6 (6) | 1 | hi-- |
| 2 (1) | 5 (5) | 0 | record [-6, 1, 5]; lo++, hi-- |
| 3 (2) | 4 (3) | -1 | lo++, stop |

For `i >= 2` every value is positive, so every sum is positive and `hi` just walks down. Final result: `[[-8, 2, 6], [-8, 3, 5], [-6, 1, 5]]`.

## Complexity

- **Time: O(n^2)**. Sorting is O(n log n). Then n iterations of `i`, each with a two-pointer scan of O(n): O(n^2) dominates.
- **Space: O(n)** for the sorted copy (O(1) extra if sorting in place), plus the output.

Could it be faster? For the general 3-sum problem, no algorithm significantly better than O(n^2) is known; it is a famous conjecture in complexity theory ("3SUM-hardness"). Mentioning this is a nice depth signal.

## Edge cases

- Fewer than three elements: the loop does not run, returns `[]`.
- No triplet: `[]`.

## Common mistakes

- Starting `lo` at 0 or at `i` instead of `i + 1` (reuses elements, produces duplicates).
- Stopping after the first match for a given `i` (there can be several, as with `-8`).
- Forgetting to sort before using two pointers.

## Follow-ups

1. **Duplicates allowed (LeetCode #15):** skip `i` if `a[i] == a[i - 1]`; after a match, advance `lo` past equal values and `hi` past equal values.
2. **3Sum Closest (#16):** track the sum with minimum `|sum - target|` instead of exact matches.
3. **3Sum Smaller (#259):** when `sum < target`, all pairs `(lo, lo+1..hi)` work: add `hi - lo` and `lo++`.
4. **k-Sum:** recursively fix one element until two remain, then two pointers: O(n^(k-1)). See Four Number Sum (hard 01) for an O(n^2) average approach for k = 4.

## What to remember

Reduce k-sum to (k-1)-sum by fixing the smallest element, down to two-sum solved with two pointers on a sorted array.
