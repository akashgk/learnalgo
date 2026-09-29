# Number Of Binary Tree Topologies

**Difficulty:** Very Hard | **Category:** Recursion | **Pattern:** Catalan recurrence (DP over split points)

## Problem
Given a non-negative integer n, return how many structurally different binary trees with n nodes exist. With n = 0 the answer is 1 (the empty tree).

## Building up the logic
1. One node is the root. The remaining `n - 1` nodes split into a left subtree of size `k` and a right subtree of size `n - 1 - k`, for `k = 0 .. n-1`.
2. The left and right shapes are independent, so the count for a split is a **product**; different splits are disjoint, so sum them:
   `T(n) = sum over k of T(k) * T(n - 1 - k)`, with `T(0) = 1`.
3. Naive recursion recomputes the same `T(k)` exponentially many times. Memoize or tabulate: O(n^2).
4. These are the **Catalan numbers**: 1, 1, 2, 5, 14, 42, 132, ... with closed form `C(n) = (2n)! / ((n + 1)! n!)`, computable in O(n).

## Complexity
| Approach | Time | Space |
|---|---|---|
| Naive recursion | exponential (about O(4^n / n^1.5) calls) | O(n) |
| DP | O(n^2) | O(n) |
| Closed form | O(n) | O(1) |

## Interview notes
- LeetCode #96 (Unique Binary Search Trees): the number of BSTs with keys 1..n is the same Catalan number (choosing the root value fixes the split sizes). #95 asks to generate them all.
- Catalan numbers also count valid parentheses strings (Generate Div Tags) and polygon triangulations. Recognizing the recurrence shape `sum T(k) T(n-1-k)` is the skill.
