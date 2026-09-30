# Palindromic Substrings

**Difficulty:** Medium | **Category:** 1-D Dynamic Programming | **Pattern:** Expand around centers | **Source:** LeetCode 647; NeetCode 150, Blind 75

## The problem

Count the substrings of `s` that are palindromes. Substrings at different positions count separately, even if they are equal.

```
"abc"  ->  3   (a, b, c)
"aaa"  ->  6   (a, a, a, aa, aa, aaa)
```

## Step 1: Brute force

Check every substring: O(n^2) substrings, each checked in O(n): **O(n^3)**.

## Step 2: Share work between checks

Checking `s[i..j]` from scratch ignores that it is a palindrome exactly when `s[i] == s[j]` and `s[i+1..j-1]` is a palindrome. Two ways to exploit that:

**DP table:** `isPal[i][j]` filled by increasing length, O(n^2) time and O(n^2) space.

**Expand around centers:** every palindrome has a **center**: a character (odd length) or a gap between two characters (even length). There are `2n - 1` centers. From each center, expand outward while the two ends match; **every successful expansion is one more palindrome**. When the ends stop matching, no wider palindrome exists around that center. O(n^2) time, **O(1) space**.

## Step 3: Encoding the centers

Use one loop variable `center` from 0 to `2n - 2`:

- even `center`: the character at `center / 2` (odd-length palindromes), start with `lo = hi = center / 2`;
- odd `center`: the gap after `center / 2` (even-length), start with `lo = center / 2`, `hi = lo + 1`.

`hi = lo + center % 2` handles both in one line.

## Step 4: The code

<!-- CODE:START -->

Full source: [`palindromic_substrings.dart`](palindromic_substrings.dart) (run it with `dart run`).

```dart
// Palindromic Substrings: count substrings (by position) that are palindromes.
// Expand around each of the 2n - 1 centers (every character, and every gap between characters).
// O(n^2) time, O(1) space.

int countSubstrings(String s) {
  var count = 0;
  for (var center = 0; center < 2 * s.length - 1; center++) {
    // Even centers sit on a character (odd length); odd centers sit between two (even length).
    var lo = center ~/ 2, hi = lo + center % 2;
    while (lo >= 0 && hi < s.length && s[lo] == s[hi]) {
      count++; // s[lo..hi] is a palindrome; try one step wider
      lo--;
      hi++;
    }
  }
  return count;
}
```

<!-- CODE:END -->

### Walkthrough

- `count++` happens once per successful expansion: each is a distinct `(lo, hi)` pair, so a distinct substring position.
- The `while` stops at the first mismatch or the string boundary.

## Step 5: Dry run

`"aaa"`:

| center | start (lo, hi) | palindromes found |
|---|---|---|
| 0 | (0, 0) | a |
| 1 | (0, 1) | aa |
| 2 | (1, 1) | a, aaa |
| 3 | (1, 2) | aa |
| 4 | (2, 2) | a |

Total **6**.

## Complexity

- Time: **O(n^2)** worst case (all equal characters); faster when palindromes are short.
- Space: **O(1)**.
- Manacher's algorithm counts all palindromes in O(n); worth naming, rarely expected.

## Edge cases

- Empty string: 0 (the loop runs zero times since `2 * 0 - 1 < 0`).
- All distinct characters: n.

## Common mistakes

- Only odd-length centers (misses "aa").
- Counting distinct palindromic strings instead of positions (a different problem).

## Follow-ups you should be ready for

1. **Longest Palindromic Substring.** Same expansion, track the longest; AlgoExpert medium 67.
2. **Palindrome Partitioning.** Precompute the palindrome table; more_problems 27.
3. **Count distinct palindromic substrings.** A palindromic tree (eertree), or hashing.

## What to remember

There are 2n - 1 palindrome centers. Expanding from each one enumerates every palindrome exactly once, in O(1) space.
