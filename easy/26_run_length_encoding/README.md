# Run-Length Encoding

**Difficulty:** Easy | **Category:** Strings | **Pattern:** Run tracking in one pass

## Problem
Encode a non-empty string with run-length encoding: each run of identical characters becomes `<length><char>`. Runs longer than 9 must be split (`"AAAAAAAAAAAA"` -> `"9A3A"`), because otherwise `"12A"` would be ambiguous: twelve A's, or one `'1'` followed by two A's. Input may contain any characters, including digits.

## Building up the logic
1. Track the length of the current run.
2. A run ends when: the next char differs, the run hits 9, or the string ends.
3. Handle the end-of-string flush inside the loop by iterating to `i == length`; this avoids the classic "forgot the last run" bug.
4. Use a `StringBuffer` (StringBuilder in Java) for O(n) building.

## Complexity
- Time: O(n).
- Space: O(n) for the output.

## Edge cases
- Digits in the input (`"122333"` -> `"112233"`), which is exactly why the 9-cap exists.
- Case sensitivity (`'a'` != `'A'`).

## Interview notes
- Decoding is the natural follow-up; with the 9-cap, each pair is exactly one digit then one char.
- Related: LeetCode #443 (String Compression, in place).
