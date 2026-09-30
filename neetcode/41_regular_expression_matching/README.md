# Regular Expression Matching

**Difficulty:** Hard | **Category:** 2-D Dynamic Programming | **Pattern:** Two-string DP with a lookahead for `*` | **Source:** LeetCode 10; NeetCode 150

## The problem

Implement matching where `.` matches any single character and `x*` matches **zero or more** of the preceding element `x` (which may itself be `.`). The pattern must match the **entire** string.

```
"aa",  "a"         ->  false
"aa",  "a*"        ->  true
"ab",  ".*"        ->  true
"aab", "c*a*b"     ->  true    (c* matches nothing, a* matches "aa")
"mississippi", "mis*is*p*."  ->  false
```

Different from Wildcard Matching (more_problems 42), where `*` matches any sequence by itself.

## Step 1: Recursion on suffixes

Let `match(i, j)` = does `s[i..]` match `p[j..]`?

Let `firstMatches = i < |s| and (p[j] == '.' or p[j] == s[i])`.

- If `p[j + 1]` is `*` (the element `p[j]` is starred):
  - use it **zero times**: skip both pattern characters: `match(i, j + 2)`;
  - or use it **once more**: `firstMatches and match(i + 1, j)` (the `x*` stays available).
- Otherwise: `firstMatches and match(i + 1, j + 1)`.

Base case: `match(|s|, |p|) = true`. When the pattern is exhausted but the string is not, false. When the string is exhausted, the pattern can still match if it is a sequence of starred elements (handled by the zero-times branch).

**Look ahead, not behind:** decide what `p[j]` does by checking whether `p[j + 1]` is `*`. That way `*` is always processed together with its element.

## Step 2: Memoize, or fill a table

The state is `(i, j)`: O(|s| * |p|) states, O(1) each. Bottom-up, fill `dp[i][j]` from `i = |s|` down to 0 and `j = |p| - 1` down to 0, since each cell reads larger `i` or `j`.

## Step 3: The code

<!-- CODE:START -->

Full source: [`regular_expression_matching.dart`](regular_expression_matching.dart) (run it with `dart run`).

```dart
// Regular Expression Matching: '.' matches any single character; 'x*' matches zero or more of the
// preceding element x. The pattern must match the whole string.
// dp[i][j] = s[i..] matches p[j..] (suffix DP). O(|s| * |p|) time and space.

bool isMatch(String s, String p) {
  final m = s.length, n = p.length;
  final dp = List.generate(m + 1, (_) => List<bool>.filled(n + 1, false));
  dp[m][n] = true; // empty string matches empty pattern
  for (var i = m; i >= 0; i--) {
    for (var j = n - 1; j >= 0; j--) {
      final firstMatches = i < m && (p[j] == '.' || p[j] == s[i]);
      if (j + 1 < n && p[j + 1] == '*') {
        // "x*": use it zero times (skip both pattern chars), or consume one s char and stay on "x*".
        dp[i][j] = dp[i][j + 2] || (firstMatches && dp[i + 1][j]);
      } else {
        dp[i][j] = firstMatches && dp[i + 1][j + 1];
      }
    }
  }
  return dp[0][0];
}
```

<!-- CODE:END -->

### Walkthrough

- The table has an extra row and column for the empty suffixes; `dp[m][n] = true`.
- Row `i = m` (empty string) is computed too: a pattern like `a*b*` matches it through the zero-times branch.
- `firstMatches` guards `i < m` before reading `s[i]`.

## Step 4: Dry run

`s = "aab"`, `p = "c*a*b"`. Rows are string suffixes (`i`), columns pattern suffixes (`j`), 1 = true:

| i \ j | 0 `c*a*b` | 1 `*a*b` | 2 `a*b` | 3 `*b` | 4 `b` | 5 `` |
|---|---|---|---|---|---|---|
| 0 `aab` | **1** | 0 | 1 | 0 | 0 | 0 |
| 1 `ab` | 1 | 0 | 1 | 0 | 0 | 0 |
| 2 `b` | 1 | 0 | 1 | 0 | 1 | 0 |
| 3 `` | 0 | 0 | 0 | 0 | 0 | 1 |

Columns 1 and 3 start with `*`; they are never the start of a valid pattern suffix and stay false. `dp[0][0]` is true: `c*` matches nothing, `a*` eats `aa`, `b` matches `b`.

## Complexity

- Time: **O(|s| * |p|)**.
- Space: **O(|s| * |p|)** (O(|p|) with two rows).

## Edge cases

- Empty string with pattern `a*b*`: true.
- Pattern `.*` matches anything.
- `.*c` against `"ab"`: false (the `c` must match at the end).

## Common mistakes

- Treating `*` as a standalone wildcard.
- Handling `*` when reaching it instead of when reaching its element (leads to messy index juggling).
- Forgetting that a starred element may match zero times.

## Follow-ups you should be ready for

1. **Add `+` (one or more).** `x+` is `x x*`.
2. **Real regex engines.** They compile to an NFA (Thompson construction) and simulate it, avoiding exponential backtracking on patterns like `(a*)*b`.
3. **Wildcard Matching.** more_problems 42.

## What to remember

Match suffix by suffix; look ahead for `*`. A starred element either disappears (`j + 2`) or consumes one character and stays (`i + 1`, same `j`).
