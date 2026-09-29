# Dice Throws

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** Counting DP over (items, total)

## Problem
You roll `numDice` dice, each with faces `1..numSides`. Return the number of distinct outcomes (ordered: die 1 shows 3 and die 2 shows 4 is different from the reverse) whose faces sum to `target`.

```
numDice = 2, numSides = 6, target = 7  ->  6
```

## Building up the logic
1. Brute force: `numSides^numDice` outcomes.
2. **Subproblem:** `ways[d][t]` = number of ways to reach total `t` with `d` dice.
3. **Recurrence:** the last die shows some face `f`: `ways[d][t] = sum over f of ways[d-1][t-f]`.
4. Base: `ways[0][0] = 1`, `ways[0][t>0] = 0`.
5. Only the previous row is needed: rolling array, O(t) space.
6. Speed-up: the inner sum is a sliding window of width `numSides` over the previous row, so maintain a running window sum (like Staircase Traversal). Time O(d * t).

## Complexity
- Time: O(d * t * s) as written; O(d * t) with the sliding window.
- Space: O(t).

## Interview notes
- LeetCode #1155 (Number of Dice Rolls With Target Sum), which asks for the result modulo 10^9 + 7. Mention modular arithmetic whenever counts explode; Dart `int` overflows silently past 2^63.
