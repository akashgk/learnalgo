# Distinct Subsequences

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** Two-string DP (counting) | **Source:** LeetCode 115; Striver A2Z, NeetCode 150

## The problem

Count the number of distinct ways to choose positions in `s` whose characters spell `t` in order. Two ways are different if they use a different set of positions.

```
s = "rabbbit", t = "rabbit"  ->  3    (drop any one of the three b's)
s = "babgbag", t = "bag"     ->  5
```

## Step 1: Think about the last characters

Let `ways(i, j)` = number of ways to form `t[0..j)` (the first `j` characters of t) from `s[0..i)` (the first `i` characters of s). Look at `s[i - 1]`, the last character available:

- **Skip it:** every way to form `t[0..j)` from `s[0..i-1)` still works: `ways(i - 1, j)`.
- **Use it** as the last character of t, possible only if `s[i - 1] == t[j - 1]`: then the rest of t must come from the earlier part of s: `ways(i - 1, j - 1)`.

These two groups never overlap (one uses position `i - 1`, the other does not), so we **add** them:

```
ways(i, j) = ways(i-1, j) + (s[i-1] == t[j-1] ? ways(i-1, j-1) : 0)
```

Base cases:

- `ways(i, 0) = 1`: the empty t is formed exactly one way (choose nothing).
- `ways(0, j > 0) = 0`: nothing can be formed from an empty s.

## Step 2: Brute force

Enumerate all C(|s|, |t|) position sets. Exponential. The recursion above without memoization is also exponential.

## Step 3: Table, then one row

The full table is `(|s| + 1) x (|t| + 1)`. Row `i` only reads row `i - 1`, so one array `dp[j]` suffices if we update `j` **from high to low**. That way, `dp[j - 1]` still holds the value from row `i - 1` when `dp[j]` reads it. (Same reason as the backward loop in 0/1 knapsack, more_problems 39.)

## Step 4: The code

<!-- CODE:START -->

Full source: [`distinct_subsequences.dart`](distinct_subsequences.dart) (run it with `dart run`).

```dart
// Distinct Subsequences: number of distinct ways (index sets) to pick t as a subsequence of s.
// dp[i][j] = ways to form t[0..j) from s[0..i). O(|s| * |t|) time, O(|t|) space with a 1-D row.

int numDistinct(String s, String t) {
  final m = t.length;
  final dp = List<int>.filled(m + 1, 0);
  dp[0] = 1; // one way to form the empty string: pick nothing
  for (var i = 0; i < s.length; i++) {
    // Backwards so dp[j - 1] is still the value from before s[i] was considered.
    for (var j = m; j >= 1; j--) {
      if (s[i] == t[j - 1]) dp[j] += dp[j - 1]; // use s[i] as t[j-1], or skip it (already in dp[j])
    }
  }
  return dp[m];
}
```

<!-- CODE:END -->

### Walkthrough

- `dp[0] = 1` and it never changes: the empty target always has one way.
- For each character of s, the inner loop goes backwards over t. On a match, `dp[j] += dp[j - 1]`: the "skip" part is the old `dp[j]` already in place, and the "use" part is `dp[j - 1]` from the previous row.

## Step 5: Dry run

`s = "babgbag"`, `t = "bag"`. `dp` = [ways for "", "b", "ba", "bag"] after each character of s:

| s char | dp |
|---|---|
| (start) | 1 0 0 0 |
| b | 1 1 0 0 |
| a | 1 1 1 0 |
| b | 1 2 1 0 |
| g | 1 2 1 1 |
| b | 1 3 1 1 |
| a | 1 3 4 1 |
| g | 1 3 4 **5** |

For example, at the second `a` (index 5): "ba" can now end at this a, using any of the 3 earlier b's, so `dp[2] = 1 + 3 = 4`.

## Complexity

- Time: **O(|s| * |t|)**.
- Space: **O(|t|)**.

## Edge cases

- `t` empty: 1.
- `s` shorter than `t`: 0 (the table never fills `dp[m]`).
- Many repeats (`"aaaa"`, `"aa"`): C(4, 2) = 6.

## Common mistakes

- Iterating `j` forwards in the 1-D version (uses the current character twice).
- Treating the result as the number of distinct **strings**; it counts position sets.
- Overflow: counts grow exponentially; LeetCode guarantees 32-bit answers, and Dart ints are 64-bit.

## Follow-ups you should be ready for

1. **Is t a subsequence of s? (LeetCode 392).** Two pointers, O(|s|).
2. **Count distinct subsequences of s itself (LeetCode 940).** DP with a "last occurrence" correction to avoid counting the same string twice.
3. **Number of matching subsequences for many words (LeetCode 792).** Bucket words by their next needed character.

## What to remember

Two-string DP: decide what happens to the last character of each string. For counting, the cases must be disjoint and are added; skip-or-use gives `ways(i-1, j) + ways(i-1, j-1)` on a match.
