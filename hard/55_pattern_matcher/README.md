# Pattern Matcher

**Difficulty:** Hard | **Category:** Strings | **Pattern:** Enumerate one length, derive the other

## Problem
A pattern consists only of the characters `x` and `y`. Find non-empty strings for `x` and `y` (y may be empty only if the pattern has no `y`) such that replacing every `x` and `y` in the pattern produces the given string. Return `[x, y]`, or `[]` if impossible. If several answers exist, any is fine (here: the one with the shortest x).

```
pattern = "xxyxxy", string = "gogopowerrangergogopowerranger"  ->  ["go", "powerranger"]
```

## Building up the logic
1. Brute force over all pairs of lengths is O(n^2) pairs times O(n) to verify: O(n^3).
2. **Only one free variable:** with `cx` x's and `cy` y's, `cx * lenX + cy * lenY = n`. Choosing `lenX` determines `lenY` (if it divides evenly). So enumerate `lenX` only.
3. **Normalize:** if the pattern starts with `y`, swap the letters so it starts with `x`; then `x` is always the prefix of the string. Swap the answer back at the end.
4. `y` starts at `firstYIndex * lenX` (everything before the first y in the pattern is x's).
5. Build the candidate string and compare. O(n) per candidate.

## Complexity
- Time: O(n^2 + m): up to n candidate lengths, O(n) to build and compare each (m = pattern length).
- Space: O(n + m).

## Interview notes
- Cracking the Coding Interview 16.18. LeetCode #290 (Word Pattern) and #291 (Word Pattern II, arbitrary letters, needs backtracking) are relatives.
- The "normalize to start with x" trick halves the case analysis. Look for such normalizations in any problem with a symmetric role.
