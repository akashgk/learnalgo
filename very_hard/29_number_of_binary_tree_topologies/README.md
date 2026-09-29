# Number Of Binary Tree Topologies

**Difficulty:** Very Hard | **Category:** Recursion | **Pattern:** Catalan recurrence (DP over split points)

## The problem

Given a non-negative integer n, return how many **structurally different** binary trees with n nodes exist (the values in the nodes do not matter, only the shape). For n = 0 the answer is 1 (the empty tree).

```
n = 0 -> 1,  n = 1 -> 1,  n = 2 -> 2,  n = 3 -> 5,  n = 4 -> 14
```

The 5 shapes for n = 3:

```
    o        o         o          o      o
   /        /         / \          \      \
  o        o         o   o          o      o
 /          \                      /        \
o            o                    o          o
```

## Step 1: Split at the root

Every non-empty tree has a root. The remaining `n - 1` nodes are divided between the left and right subtrees: the left gets `k` nodes and the right gets `n - 1 - k`, for some k from 0 to n - 1.

- For a fixed split, any left shape can be combined with any right shape: the count is a **product** `T(k) * T(n - 1 - k)`.
- Different splits give different trees: **add** them.

```
T(0) = 1
T(n) = sum over k = 0..n-1 of T(k) * T(n - 1 - k)
```

Check: `T(2) = T(0)T(1) + T(1)T(0) = 2`; `T(3) = T(0)T(2) + T(1)T(1) + T(2)T(0) = 2 + 1 + 2 = 5`.

## Step 2: Avoid recomputation

Plain recursion recomputes the same `T(k)` many times (exponential). Every `T(n)` needs only smaller values, so compute `T(0), T(1), ..., T(n)` in order: **O(n^2)** time, O(n) space.

## Step 3: Catalan numbers

These are the **Catalan numbers**: 1, 1, 2, 5, 14, 42, 132, ... with a closed form

```
C(n) = (2n)! / ((n + 1)! * n!)
```

computable in O(n). The same numbers count balanced parentheses strings (Generate Div Tags, hard 42), BSTs with keys 1..n, triangulations of polygons, and many more. Recognizing the recurrence shape `sum T(k) * T(n - 1 - k)` is the skill.

## Step 4: The code

<!-- CODE:START -->

Full source: [`number_of_binary_tree_topologies.dart`](number_of_binary_tree_topologies.dart) (run it with `dart run`).

```dart
// Number Of Binary Tree Topologies with n nodes (the nth Catalan number).
// T(n) = sum over leftSize of T(leftSize) * T(n - 1 - leftSize). O(n^2) time, O(n) space.

int numberOfBinaryTreeTopologies(int n) {
  final t = List<int>.filled(n + 1, 0)..[0] = 1;
  for (var nodes = 1; nodes <= n; nodes++) {
    for (var leftSize = 0; leftSize < nodes; leftSize++) {
      t[nodes] += t[leftSize] * t[nodes - 1 - leftSize];
    }
  }
  return t[n];
}
```

<!-- CODE:END -->

### Walkthrough

- `t` is the table, with `t[0] = 1`.
- For each `nodes`, sum the products over all left-subtree sizes.

## Step 5: Dry run

| n | sum of products | T(n) |
|---|---|---|
| 0 | | 1 |
| 1 | T0*T0 | 1 |
| 2 | T0*T1 + T1*T0 | 2 |
| 3 | T0*T2 + T1*T1 + T2*T0 = 2 + 1 + 2 | 5 |
| 4 | T0*T3 + T1*T2 + T2*T1 + T3*T0 = 5 + 2 + 2 + 5 | 14 |

## Complexity

| Approach | Time | Space |
|---|---|---|
| Plain recursion | exponential (about 4^n calls) | O(n) |
| DP table | O(n^2) | O(n) |
| Closed form | O(n) | O(1) |

## Common mistakes

- `T(0) = 0` (the empty subtree is one valid shape; with 0 every product vanishes).
- Overflow: Catalan numbers grow like 4^n; use modulo arithmetic or `BigInt` for large n.

## Follow-ups

1. **Unique Binary Search Trees (LeetCode #96):** the number of BSTs with keys 1..n is the same Catalan number (the root value fixes the split).
2. **Unique Binary Search Trees II (#95):** generate all of them recursively.

## What to remember

Counting tree shapes: split at the root, multiply the counts of independent parts, add over all splits. That recurrence produces the Catalan numbers.
