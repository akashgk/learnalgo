# Combination Sum II

**Difficulty:** Medium | **Category:** Backtracking | **Pattern:** Start index + no reuse + skip duplicates at the same depth | **Source:** LeetCode 40; NeetCode 150

## The problem

Candidates may contain **duplicates**, and each element may be used **at most once**. Return all **unique** combinations that sum to `target`.

```
candidates = [10, 1, 2, 7, 6, 1, 5], target = 8
->  [[1, 1, 6], [1, 2, 5], [1, 7], [2, 6]]
```

`[1, 7]` must appear once, even though there are two 1s that could each pair with 7.

## Step 1: Combine two known tricks

This problem is two earlier problems glued together:

| From | Rule | Why |
|---|---|---|
| more_problems 24 Combination Sum | backtrack with a start index; stop when the candidate exceeds the remainder (sorted input) | combinations, not permutations; pruning |
| more_problems 25 Subsets II | sort, then skip `c[i]` when `i > start && c[i] == c[i - 1]` | no duplicate combinations |

The one change from Combination Sum: recurse with `i + 1` instead of `i`, because each element can be used only once.

## Step 2: Why the skip rule is exactly right

After sorting, `[1, 1, 2, 5, 6, 7, 10]`. At the root (depth 0), choosing the first 1 or the second 1 as the first element leads to identical sets of combinations. So at any depth, among equal values, only the **first** one available at that depth is tried.

But `[1, 1, 6]` uses both 1s. That is allowed because the second 1 is chosen at **depth 1** (`i == start` there), not as an alternative at depth 0. The condition `i > start` distinguishes these cases.

## Step 3: The code

<!-- CODE:START -->

Full source: [`combination_sum_ii.dart`](combination_sum_ii.dart) (run it with `dart run`).

```dart
// Combination Sum II: candidates may contain duplicates; each element may be used at most once.
// Return all unique combinations that sum to target.
// Sort, backtrack with a start index, recurse with i + 1 (no reuse), and skip equal values at the
// same depth (no duplicate combinations). Exponential time, O(n) recursion space.

List<List<int>> combinationSum2(List<int> candidates, int target) {
  final c = [...candidates]..sort();
  final result = <List<int>>[];
  final path = <int>[];
  void dfs(int start, int remaining) {
    if (remaining == 0) {
      result.add([...path]);
      return;
    }
    for (var i = start; i < c.length; i++) {
      if (i > start && c[i] == c[i - 1]) continue; // same value already tried at this depth
      if (c[i] > remaining) break; // sorted: every later value is too big as well
      path.add(c[i]);
      dfs(i + 1, remaining - c[i]); // i + 1: each element used at most once
      path.removeLast();
    }
  }

  dfs(0, target);
  return result;
}
```

<!-- CODE:END -->

### Walkthrough

- The skip check comes before the `break` check; either order works because both use the sorted array.
- `break` (not `continue`) on `c[i] > remaining`: every later value is at least as large.
- `dfs(i + 1, ...)`: no reuse.

## Step 4: Dry run

Sorted `[1, 1, 2, 5, 6, 7, 10]`, target 8. Each line is a choice; "stop" means the `break` fired because the next value exceeds the remainder.

```
depth 0: pick 1 (index 0), remaining 7
  depth 1: pick 1 (index 1), remaining 6
    depth 2: pick 2, remaining 4 -> next is 5 > 4: stop
    depth 2: pick 5, remaining 1 -> next is 6 > 1: stop
    depth 2: pick 6, remaining 0 => [1, 1, 6]
    depth 2: 7 > 6: stop
  depth 1: pick 2, remaining 5
    depth 2: pick 5, remaining 0 => [1, 2, 5]
    depth 2: 6 > 5: stop
  depth 1: pick 5 (remaining 2), pick 6 (remaining 1): both dead ends
  depth 1: pick 7, remaining 0 => [1, 7]
  depth 1: 10 > 7: stop
depth 0: index 1 is another 1: SKIPPED (i > start and equal to index 0)
depth 0: pick 2, remaining 6
  depth 1: pick 5 (dead end), pick 6 => [2, 6], then 7 > 6: stop
depth 0: pick 5, 6, 7: dead ends; 10 > 8: stop
```

## Complexity

- Time: **O(2^n * n)** in the worst case (every subset explored, each copied in O(n)); pruning makes it much faster in practice.
- Space: **O(n)** recursion depth, excluding output.

## Edge cases

- No combination: `[]`.
- All equal candidates (`[1, 1, 1]`, target 2): `[[1, 1]]` once.

## Common mistakes

- Skipping with `i > 0` instead of `i > start` (loses `[1, 1, 6]`).
- Deduplicating results with a set afterwards (works, but explores duplicate branches).
- Recursing with `i` (allows reuse).

## Follow-ups you should be ready for

1. **Combination Sum III (LeetCode 216).** Exactly k distinct numbers from 1..9.
2. **Count only.** 0/1 knapsack counting over distinct values with multiplicities.
3. **Subsets II.** The same skip rule without a target.

## What to remember

Backtracking family: start index for combinations; `i` vs `i + 1` for reuse; `i > start && equal` skip for duplicate inputs.
