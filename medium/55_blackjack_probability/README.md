# Blackjack Probability

**Difficulty:** Medium | **Category:** Recursion | **Pattern:** Probability DP with memoization

## Problem
A dealer draws cards valued 1 to 10, each equally likely (infinite deck). The dealer must draw while their hand is below `target - 4` and stops as soon as it is at least `target - 4`. The dealer busts if the hand exceeds `target`. Given `target` and `startingHand`, return the probability of busting, rounded to 3 decimals.

## Building up the logic
1. Define `P(h)` = probability of busting from hand `h`.
2. Terminal states: `h > target` -> 1; `target - 4 <= h <= target` -> 0 (dealer stands).
3. Otherwise the next card is 1..10 with probability 1/10 each: `P(h) = (P(h+1) + ... + P(h+10)) / 10`.
4. Many paths reach the same hand value (e.g. 3+4 and 4+3), so memoize by hand value.
5. Round only at the very end; rounding intermediate values accumulates error.

## Complexity
- Time: O(target) states, each doing 10 constant-time lookups: O(target).
- Space: O(target) memo plus recursion depth.

## Interview notes
- Any "expected value / probability over a process with repeated states" problem is a DP over states. Related: LeetCode #837 (New 21 Game), which needs the sliding-window sum trick from Staircase Traversal to get O(n).
