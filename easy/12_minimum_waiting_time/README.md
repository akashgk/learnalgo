# Minimum Waiting Time

**Difficulty:** Easy | **Category:** Greedy | **Pattern:** Sort then greedy (shortest job first)

## Problem
You have a list of positive query durations. Queries run one at a time, in any order you choose. A query's waiting time is the total time spent before it starts. Return the minimum possible total waiting time across all queries.

```
[3, 2, 1, 2, 6]  ->  17   (order 1, 2, 2, 3, 6: waits 0 + 1 + 3 + 5 + 8)
```

## Building up the logic
1. Brute force: try all n! orders. Useless, but it frames the question as "choose an order".
2. Count contributions instead of simulating. The query at position `i` (0-based) delays every query after it, so it contributes `duration * (n - 1 - i)` to the total.
3. Large durations should get small multipliers, so they should go last. Sort ascending.
4. **Exchange argument (the proof):** if a longer query `a` runs right before a shorter `b`, swapping them reduces `b`'s wait by `a` and increases `a`'s wait by `b`. Net change `b - a < 0`. So any order with an inversion can be improved; the sorted order is optimal.

## Complexity
- Time: O(n log n) for the sort.
- Space: O(1) extra with in-place sort (this code copies: O(n)).

## Interview notes
- Greedy problems at FAANG are judged on the proof. Learn to say "exchange argument" and show the swap.
- This is the classic Shortest Processing Time rule from scheduling theory.
