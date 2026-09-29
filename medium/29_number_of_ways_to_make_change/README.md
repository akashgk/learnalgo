# Number Of Ways To Make Change

**Difficulty:** Medium | **Category:** Dynamic Programming | **Pattern:** Unbounded knapsack (counting)

## Problem
Given a target amount `n` and a list of distinct positive coin denominations (unlimited supply of each), return the number of ways to make exactly `n`. Order does not matter: `1 + 5` and `5 + 1` are the same way. There is one way to make 0 (use no coins).

## Building up the logic
1. **Subproblem:** `ways[a]` = number of ways to make amount `a` with the coins considered so far.
2. **Add one denomination at a time.** With coin `c` available, any way to make `a` either uses no `c` (already counted) or uses at least one `c` (then the rest is a way to make `a - c`, which may use more `c`'s). So `ways[a] += ways[a - c]`.
3. Iterate amounts **upward** so `ways[a - c]` already includes using coin `c` again (unbounded supply).
4. **Loop order is the whole problem:**
   - coins outer, amounts inner -> counts **combinations** (what we want). Each combination is built in a fixed coin order, so it is counted once.
   - amounts outer, coins inner -> counts **permutations** (`1+5` and `5+1` separately). That is LeetCode #377 (Combination Sum IV).
5. Base case `ways[0] = 1`.

Walk it for `n = 6, coins = [1, 5]`: after coin 1, `ways = [1,1,1,1,1,1,1]`. After coin 5: `ways[5] += ways[0]` -> 2, `ways[6] += ways[1]` -> 2.

## Complexity
- Time: O(n * d), d = number of denominations.
- Space: O(n).

## Interview notes
- LeetCode #518 (Coin Change II). Be ready to explain the loop-order difference; it is a favorite probing question.
