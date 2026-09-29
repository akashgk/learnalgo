# Sunset Views

**Difficulty:** Medium | **Category:** Stacks | **Pattern:** Running maximum from one side (or monotonic stack)

## Problem
Given building heights in a row (index 0 is the westmost) and a direction (`"EAST"` or `"WEST"`) that all buildings face, return the indices of buildings that can see the sunset, sorted ascending. A building sees the sunset if it is strictly taller than every building between it and the sun in the direction it faces.

## Building up the logic
1. Brute force: for each building, check all buildings in front of it. O(n^2).
2. Scan **from the sun's side**. A building can see the sunset iff it is taller than the running maximum of everything already scanned (everything between it and the sun).
3. Facing east, the sun is on the right: scan right to left, then reverse the collected indices. Facing west: scan left to right.

## Alternative: monotonic stack
Scan in the facing direction's opposite order and keep a stack of candidates; pop any candidate that is not taller than the new building (it is now blocked). The stack ends up holding the answer. Same O(n); useful when the input is a stream that arrives from the far side.

## Complexity
- Time: O(n).
- Space: O(n) for the output (O(1) extra for the running-max version).

## Interview notes
- LeetCode #1762 (Buildings With an Ocean View).
- The monotonic stack generalization is the backbone of Next Greater Element and Largest Rectangle Under Skyline. Make sure you understand both views here.
