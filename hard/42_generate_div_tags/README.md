# Generate Div Tags

**Difficulty:** Hard | **Category:** Recursion | **Pattern:** Backtracking with validity counters (balanced parentheses)

## Problem
Given a positive integer n, return all strings made of exactly n `<div>` and n `</div>` tags that are properly matched and nested, in any order.

## Building up the logic
1. Generating all 2^(2n) sequences and filtering valid ones is wasteful.
2. Build left to right and only take moves that keep the prefix valid:
   - add an opening tag if any remain;
   - add a closing tag only if it closes something, i.e. more closes than opens remain (`closesLeft > opensLeft`).
3. Every complete string produced this way is valid, and no invalid prefix is ever explored.
4. This is exactly Generate Parentheses with `(` = `<div>` and `)` = `</div>`.

## Complexity
- The number of results is the nth Catalan number `C(n) = (2n)! / ((n + 1)! n!)`, which grows like `4^n / (n^1.5 * sqrt(pi))`.
- Time: O(C(n) * n) to build each string.
- Space: O(C(n) * n) output, O(n) recursion.

## Interview notes
- LeetCode #22. Catalan numbers also count BST shapes (Number Of Binary Tree Topologies), triangulations, and Dyck paths; recognizing them lets you state output sizes precisely.
