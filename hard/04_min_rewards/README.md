# Min Rewards

**Difficulty:** Hard | **Category:** Arrays | **Pattern:** Two-pass greedy (left and right constraints)

## The problem

Students stand in a line; each has a **distinct** score. Give each student at least one reward so that any student with a higher score than an **adjacent** student gets strictly more rewards than that neighbor. Return the minimum total number of rewards.

```
scores  = [8, 4, 2, 1, 3, 6, 7, 9, 5]
rewards = [4, 3, 2, 1, 2, 3, 4, 5, 1]   total 25
```

## Step 1: Work an example by hand

Look at the **valleys** (students lower than both neighbors): the student with score 1 must get at least 1, and nothing forces more. Moving away from a valley uphill, each step needs one more reward: to the right `3 -> 2`, `6 -> 3`, `7 -> 4`, `9 -> 5`; to the left `2 -> 2`, `4 -> 3`, `8 -> 4`. At the end, 5 is lower than 9, so it can get 1.

A peak between two slopes needs to satisfy both sides: it takes the **maximum** of the two slope counts.

## Step 2: Brute force

Start with everyone at 1. Repeatedly scan and fix any violated pair by bumping the higher student to `neighbor + 1`, until nothing changes. Correct but O(n^2) in the worst case (a long decreasing run fixes one step per scan).

## Step 3: Two passes

Each student has at most two constraints: with the left neighbor and with the right neighbor. Satisfy them separately:

1. **Left to right:** if `score[i] > score[i-1]`, set `rewards[i] = rewards[i-1] + 1`. This satisfies every "beat my left neighbor" constraint with the minimum values.
2. **Right to left:** if `score[i] > score[i+1]`, set `rewards[i] = max(rewards[i], rewards[i+1] + 1)`. The `max` keeps the left constraint satisfied while adding the right one.

Why minimal? After both passes, each value equals `1 + the length of the longest strictly decreasing run going away from it on either side`, which any valid assignment must also give at least.

## Step 4: The code

<!-- CODE:START -->

Full source: [`min_rewards.dart`](min_rewards.dart) (run it with `dart run`).

```dart
// Min Rewards: students in a line with distinct scores. Everyone gets >= 1 reward, and a
// student with a higher score than an adjacent student gets strictly more than them.
// Two sweeps (left-to-right, right-to-left). O(n) time, O(n) space.

int minRewards(List<int> scores) {
  final rewards = List<int>.filled(scores.length, 1);
  for (var i = 1; i < scores.length; i++) {
    if (scores[i] > scores[i - 1]) rewards[i] = rewards[i - 1] + 1;
  }
  for (var i = scores.length - 2; i >= 0; i--) {
    if (scores[i] > scores[i + 1] && rewards[i] <= rewards[i + 1]) {
      rewards[i] = rewards[i + 1] + 1;
    }
  }
  return rewards.fold(0, (a, b) => a + b);
}
```

<!-- CODE:END -->

### Walkthrough

- `List<int>.filled(scores.length, 1)`: everyone starts with 1.
- First loop: left constraints.
- Second loop: right constraints, only raising values (`rewards[i] <= rewards[i + 1]` is the condition for needing a raise).
- `fold` sums the rewards.

## Step 5: Dry run

| index | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|---|
| score | 8 | 4 | 2 | 1 | 3 | 6 | 7 | 9 | 5 |
| after left pass | 1 | 1 | 1 | 1 | 2 | 3 | 4 | 5 | 1 |
| after right pass | 4 | 3 | 2 | 1 | 2 | 3 | 4 | 5 | 1 |

Total: 25.

## Complexity

- **Time: O(n)**: two passes.
- **Space: O(n)** for the rewards array.

## Alternative: valley expansion

Find every local minimum (valley) and expand left and right from it, assigning 1, 2, 3, ... and taking the max at peaks. Also O(n), but more code. The two-pass version is the one to write in an interview.

## Common mistakes

- A single left-to-right pass (misses decreasing runs).
- Overwriting instead of taking the `max` in the second pass.

## Follow-ups

1. **Candy (LeetCode #135):** identical, but scores may repeat. Equal neighbors impose no constraint; the strict `>` comparisons already handle that.
2. **Circular arrangement:** the first and last students are neighbors; handle with care (for example, start from the global minimum).

## What to remember

When each element has independent left and right constraints, satisfy each side in its own pass and combine with `max`.
