# Best Digits

**Difficulty:** Medium | **Category:** Stacks | **Pattern:** Monotonic stack (greedy digit removal)

## Problem
Given a string of digits and an integer `numDigits`, remove exactly `numDigits` digits (keeping the remaining order) to form the largest possible number. Return it as a string.

```
"462839", remove 2  ->  "6839"
```

## Building up the logic
1. Brute force: try all C(n, k) removals. Exponential.
2. **Greedy insight:** the leftmost digits matter most. If a digit is followed by a bigger digit, removing the smaller one makes the number bigger at that position, and nothing to the right can compensate for a smaller leading digit.
3. So scan left to right with a stack. While removals remain and the stack top is **smaller** than the incoming digit, pop it.
4. After the scan the stack is non-increasing. Any removals still owed come off the end, where the smallest digits sit.

## Complexity
- Time: O(n): each digit is pushed and popped at most once.
- Space: O(n).

## Interview notes
- Mirror of LeetCode #402 (Remove K Digits), which asks for the **smallest** number: pop while the top is **larger**, then strip leading zeros. Know both directions.
- Related harder variant: #321 (Create Maximum Number) combines this with merging.
