# Wildcard Matching

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** Two-string DP over prefixes | **Source:** LeetCode 44; Striver A2Z

## The problem

Match a string `s` against a pattern `p` where `?` matches **exactly one** character and `*` matches **any sequence** of characters, including the empty one. The match must cover the **entire** string.

```
s = "aa",    p = "a"      ->  false
s = "aa",    p = "*"      ->  true
s = "adceb", p = "*a*b"   ->  true    (* = "", a, * = "dce", b)
s = "acdcb", p = "a*c?b"  ->  false
```

Different from Regular Expression Matching (LeetCode 10), where `*` repeats the **previous** character.

## Step 1: Recursion on prefixes

Let `match(i, j)` = does `p[0..j)` match `s[0..i)`? Look at the last pattern character `p[j - 1]`:

- **A letter or `?`:** it must match `s[i - 1]` (a letter must be equal; `?` matches anything), and the rest must match: `match(i - 1, j - 1)`.
- **`*`:** two choices:
  - the star matches **nothing**: `match(i, j - 1)`;
  - the star matches **one more character**, `s[i - 1]`, and **stays available** for more: `match(i - 1, j)`.

This two-way star rule avoids a loop over "how many characters does the star eat": eating k characters is "one more, then k - 1 more".

Base cases:

- `match(0, 0) = true`.
- `match(i > 0, 0) = false`: an empty pattern cannot match a non-empty string.
- `match(0, j) = true` only if `p[0..j)` is all stars.

## Step 2: Brute force

The plain recursion branches at every star: exponential for patterns like `"*a*a*a*b"`. The state is just `(i, j)`, so memoize: O(|s| * |p|) states, O(1) each.

## Step 3: Bottom-up, one row at a time

Row `i` (prefix of s of length i) needs row `i - 1` (for letters/`?` and for "star eats one more") and row `i` itself, left of `j` (for "star matches nothing"). Keep two rows: `dp` for row `i - 1` and `next` for row `i`, filling `next` left to right.

## Step 4: The code

<!-- CODE:START -->

Full source: [`wildcard_matching.dart`](wildcard_matching.dart) (run it with `dart run`).

```dart
// Wildcard Matching: '?' matches any one character, '*' matches any sequence (including empty).
// The pattern must match the whole string. DP over prefixes. O(|s| * |p|) time, O(|p|) space.

bool isMatch(String s, String p) {
  final m = p.length;
  // dp[j]: does p[0..j) match the current prefix of s?
  var dp = List<bool>.filled(m + 1, false);
  dp[0] = true;
  for (var j = 1; j <= m; j++) {
    dp[j] = dp[j - 1] && p[j - 1] == '*'; // only stars can match the empty string
  }
  for (var i = 1; i <= s.length; i++) {
    final next = List<bool>.filled(m + 1, false); // next[0] = false: empty pattern vs non-empty s
    for (var j = 1; j <= m; j++) {
      final pc = p[j - 1];
      if (pc == '*') {
        // Star matches nothing (next[j - 1]) or absorbs s[i - 1] and stays available (dp[j]).
        next[j] = next[j - 1] || dp[j];
      } else if (pc == '?' || pc == s[i - 1]) {
        next[j] = dp[j - 1];
      }
    }
    dp = next;
  }
  return dp[m];
}
```

<!-- CODE:END -->

### Walkthrough

- The first loop computes row 0: a pattern prefix matches the empty string only while it consists of stars.
- `next[0]` stays false for every non-empty prefix of s.
- For `*`: `next[j] = next[j - 1] || dp[j]`, the "matches nothing" and "eats one more" cases.
- For a letter or `?`: `next[j] = dp[j - 1]`. A mismatching letter leaves `false`.

## Step 5: Dry run

`s = "adceb"`, `p = "*a*b"`. Columns are pattern prefixes `"", "*", "*a", "*a*", "*a*b"`:

| s prefix | "" | * | *a | *a* | *a*b |
|---|---|---|---|---|---|
| "" | 1 | 1 | 0 | 0 | 0 |
| a | 0 | 1 | 1 | 1 | 0 |
| ad | 0 | 1 | 0 | 1 | 0 |
| adc | 0 | 1 | 0 | 1 | 0 |
| adce | 0 | 1 | 0 | 1 | 0 |
| adceb | 0 | 1 | 0 | 1 | **1** |

The second star absorbs "dce" (the `*a*` column stays true), and the final `b` matches.

## Complexity

- Time: **O(|s| * |p|)**.
- Space: **O(|p|)** with two rows.

## Edge cases

- Both empty: true.
- Empty string, pattern of only stars: true.
- Consecutive stars behave like one star (the DP handles them without special code; you may also collapse them first).

## Common mistakes

- Letting `*` match only one or more characters (it can match zero).
- Forgetting to initialize row 0 for leading stars.
- Mixing up with regex `*` semantics.

## Follow-ups you should be ready for

1. **Greedy O(1)-space solution.** Two pointers, remembering the position of the last star and where in s it started; on a mismatch, backtrack to "let the last star eat one more character". O(|s| * |p|) worst case, usually much faster, and it is a known interview favorite once the DP is done.
2. **Regular Expression Matching (LeetCode 10).** `*` applies to the previous character: `match(i, j)` looks at `p[j - 2]`.
3. **Return the matched segments.** Store choices during the DP and backtrack.

## What to remember

For pattern matching, define `match(i, j)` on prefixes and handle the last pattern character. A star has two options: match nothing, or eat one character and stay.
