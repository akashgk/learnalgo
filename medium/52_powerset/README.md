# Powerset

**Difficulty:** Medium | **Category:** Recursion | **Pattern:** Subset generation (iterative doubling, bitmask, backtracking)

## The problem

Given an array of unique integers, return its **powerset**: the set of all subsets, including the empty set and the full set. Order does not matter.

```
[1, 2, 3]  ->  [[], [1], [2], [1, 2], [3], [1, 3], [2, 3], [1, 2, 3]]
```

## Step 1: How many subsets?

Each element is independently **in** or **out** of a subset: 2 choices per element, so 2^n subsets. For 3 elements, 8.

## Step 2: Approach A: iterative doubling (this code)

Build the answer one element at a time:

| after element | subsets |
|---|---|
| (none) | [] |
| 1 | [], [1] |
| 2 | [], [1], [2], [1, 2] |
| 3 | [], [1], [2], [1, 2], [3], [1, 3], [2, 3], [1, 2, 3] |

Adding element `x` keeps every existing subset (x out) and adds a copy of each existing subset with `x` appended (x in). The count doubles each time.

The recursive way to say the same thing: `powerset(first k elements) = powerset(first k-1) + (each of those + element k)`.

## Step 3: Approach B: bitmasks

Number the subsets `0 .. 2^n - 1`. In subset number `mask`, element `i` is included iff bit `i` of `mask` is 1:

| mask (binary) | subset of [1, 2, 3] |
|---|---|
| 000 | [] |
| 001 | [1] |
| 010 | [2] |
| 011 | [1, 2] |
| 100 | [3] |
| 101 | [1, 3] |
| 110 | [2, 3] |
| 111 | [1, 2, 3] |

Short to write, and the same idea powers "DP over subsets" for problems with n <= 20.

## Step 4: Approach C: backtracking

At index i, recurse twice: once without `a[i]`, once with it (append, recurse, remove). Record the current subset at the end. Same complexity, and it adapts easily to constraints (for example "subsets that sum to X": prune branches).

## Step 5: The code

<!-- CODE:START -->

Full source: [`powerset.dart`](powerset.dart) (run it with `dart run`).

```dart
// Powerset: all subsets. Iterative doubling: for each element, add it to every existing subset.
// O(n * 2^n) time and space.

List<List<int>> powerset(List<int> array) {
  final subsets = <List<int>>[[]];
  for (final x in array) {
    final count = subsets.length; // snapshot: only extend subsets that existed before x
    for (var i = 0; i < count; i++) {
      subsets.add([...subsets[i], x]);
    }
  }
  return subsets;
}

/// Bitmask version: subset `mask` contains array[i] iff bit i is set.
List<List<int>> powersetBitmask(List<int> array) => [
  for (var mask = 0; mask < 1 << array.length; mask++)
    [
      for (var i = 0; i < array.length; i++)
        if (mask & (1 << i) != 0) array[i],
    ],
];
```

<!-- CODE:END -->

### Walkthrough of `powerset`

- `final subsets = <List<int>>[[]];` starts with the empty subset.
- `final count = subsets.length;` takes a **snapshot** before adding. Without it, the loop would also extend the subsets it just added, and never end.
- `subsets.add([...subsets[i], x]);` creates a new list (copy plus `x`), leaving the original subset unchanged.

### Walkthrough of `powersetBitmask`

- `for (var mask = 0; mask < 1 << array.length; mask++)` enumerates all 2^n masks.
- `if (mask & (1 << i) != 0) array[i]` includes element `i` when its bit is set (a collection-if inside a list literal).

## Complexity

- **Time: O(n * 2^n)**: 2^n subsets with average length n/2 to build.
- **Space: O(n * 2^n)** for the output.

Rule of thumb: 2^20 is about a million, so enumerating subsets is feasible for n up to about 20.

## Common mistakes

- Looping over a list while appending to it (forgetting the snapshot).
- Appending to an existing subset in place instead of copying.

## Follow-ups

1. **Subsets II (LeetCode #90), duplicates in the input:** sort; when an element equals the previous one, only extend the subsets created in the previous round.
2. **Subsets of size k / combinations (#77):** backtracking with a size limit.
3. **Combination Sum (#39):** backtracking with pruning by remaining target.

## What to remember

Every element is in or out: 2^n subsets. Build them by doubling, by bitmask, or by an in/out backtracking recursion.
