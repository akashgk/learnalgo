# Longest Palindromic Subsequence

**Difficulty:** Medium | **Category:** Dynamic Programming | **Pattern:** Interval DP (or LCS of the string and its reverse) | **Source:** LeetCode 516; Striver A2Z

## The problem

Return the length of the longest **subsequence** (not necessarily contiguous) that reads the same forwards and backwards.

```
"bbbab"   ->  4   ("bbbb")
"cbbd"    ->  2   ("bb")
"agbdba"  ->  5   ("abdba")
```

Do not confuse with Longest Palindromic **Substring** (AlgoExpert medium 67), where the characters must be contiguous.

## Step 1: Brute force

Every subsequence is a subset of positions: 2^n of them, each checked in O(n). Exponential.

## Step 2: Look at the two ends

Consider `s[i..j]`:

- If `s[i] == s[j]`, both ends can be the outer pair of a palindrome, wrapped around the best palindrome inside: `2 + LPS(i + 1, j - 1)`. (Using them is never worse: any palindrome inside `s[i+1..j-1]` can be extended by this pair.)
- If `s[i] != s[j]`, they cannot **both** be used as a matching pair, so at least one of them is not in the answer: `max(LPS(i + 1, j), LPS(i, j - 1))`.

Base cases: one character has LPS 1; an empty range has 0.

That is a recursion on **intervals** `(i, j)`. There are only O(n^2) intervals, and they overlap heavily: dynamic programming.

## Step 3: Fill order

`dp[i][j]` depends on `dp[i + 1][j - 1]`, `dp[i + 1][j]`, and `dp[i][j - 1]`: shorter intervals, with a **larger** `i` or a **smaller** `j`. So loop `i` from `n - 1` down to 0, and `j` from `i + 1` up to `n - 1`. Every dependency is then ready.

## Step 4: An alternative view

The LPS of `s` equals the **Longest Common Subsequence** of `s` and `reverse(s)` (AlgoExpert hard 16). It is a good sanity check and a valid interview answer if you already know LCS well. The interval DP is more direct, and it generalizes to problems like "minimum insertions to make a palindrome".

## Step 5: The code

<!-- CODE:START -->

Full source: [`longest_palindromic_subsequence.dart`](longest_palindromic_subsequence.dart) (run it with `dart run`).

```dart
// Longest Palindromic Subsequence: length of the longest subsequence that reads the same both ways.
// Interval DP: dp[i][j] = LPS length of s[i..j]. O(n^2) time, O(n^2) space (O(n) possible).

int longestPalindromeSubseq(String s) {
  final n = s.length;
  if (n == 0) return 0;
  final dp = List.generate(n, (_) => List<int>.filled(n, 0));
  for (var i = n - 1; i >= 0; i--) {
    dp[i][i] = 1;
    for (var j = i + 1; j < n; j++) {
      if (s[i] == s[j]) {
        dp[i][j] = dp[i + 1][j - 1] + 2; // both ends wrap the best inner palindrome (dp is 0 when empty)
      } else {
        dp[i][j] = dp[i + 1][j] > dp[i][j - 1] ? dp[i + 1][j] : dp[i][j - 1]; // drop one end
      }
    }
  }
  return dp[0][n - 1];
}
```

<!-- CODE:END -->

### Walkthrough

- `dp[i][i] = 1` is set as each row starts.
- When `j == i + 1` and the characters match, `dp[i + 1][j - 1]` is `dp[i + 1][i]`, an "empty interval" cell that is 0 because it was never written. So the formula gives 2, correct for two equal characters.

## Step 6: Dry run

`"bbbab"` (indices 0..4). `dp[i][j]`:

| i \ j | 0 | 1 | 2 | 3 | 4 |
|---|---|---|---|---|---|
| 0 | 1 | 2 | 3 | 3 | **4** |
| 1 | | 1 | 2 | 2 | 3 |
| 2 | | | 1 | 1 | 3 |
| 3 | | | | 1 | 1 |
| 4 | | | | | 1 |

- `dp[2][4]`: `s[2] = b`, `s[4] = b`, match: `2 + dp[3][3] = 3` ("bab").
- `dp[0][3]`: `b` vs `a`, no match: `max(dp[1][3], dp[0][2]) = max(2, 3) = 3`.
- `dp[0][4]`: `b` and `b` match: `2 + dp[1][3] = 4` ("bbbb").

## Complexity

- Time: **O(n^2)**.
- Space: **O(n^2)**; reducible to **O(n)** by keeping only row `i + 1` and the current row.

## Edge cases

- Empty string: 0 (guarded).
- All distinct characters: 1.
- Already a palindrome: n.

## Common mistakes

- Looping `i` upward (reads rows not computed yet).
- Confusing subsequence with substring.
- Forgetting the empty-interval case for adjacent equal characters.

## Follow-ups you should be ready for

1. **Minimum insertions (or deletions) to make a string a palindrome (LeetCode 1312).** `n - LPS`.
2. **Return the subsequence itself.** Walk the table from `(0, n - 1)`, taking both ends on a match and moving toward the larger neighbor otherwise.
3. **Count palindromic subsequences (LeetCode 730).** Interval DP again, with careful duplicate handling.

## What to remember

For "best subsequence inside `s[i..j]`" problems, decide what happens at the two ends, and fill the table by increasing interval length (or `i` downward, `j` upward).
