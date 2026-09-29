# Reverse Polish Notation

**Difficulty:** Medium | **Category:** Stacks | **Pattern:** Stack-based expression evaluation

## Problem
Evaluate an arithmetic expression given as a list of tokens in Reverse Polish (postfix) notation. Operators are `+ - * /`; division truncates toward zero. The expression is valid.

```
["50", "3", "17", "+", "2", "-", "/"]  =  50 / ((3 + 17) - 2)  =  2
```

## Building up the logic
1. In postfix, each operator applies to the two most recent values. "Most recent" = stack.
2. Numbers: push. Operator: pop right operand **first**, then left, compute, push the result.
3. Operand order matters for `-` and `/`. Popping in the wrong order is the most common bug.
4. At the end the stack holds exactly one value.
5. Negative numbers like `"-7"` are tokens too: check for operators by exact match, not by first character.

## Complexity
- Time: O(n).
- Space: O(n).

## Interview notes
- LeetCode #150. Related: converting infix to postfix (shunting-yard algorithm) and Basic Calculator (#224/#227), both common at Google/Meta.
- RPN is the post-order traversal of an expression tree; compare with Evaluate Expression Tree.
