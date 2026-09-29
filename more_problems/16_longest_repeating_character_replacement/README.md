# Longest Repeating Character Replacement

**Difficulty:** Medium | **Category:** Strings | **Pattern:** Sliding window with a frequency count | **Source:** LeetCode 424; Striver A2Z, NeetCode 150

## The problem

A string of uppercase letters. You may replace at most `k` characters with any letter. Return the length of the longest substring that can be made of one repeated letter.

```
"ABAB", k = 2      ->  4    (replace both A's, or both B's)
"AABABBA", k = 1   ->  4    ("AABA" -> "AAAA")
```

## Step 1: When is a window fixable?

Take any substring. The cheapest way to make it all one letter is to keep its **most frequent** letter and replace everything else. So:

```
window is valid  <=>  length - maxFreq <= k
```

where `maxFreq` is the count of the most frequent letter in the window. "AABA": length 4, maxFreq 3, needs 1 replacement.

## Step 2: Brute force

Check every substring with that formula: O(n^2) substrings, and with a running count array each check is O(26). O(26 n^2).

## Step 3: Sliding window

If a window `[left, right]` is valid, every window inside it is valid too (fewer characters to replace, at most as many). That is the property that makes a sliding window correct: extend `right` one step at a time; when the window becomes invalid, advance `left`.

The standard version shrinks with a `while` loop until the window is valid again. That works, but recomputing the true `maxFreq` after a shrink costs O(26).

## Step 4: The subtle optimization: never shrink, and let maxFreq go stale

We only care about windows **longer than the best found so far**. A longer valid window needs `length - maxFreq <= k` with a larger length, so it needs a **larger maxFreq** than any seen before. Therefore:

1. `maxFreq` never needs to decrease. If it is stale (too high for the current window), the window may be "wrongly" considered valid, but that window's length is never longer than `best`, so the answer is unaffected.
2. When the window is invalid, move `left` **once** (not in a loop). The window then **slides** at its current size instead of shrinking. The size only grows when a new, higher `maxFreq` appears.

The final answer is the largest size the window ever had.

## Step 5: The code

<!-- CODE:START -->

Full source: [`longest_repeating_character_replacement.dart`](longest_repeating_character_replacement.dart) (run it with `dart run`).

```dart
// Longest Repeating Character Replacement: replace at most k characters (uppercase A-Z)
// to get the longest run of one letter. Sliding window: a window is valid when
// windowLength - (count of its most frequent letter) <= k. O(n) time, O(1) space (26 counters).

int characterReplacement(String s, int k) {
  final count = List<int>.filled(26, 0);
  var left = 0, maxFreq = 0, best = 0;
  for (var right = 0; right < s.length; right++) {
    final c = s.codeUnitAt(right) - 65;
    count[c]++;
    if (count[c] > maxFreq) maxFreq = count[c];
    // Too many letters to replace: slide the window by one (it never shrinks below best).
    if (right - left + 1 - maxFreq > k) {
      count[s.codeUnitAt(left) - 65]--;
      left++;
    }
    if (right - left + 1 > best) best = right - left + 1;
  }
  return best;
}
```

<!-- CODE:END -->

### Walkthrough

- `count` is the frequency of each letter inside the window.
- `maxFreq` is the highest count ever seen in any window (it never decreases).
- The `if` (not `while`) slides the window by one when it is too big.
- `best` records the window size; since the window never shrinks, `best` equals the final window size too.

## Step 6: Dry run

`"AABABBA"`, k = 1:

| right | char | maxFreq | window after step | action | best |
|---|---|---|---|---|---|
| 0 | A | 1 | A | | 1 |
| 1 | A | 2 | AA | | 2 |
| 2 | B | 2 | AAB | | 3 |
| 3 | A | 3 | AABA | | 4 |
| 4 | B | 3 | ABAB | 5 - 3 > 1, slide | 4 |
| 5 | B | 3 | BABB | 5 - 3 > 1, slide | 4 |
| 6 | A | 3 | ABBA | 5 - 3 > 1, slide | 4 |

At right = 6 the window "ABBA" has true maxFreq 2 and needs 2 replacements, so it is actually invalid, but `maxFreq` is stale at 3. It does not matter: its size is 4, no larger than `best`.

## Complexity

- Time: **O(n)**.
- Space: **O(1)** (26 counters).

## Edge cases

- Empty string: 0.
- `k >= length`: the whole string.
- `k = 0`: longest run of one letter.

## Common mistakes

- Recomputing `maxFreq` from scratch every step (O(26n), acceptable, but explain the stale trick if asked for O(n)).
- Using a `while` shrink loop with a stale `maxFreq`: the loop condition may never become true in the way you expect. Either recompute maxFreq, or slide by one.
- Counting "number of distinct letters" instead of "length minus the most frequent count".

## Follow-ups you should be ready for

1. **Max Consecutive Ones III (LeetCode 1004).** Binary alphabet, flip at most k zeros: the window is valid while it has at most k zeros. Same template, simpler.
2. **Longest substring with at most k distinct characters (LeetCode 340).** Window valid while the distinct count is <= k.
3. **Lowercase or any characters.** Use a map instead of 26 counters.

## What to remember

Express "the window is fixable" as a formula over counts. For "longest valid window", the window never has to shrink: slide it at its best size and grow only when a better window becomes possible.
