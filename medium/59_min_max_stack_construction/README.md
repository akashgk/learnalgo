# Min Max Stack Construction

**Difficulty:** Medium | **Category:** Stacks | **Pattern:** Augmenting each stack entry with aggregate state

## Problem
Implement a stack with `push`, `pop`, `peek`, `getMin`, and `getMax`, all in constant time.

## Building up the logic
1. Scanning for min/max on demand is O(n). Keeping a single `min` variable fails after popping the minimum: what is the new minimum?
2. A stack only changes at the top, so the min/max **below** any element never change while that element is on the stack.
3. Therefore store, with each pushed element, the min and max of the stack at that moment. After a pop, the new top already knows the correct min and max.
4. Space optimization: keep a separate min-stack that only receives a value when it is `<=` the current min (and pops when the popped value equals its top). Same for max. Saves memory when the extremes rarely change.

## Complexity
- Time: O(1) for every operation.
- Space: O(n).

## Interview notes
- LeetCode #155 (Min Stack). A related constant-space trick stores `2 * value - min` encodings; it is clever but fragile with overflow, so mention rather than code it.
- Dart note: named-field records `({int value, int min, int max})` are a clean way to bundle per-entry state.
