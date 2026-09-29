# Balanced Brackets

**Difficulty:** Medium | **Category:** Stacks | **Pattern:** Stack matching

## Problem
Return whether the brackets in a string are balanced: every opening bracket `(`, `[`, `{` is closed by the matching type in the correct order, and no closer appears without an opener. Non-bracket characters are ignored.

## Building up the logic
1. Counting openers and closers fails for `([)]`: counts match but nesting is wrong.
2. The most recently opened bracket must be closed first: **last in, first out**, which is a stack.
3. Push openers. On a closer, the stack top must be its matching opener; otherwise fail. An empty stack on a closer also fails.
4. At the end, the stack must be empty (unclosed openers fail).

## Complexity
- Time: O(n).
- Space: O(n) for the stack.

## Interview notes
- LeetCode #20. Follow-ups: minimum insertions to balance (#921), longest valid parentheses substring (#32, see Longest Balanced Substring), generate all balanced strings (Generate Div Tags).
- With only one bracket type, a counter suffices (O(1) space). Mention it.
