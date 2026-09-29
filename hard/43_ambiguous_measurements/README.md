# Ambiguous Measurements

**Difficulty:** Hard | **Category:** Recursion | **Pattern:** Memoized recursion over a range state

## Problem
You have measuring cups; filling cup `i` yields an unknown amount in `[low_i, high_i]`. You pour whole cups (any cup, any number of times) into one container. Given a target range `[low, high]`, return whether some sequence of pours **guarantees** the total lands in the target range, no matter where each pour falls within its cup's range.

```
cups = [[200, 210], [450, 465], [800, 850]], target = [2100, 2300]  ->  true
one guaranteed combination: 800-850 + 2 x (450-465) + 2 x (200-210) = [2100, 2200]
```

## Building up the logic
1. Summing `k` pours gives a total range `[sum of lows, sum of highs]`. The guarantee holds iff that range is inside `[low, high]`.
2. **Recursive formulation:** pouring cup `c` first leaves a smaller problem: the rest must land in `[low - c.low, high - c.high]`. Why these bounds: the rest's total must satisfy both extremes, `rest + c.low >= low` and `rest + c.high <= high`.
3. Base cases and pruning:
   - if a single cup's range fits inside the current target, success;
   - if `c.high >= high` and the cup does not fit alone, pouring it leaves no room for anything else, so skip it;
   - a remaining lower bound below zero is clamped to 0 (you have already guaranteed enough).
   - `high` strictly decreases with every pour (cup ranges are positive), so the recursion terminates.
4. The same `(low, high)` state is reached through many pour orders, so memoize on it.

## Complexity
- Time: O(low * high * n) in the worst case (distinct states times cups).
- Space: O(low * high) memo plus recursion depth.

## Interview notes
- The skill tested is turning an "uncertain quantity" into interval arithmetic, then recognizing overlapping subproblems. Always derive the new bounds from both inequalities explicitly.
