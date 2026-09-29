# Longest Common Subsequence

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** 2D DP over two prefixes, with backtracking

## The problem

Given two strings, return their **longest common subsequence** (LCS) as a list of characters. A subsequence keeps the original order but may skip characters. Assume a unique LCS.

```
"ZXVVYZW", "XKYKZPW"  ->  ["X", "Y", "Z", "W"]
"ABCDEFG", "APPLES"   ->  ["A", "E"]
```

## Step 1: Think about the last characters

Let `a` and `b` be the strings. Compare their last characters:

- **Equal** (both `W` in the first example): some LCS ends with that character. The rest of the LCS is the LCS of the two strings without their last characters.
- **Different:** at least one of the two last characters is not in the LCS. So the LCS is the better of: LCS(a without its last char, b) and LCS(a, b without its last char).

Both cases reduce the problem to **shorter prefixes**. That is a DP.

## Step 2: The DP table

`L[i][j]` = length of the LCS of `a[0..i)` and `b[0..j)` (the first i and first j characters).

```
L[0][*] = L[*][0] = 0
L[i][j] = L[i-1][j-1] + 1                    if a[i-1] == b[j-1]
L[i][j] = max(L[i-1][j], L[i][j-1])          otherwise
```

## Step 3: Reconstruct the sequence

The table stores only lengths. To recover the characters, walk back from `(n, m)`:

- characters equal: this character is part of the LCS; take it and move diagonally;
- otherwise move toward the neighbor with the larger value (up or left);
- reverse the collected characters at the end.

Storing whole strings in every cell also works, but costs far more memory (each cell holds a string of length up to min(n, m)).

## Step 4: The code

<!-- CODE:START -->

Full source: [`longest_common_subsequence.dart`](longest_common_subsequence.dart) (run it with `dart run`).

```dart
// Longest Common Subsequence: returns the subsequence as a list of characters.
// 2D DP table, then backtrack. O(n * m) time and space.

List<String> longestCommonSubsequence(String str1, String str2) {
  final n = str1.length, m = str2.length;
  // lcs[i][j] = LCS length of str1[0..i) and str2[0..j)
  final lcs = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = 1; i <= n; i++) {
    for (var j = 1; j <= m; j++) {
      lcs[i][j] = str1[i - 1] == str2[j - 1]
          ? lcs[i - 1][j - 1] + 1
          : (lcs[i - 1][j] > lcs[i][j - 1] ? lcs[i - 1][j] : lcs[i][j - 1]);
    }
  }
  final out = <String>[];
  var i = n, j = m;
  while (i > 0 && j > 0) {
    if (str1[i - 1] == str2[j - 1]) {
      out.add(str1[i - 1]);
      i--;
      j--;
    } else if (lcs[i - 1][j] >= lcs[i][j - 1]) {
      i--;
    } else {
      j--;
    }
  }
  return out.reversed.toList();
}
```

<!-- CODE:END -->

### Walkthrough

- `lcs` is an `(n + 1) x (m + 1)` table of zeros (row 0 and column 0 are the empty-prefix base cases).
- The double loop fills it with the recurrence.
- The `while` loop backtracks from the bottom-right corner, collecting matched characters.
- `out.reversed.toList()` returns them in order.

## Step 5: Dry run (small example "ABCDEFG" vs "APPLES")

Relevant matches: `A` (both first) and `E` (a[4], b[4]). The table's bottom-right value is 2. Backtracking: at the end, `G` vs `S` differ, move toward the larger neighbor, ..., reach the `E`/`E` match (take `E`), continue up-left, reach `A`/`A` (take `A`). Reversed: `["A", "E"]`.

## Complexity

- **Time: O(n * m)**.
- **Space: O(n * m)** for the table (needed for reconstruction). If you only need the **length**, two rows suffice: O(min(n, m)).

## Common mistakes

- Taking `L[i-1][j-1]` (instead of the max of up and left) when characters differ.
- Forgetting to reverse the reconstructed sequence.

## Relation to edit distance

LCS and Levenshtein Distance (medium 31) fill the same kind of table. If only insertions and deletions are allowed, the edit distance equals `n + m - 2 * LCS`.

## Follow-ups

1. **Longest Common Subsequence (LeetCode #1143):** length only.
2. **Shortest Common Supersequence (#1092):** built from the LCS table.
3. **Diff tools** (`git diff`, text comparison) are based on LCS-like algorithms (Myers' algorithm).

## What to remember

Two-string DP: compare the last characters; match -> diagonal + 1; mismatch -> max of dropping one character from either string. Backtrack through the table to recover the answer.
