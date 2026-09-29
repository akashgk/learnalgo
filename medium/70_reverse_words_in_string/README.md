# Reverse Words In String

**Difficulty:** Medium | **Category:** Strings | **Pattern:** Tokenize and reverse (or reverse twice)

## Problem
Reverse the order of words in a string, where words are separated by one or more spaces. Whitespace must be preserved exactly: `"whitespaces    4"` becomes `"4    whitespaces"`. Do not use built-in split or reverse helpers (the point is to implement the logic).

## Building up the logic
1. If whitespace did not matter, you would split on spaces and join in reverse. Here the space **runs** are data too.
2. Treat both words and space runs as tokens. A token boundary is where "is space" flips between consecutive characters.
3. Reverse the token list and join. Space runs stay between the same neighbors, just mirrored.
4. **In-place alternative** (for a mutable char array, the classic follow-up): reverse the whole string, then reverse each word back. `"the sky"` -> `"yks eht"` -> `"sky the"`. O(1) extra space in languages with mutable strings.

## Complexity
- Time: O(n).
- Space: O(n).

## Interview notes
- LeetCode #151 normalizes whitespace (single spaces, trimmed), which is a different requirement. Always ask whether whitespace must be preserved.
- The "reverse all, then reverse each part" trick also solves Rotate Array (#189).
