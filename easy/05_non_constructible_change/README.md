# Non-Constructible Change

**Difficulty:** Easy | **Category:** Arrays | **Pattern:** Sorting + greedy invariant

## Problem
Given positive integer coin values (duplicates allowed), return the minimum amount of change you **cannot** make using any subset of the coins. With no coins the answer is 1.

```
coins = [5, 7, 1, 1, 2, 3, 22]  ->  20
```

## Building up the logic
1. Brute force: generate all subset sums (2^n) and find the smallest missing positive. Too slow, but it tells you the question is about subset sums.
2. Try small cases by hand after sorting. With `[1]` you can make 1. Add `1`: you can make 1..2. Add `2`: 1..4. Add `3`: 1..7. Add `5`: 1..12. Add `7`: 1..19. Next coin 22 > 20, so 20 is impossible.
3. **Invariant:** after processing sorted coins, let `change` be the sum so far; every amount in `[1, change]` is constructible.
4. **Extending it:** a new coin `c` lets you make `[c, c + change]`. That range joins the old one without a gap only if `c <= change + 1`. If `c > change + 1`, then `change + 1` is unreachable now, and every later coin is at least `c`, so it stays unreachable forever. That is why sorting matters and why we can stop early.

## Complexity
- Time: O(n log n) for sorting; the scan is O(n).
- Space: O(1) extra if you sort in place. This code copies to avoid mutating the input (O(n)).

## Edge cases
- Empty list -> 1.
- No coin of value 1 -> 1.

## Interview notes
- The invariant proof is the whole question. If you can state "all of `[1, change]` is reachable" and show how a coin extends it, you have solved it.
- Related: LeetCode #330 (Patching Array) uses exactly this invariant.
