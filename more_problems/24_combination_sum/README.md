# Combination Sum

**Difficulty:** Medium | **Category:** Recursion / Backtracking | **Pattern:** Backtracking with a start index (unbounded choices) | **Source:** LeetCode 39; Striver A2Z, NeetCode 150

## The problem

Given **distinct** positive integers `candidates` and a `target`, return all unique combinations whose sum is `target`. The same number may be used any number of times. Combinations are multisets: `[2, 2, 3]` and `[3, 2, 2]` are the same combination.

```
candidates = [2, 3, 6, 7], target = 7  ->  [[2, 2, 3], [7]]
candidates = [2, 3, 5],    target = 8  ->  [[2, 2, 2, 2], [2, 3, 3], [3, 5]]
```

## Step 1: The naive recursion produces duplicates

"At each step, pick any candidate and recurse on `target - candidate`" finds every **sequence** summing to the target: `[2, 2, 3]`, `[2, 3, 2]`, `[3, 2, 2]` all appear. Deduplicating afterwards with a set of sorted lists works, but wastes exponential work.

## Step 2: Generate each combination in one canonical order

Only generate combinations in **non-decreasing index order**. At each level, pass a `start` index: the next number chosen must have index `>= start`. Then `[2, 2, 3]` can be generated, but `[3, 2, 2]` cannot (after choosing 3 at index 1, index 0 is off limits). Each multiset has exactly one non-decreasing arrangement, so each is produced exactly once.

Reuse is allowed, so after choosing index `i`, recurse with `start = i` (not `i + 1`).

## Step 3: The recursion tree

`candidates = [2, 3, 6, 7]`, target 7. Each node shows the remaining target:

```
7
|- 2 -> 5
|       |- 2 -> 3
|       |       |- 2 -> 1   (2 > 1: stop)
|       |       |- 3 -> 0   => [2, 2, 3]
|       |- 3 -> 2           (3 > 2: stop)
|- 3 -> 4
|       |- 3 -> 1           (3 > 1: stop)
|- 6 -> 1                   (6 > 1: stop)
|- 7 -> 0                   => [7]
```

## Step 4: Pruning

Sort the candidates first. Then in the loop, as soon as `c[i] > remaining`, **break**: every later candidate is larger, so none can fit. Without sorting, you can only `continue`, trying every candidate at every node.

## Step 5: The code

<!-- CODE:START -->

Full source: [`combination_sum.dart`](combination_sum.dart) (run it with `dart run`).

```dart
// Combination Sum: all unique combinations of distinct candidates summing to target;
// each candidate may be used any number of times. Backtracking with a start index
// (so each combination is generated in one canonical order). Exponential time.

List<List<int>> combinationSum(List<int> candidates, int target) {
  final c = [...candidates]..sort(); // sorting lets us stop early once a candidate is too big
  final result = <List<int>>[];
  final path = <int>[];
  void dfs(int start, int remaining) {
    if (remaining == 0) {
      result.add([...path]);
      return;
    }
    for (var i = start; i < c.length; i++) {
      if (c[i] > remaining) break; // every later candidate is even bigger
      path.add(c[i]);
      dfs(i, remaining - c[i]); // i, not i + 1: the same candidate may be reused
      path.removeLast();
    }
  }

  dfs(0, target);
  return result;
}
```

<!-- CODE:END -->

### Walkthrough

- `path` is one shared list: push before recursing, pop after (the "choose, explore, unchoose" pattern). Copy it (`[...path]`) when recording an answer, or every answer would alias the same list.
- `dfs(i, remaining - c[i])` passes `i`, allowing reuse.
- `remaining == 0` records a combination. Negative remainders never happen because of the `break`.

## Step 6: Dry run

Matches the tree in Step 3. Results in order: `[2, 2, 3]`, `[7]`.

## Complexity

Let `T` = target and `m` = smallest candidate. The tree depth is at most `T / m`, and each node branches at most n ways, so time is **O(n^(T/m + 1))** in the worst case, times the O(T/m) copy per answer. This is a loose bound; the real answer count is what matters in practice. Space: **O(T/m)** recursion depth (excluding output).

## Edge cases

- No combination: `[2]`, target 1 -> `[]`.
- Target equal to a candidate: that candidate alone is an answer.
- Candidate 1: many answers; the recursion depth reaches T.

## Common mistakes

- Recursing with `i + 1` (forbids reuse) or with `0` (produces permutations).
- Appending `path` itself instead of a copy.
- Forgetting to pop after recursing.

## Follow-ups you should be ready for

1. **Combination Sum II (LeetCode 40).** Candidates may repeat, each used at most once: recurse with `i + 1` and skip duplicates at the same depth (the exact trick of more_problems 25 Subsets II).
2. **Combination Sum III (LeetCode 216).** Exactly k numbers from 1..9, each at most once.
3. **Count only.** That is the coin change DP (AlgoExpert medium 29 Number Of Ways To Make Change), O(n * T) instead of exponential.
4. **Order matters (Combination Sum IV, LeetCode 377).** Then sequences are distinct answers, and the DP loops over targets on the outside.

## What to remember

To enumerate combinations (not permutations), pass a start index so choices are made in a fixed order. Pass `i` to allow reuse, `i + 1` to forbid it. Sort to prune with `break`.
