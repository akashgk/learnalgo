# Min Number Of Jumps

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** DP O(n^2) -> greedy level expansion O(n)

## Problem
Each element is the maximum number of positions you may jump forward from that index. Starting at index 0, return the minimum number of jumps to reach the last index. Assume it is always reachable.

## Building up the logic
1. **DP:** `jumps[i]` = min jumps to reach i. For each i, for each earlier j with `j + a[j] >= i`, `jumps[i] = min(jumps[j] + 1)`. O(n^2) time, O(n) space. Good first answer.
2. **See it as BFS:** indices reachable with 0 jumps: `{0}`. With 1 jump: `[1, a[0]]`. With 2 jumps: everything reachable from that range, which is `[prevEnd + 1, max(i + a[i]) over the range]`. Each level is a contiguous range, so you never need a queue.
3. Scan left to right keeping `farthest` (max reach seen so far) and `currentEnd` (end of the current level). When `i` reaches `currentEnd`, you must spend a jump: increment and extend `currentEnd = farthest`.
4. Loop to `n - 2`: you never need to jump **from** the last index.

## Complexity
| Approach | Time | Space |
|---|---|---|
| DP | O(n^2) | O(n) |
| Greedy levels | O(n) | O(1) |

## Interview notes
- LeetCode #45 (Jump Game II). #55 (Jump Game) asks only reachability: track `farthest` and fail if `i > farthest`.
- Explaining the greedy as "implicit BFS where each level is an interval" is the convincing argument; saying "greedy" alone is not.
