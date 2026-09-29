# Phone Number Mnemonics

**Difficulty:** Medium | **Category:** Recursion | **Pattern:** Backtracking over a fixed-length slot array

## Problem
On a phone keypad, digits 2-9 map to letters (2: abc, 3: def, ..., 7: pqrs, 9: wxyz); 0 and 1 map to themselves. Given a string of digits, return every possible mnemonic (one character per digit), in any order.

## Building up the logic
1. The output is the Cartesian product of the per-digit letter lists.
2. Recursion: fill slot `i` with each letter for digit `i`, then fill slot `i + 1`. When all slots are filled, record the string.
3. A fixed-size slot array means "undo" is automatic: the next loop iteration overwrites slot `i`.
4. Iterative alternative: start with `[""]` and, for each digit, extend every partial string with each letter (BFS-style).

## Complexity
- Time: O(4^n * n): at most 4 choices per digit, and each finished string costs O(n) to build.
- Space: O(4^n * n) output; O(n) recursion.

## Interview notes
- LeetCode #17 (Letter Combinations of a Phone Number). Note the difference: LeetCode excludes 0 and 1; clarify.
