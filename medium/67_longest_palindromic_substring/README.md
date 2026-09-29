# Longest Palindromic Substring

**Difficulty:** Medium | **Category:** Strings | **Pattern:** Expand around center

## The problem

Return the longest substring of a string that is a palindrome (reads the same forward and backward). Assume a unique answer.

```
"abaxyzzyxf"     ->  "xyzzyx"
"it's highnoon"  ->  "noon"
"a"              ->  "a"
```

## Step 1: Brute force

Check every substring (O(n^2) of them) with a palindrome check (O(n)): **O(n^3)**.

## Step 2: Observe the structure of palindromes

Every palindrome is symmetric around its **center**. If you know the center, you can grow the palindrome outward one character on each side as long as the two new characters match.

Where can centers be?

- On a character (odd length): `"aba"`, center `b`.
- Between two characters (even length): `"abba"`, center between the two `b`s.

A string of length n has n character centers and n - 1 gap centers: **2n - 1 centers**.

## Step 3: Expand around each center

For each center, expand while the ends match, and remember the widest palindrome found. Each expansion is O(n) at worst, and there are 2n - 1 centers: **O(n^2) time, O(1) space**.

## Step 4: DP alternative

`P[i][j]` = "substring `i..j` is a palindrome" = `s[i] == s[j]` and `P[i+1][j-1]`. Fill by increasing length. Also O(n^2) time, but **O(n^2) space**. Useful when you need to answer "is `s[i..j]` a palindrome?" for many pairs (see Palindrome Partitioning Min Cuts, very hard 13).

## Step 5: The code

<!-- CODE:START -->

Full source: [`longest_palindromic_substring.dart`](longest_palindromic_substring.dart) (run it with `dart run`).

```dart
// Longest Palindromic Substring: expand around each of the 2n - 1 centers.
// O(n^2) time, O(1) space.

String longestPalindromicSubstring(String string) {
  if (string.isEmpty) return '';
  var bestLo = 0, bestHi = 0; // inclusive bounds of the best palindrome

  (int, int) expand(int lo, int hi) {
    while (lo >= 0 && hi < string.length && string[lo] == string[hi]) {
      lo--;
      hi++;
    }
    return (lo + 1, hi - 1);
  }

  for (var i = 0; i < string.length; i++) {
    for (final (lo, hi) in [expand(i, i), expand(i, i + 1)]) {
      // odd and even centers
      if (hi - lo > bestHi - bestLo) (bestLo, bestHi) = (lo, hi);
    }
  }
  return string.substring(bestLo, bestHi + 1);
}
```

<!-- CODE:END -->

### Walkthrough

- `expand(lo, hi)` grows while `string[lo] == string[hi]`, then returns the last valid bounds `(lo + 1, hi - 1)`. It returns a Dart record.
- For each `i`, `expand(i, i)` handles odd centers and `expand(i, i + 1)` handles even centers.
- `(bestLo, bestHi) = (lo, hi)` updates both bounds at once with a record assignment.
- `substring(bestLo, bestHi + 1)` builds the result once, at the end.

## Step 6: Dry run: finding "xyzzyx" in "abaxyzzyxf"

Indices: `a0 b1 a2 x3 y4 z5 z6 y7 x8 f9`. The even center between index 5 and 6:

| lo | hi | chars | match? |
|---|---|---|---|
| 5 | 6 | z, z | yes |
| 4 | 7 | y, y | yes |
| 3 | 8 | x, x | yes |
| 2 | 9 | a, f | no, stop |

Returns bounds (3, 8): `"xyzzyx"`, length 6. The odd centers find only shorter palindromes (for example `"aba"` around index 1).

## Complexity

| Approach | Time | Space |
|---|---|---|
| Brute force | O(n^3) | O(1) |
| DP table | O(n^2) | O(n^2) |
| Expand around center | O(n^2) | O(1) |
| Manacher's algorithm | O(n) | O(n) |

Manacher's algorithm reuses the symmetry of already-found palindromes to skip redundant expansions. You are rarely expected to code it; mentioning it shows depth.

## Common mistakes

- Forgetting even-length centers (`"abba"` would return `"a"`).
- Off-by-one when converting the final expansion bounds (the loop exits one step too far on each side).
- Creating substrings inside the loop (extra O(n) per step).

## Follow-ups

1. **Longest Palindromic Substring (LeetCode #5):** identical.
2. **Palindromic Substrings (#647):** count all palindromic substrings with the same expansion (add the number of successful expansion steps).
3. **Longest Palindromic Subsequence (#516):** not contiguous, so it is a different DP: `L[i][j] = L[i+1][j-1] + 2` if the ends match, else `max(L[i+1][j], L[i][j-1])`.

## What to remember

Palindromes grow from centers; there are 2n - 1 centers (characters and gaps). Expand from each.
