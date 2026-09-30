# Jump Game

**Difficulty:** Medium | **Category:** Greedy | **Pattern:** Track the farthest reachable index | **Source:** LeetCode 55; NeetCode 150, Blind 75

## The problem

`nums[i]` is the **maximum** jump length from index `i` (any shorter jump is allowed too). Starting at index 0, can you reach the last index?

```
[2, 3, 1, 1, 4]  ->  true
[3, 2, 1, 0, 4]  ->  false   (every route lands on the 0 at index 3)
```

AlgoExpert hard 17 Min Number Of Jumps asks for the minimum number of jumps (Jump Game II); this asks only whether it is possible.

## Step 1: Brute force and DP

- DFS over all jump choices: exponential.
- DP: `canReach[i]` is true if some earlier reachable `j` has `j + nums[j] >= i`: O(n^2).

## Step 2: The reachable set is always a prefix

If you can reach index `i`, you can reach every index before it too (you passed through or jumped over them, and jumps can be shorter). So the set of reachable indices is always `0..farthest`. One number describes it.

Scan left to right:

- if `i > farthest`, index `i` is unreachable, and so is everything after it: return false;
- otherwise update `farthest = max(farthest, i + nums[i])`;
- once `farthest >= last index`, return true.

## Step 3: The code

<!-- CODE:START -->

Full source: [`jump_game.dart`](jump_game.dart) (run it with `dart run`).

```dart
// Jump Game: nums[i] is the maximum jump length from index i. Can you reach the last index from 0?
// Greedy: track the farthest index reachable so far; if the scan ever passes it, you are stuck.
// O(n) time, O(1) space.

bool canJump(List<int> nums) {
  var farthest = 0;
  for (var i = 0; i < nums.length; i++) {
    if (i > farthest) return false; // index i itself cannot be reached
    final reach = i + nums[i];
    if (reach > farthest) farthest = reach;
    if (farthest >= nums.length - 1) return true;
  }
  return true;
}
```

<!-- CODE:END -->

### Walkthrough

- The check `i > farthest` comes first: only reachable indices may extend the reach.
- The early `return true` avoids scanning the rest.

## Step 4: Dry run

`[3, 2, 1, 0, 4]`:

| i | nums[i] | reachable? | farthest after |
|---|---|---|---|
| 0 | 3 | yes | 3 |
| 1 | 2 | yes | 3 |
| 2 | 1 | yes | 3 |
| 3 | 0 | yes | 3 |
| 4 | 4 | 4 > 3: **no** | return false |

## Complexity

- Time: **O(n)**.
- Space: **O(1)**.

## Edge cases

- One element: true (already at the end).
- `[0, ...]` with more elements: false.
- Zeros that can be jumped over: fine.

## Common mistakes

- Always taking the maximum jump (overshooting a good landing spot is fine here, but greedy "jump max" can land on a 0: `[2, 5, 0, 0]` jumping 2 lands on 0, while jumping 1 reaches 5).
- Forgetting the unreachable check.

## Follow-ups you should be ready for

1. **Jump Game II (minimum jumps).** BFS by "levels" of reach: AlgoExpert hard 17.
2. **Backwards greedy.** Keep a `goal` starting at the last index; moving left, if `i + nums[i] >= goal`, set `goal = i`. Reachable if `goal` ends at 0.
3. **Jump Game III (LeetCode 1306).** Jumps of exactly `nums[i]` left or right: BFS/DFS.

## What to remember

When reachability is always a prefix, one variable (the farthest reachable index) replaces a DP table.
