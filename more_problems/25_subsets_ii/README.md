# Subsets II

**Difficulty:** Medium | **Category:** Recursion / Backtracking | **Pattern:** Backtracking with duplicate skipping at the same depth | **Source:** LeetCode 90; Striver A2Z, NeetCode 150

## The problem

Return all subsets of an array that **may contain duplicates**, without duplicate subsets.

```
[1, 2, 2]  ->  [[], [1], [1, 2], [1, 2, 2], [2], [2, 2]]
```

Without the dedupe, the 2^3 = 8 subsets would include `[2]` twice and `[1, 2]` twice.

## Step 1: Start from Subsets I

For distinct values (AlgoExpert medium 52 Powerset), a clean backtracking form is: every node of the recursion is a subset; from a node, try adding each element with index `>= start`, then recurse with `start = i + 1`.

```
dfs(start):
  record path
  for i in start..n-1:
    path.add(a[i]); dfs(i + 1); path.removeLast()
```

## Step 2: Where do duplicates come from?

Sort first: `[1, 2, 2]`, indices 0, 1, 2. At the root, the loop tries `a[1] = 2` and `a[2] = 2`. Both give a subset `[2]`, and then both explore the same continuations. The duplicates come from **choosing equal values at the same depth** (as the same "next element" of the subset).

Choosing equal values at **different** depths is fine: `[2, 2]` uses index 1 at depth 1 and index 2 at depth 2.

## Step 3: The rule

Within one loop (one depth), use only the **first** of a run of equal values:

```
if (i > start && a[i] == a[i - 1]) continue;
```

- `i > start`: `a[i - 1]` was an option at this same depth, so choosing `a[i]` here would repeat it.
- `i == start`: `a[i - 1]` (if equal) was chosen at the **previous** depth, which is allowed; this is how `[2, 2]` is built.

Sorting is what makes equal values adjacent, so the rule works.

## Step 4: The recursion tree for `[1, 2, 2]`

```
[]
|- [1]
|   |- [1, 2]
|   |   |- [1, 2, 2]
|   |- [1, 2] (index 2)   skipped: i > start and a[2] == a[1]
|- [2]
|   |- [2, 2]
|- [2] (index 2)          skipped
```

Six subsets, no duplicates.

## Step 5: The code

<!-- CODE:START -->

Full source: [`subsets_ii.dart`](subsets_ii.dart) (run it with `dart run`).

```dart
// Subsets II: all subsets of an array that may contain duplicates, without duplicate subsets.
// Sort, then backtrack; at each depth skip a value equal to the previous choice at the same depth.
// O(n * 2^n) time, O(n) recursion space (excluding output).

List<List<int>> subsetsWithDup(List<int> nums) {
  final a = [...nums]..sort();
  final result = <List<int>>[];
  final path = <int>[];
  void dfs(int start) {
    result.add([...path]); // every node of the recursion tree is a subset
    for (var i = start; i < a.length; i++) {
      // Choosing a[i] here after skipping an equal a[i - 1] at this same depth repeats a subset.
      if (i > start && a[i] == a[i - 1]) continue;
      path.add(a[i]);
      dfs(i + 1);
      path.removeLast();
    }
  }

  dfs(0);
  return result;
}
```

<!-- CODE:END -->

### Walkthrough

- The input is copied and sorted.
- `result.add([...path])` at the start of `dfs` records every node, including the empty subset at the root.
- The skip rule is the only difference from Subsets I.

## Step 6: Dry run

The tree above is the exact execution order: `[]`, `[1]`, `[1, 2]`, `[1, 2, 2]`, `[2]`, `[2, 2]`, which is the expected output.

## Complexity

- Time: **O(n * 2^n)** in the worst case (all distinct): 2^n subsets, each copied in O(n). With duplicates, the output is smaller: the product over distinct values of (count + 1).
- Space: **O(n)** recursion depth, excluding output.

## Edge cases

- Empty input: `[[]]`.
- All equal, `[2, 2, 2]`: `[]`, `[2]`, `[2, 2]`, `[2, 2, 2]`.

## Common mistakes

- Forgetting to sort.
- Writing `i > 0` instead of `i > start` (then `[2, 2]` is never generated).
- Deduplicating with a set of lists: works, but still explores all 2^n branches and needs a canonical form for each list.

## Follow-ups you should be ready for

1. **Permutations II (LeetCode 47).** Same idea for permutations: skip `a[i]` if it equals `a[i - 1]` and `a[i - 1]` is **not currently used**.
2. **Combination Sum II (LeetCode 40).** This exact skip rule plus a target.
3. **Iterative version.** Build subsets level by level; when the current value equals the previous one, only extend the subsets created in the previous round.

## What to remember

Duplicates in backtracking come from making the same choice twice **at the same depth**. Sort, then skip a value equal to its predecessor when that predecessor was an option at this depth (`i > start`).
