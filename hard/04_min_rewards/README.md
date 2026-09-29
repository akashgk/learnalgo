# Min Rewards

**Difficulty:** Hard | **Category:** Arrays | **Pattern:** Two-pass greedy (left and right constraints)

## Problem
Students stand in a line; each has a distinct score. Give each student at least one reward so that any student with a higher score than an **adjacent** student receives strictly more rewards than that neighbor. Return the minimum total number of rewards.

```
[8, 4, 2, 1, 3, 6, 7, 9, 5]  ->  25   (rewards 4, 3, 2, 1, 2, 3, 4, 5, 1)
```

## Building up the logic
1. Every constraint is local (between neighbors), and each student has at most two: one with the left neighbor, one with the right.
2. **Left pass:** satisfy only the left-neighbor constraints. Going left to right, if `score[i] > score[i-1]`, set `rewards[i] = rewards[i-1] + 1`; otherwise leave it at 1. This is the minimum for increasing runs.
3. **Right pass:** satisfy the right-neighbor constraints going right to left, but never lower an existing value: `rewards[i] = max(rewards[i], rewards[i+1] + 1)` when `score[i] > score[i+1]`.
4. Taking the max keeps both constraints satisfied, and each value equals the length of the longest strictly decreasing run ending at it from either side, which is the minimum possible.
5. Alternative view: every local minimum (valley) gets 1, and values grow by one while walking uphill away from valleys; peaks take the max of both slopes.

## Complexity
- Time: O(n).
- Space: O(n).

## Interview notes
- LeetCode #135 (Candy). There, scores may repeat and equal neighbors have no constraint; the same two-pass code handles it because of the strict `>` checks.
- A common wrong answer is a single left-to-right pass with fix-ups going backward, which degrades to O(n^2).
