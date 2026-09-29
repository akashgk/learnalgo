# Single Cycle Check

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** Functional graph traversal, counting

## Problem
Each element of an integer array is a jump: from index `i` you move `array[i]` positions (negative moves backward) with wrap-around. Return whether following jumps from any index visits every index exactly once and returns to the start (a single cycle through all elements).

## Building up the logic
1. Every index has exactly one outgoing edge: this is a **functional graph**. A single cycle covering all n nodes means that starting at index 0, after exactly n jumps you are back at 0, and you did not see 0 in between.
2. Why is that sufficient? If you return to 0 only at jump n, then the first n positions were n distinct indices (a repeat of any other index before returning to 0 would trap you in a cycle not containing 0, so you would never return). n distinct indices out of n means every index was visited.
3. Wrap-around: `(idx + jump) % n`. In Java/C++ `%` can be negative; fix with `((x % n) + n) % n`. Dart's `%` is already non-negative for positive `n`.

## Complexity
- Time: O(n).
- Space: O(1): no visited array needed thanks to the counting argument.

## Interview notes
- The counting argument (instead of a visited set) is what the interviewer is looking for. Explain it; do not just code it.
- Related: LeetCode #457 (Circular Array Loop).
