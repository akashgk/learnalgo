# Levenshtein Distance

**Difficulty:** Medium | **Category:** Dynamic Programming | **Pattern:** 2D DP over two string prefixes (edit distance)

## The problem

Return the minimum number of single-character edits needed to turn one string into another. The allowed edits are **insert** a character, **delete** a character, and **substitute** one character for another.

```
"abc"    -> "yabd"     =  2   (insert 'y' at the front; substitute 'c' with 'd')
"kitten" -> "sitting"  =  3
""       -> "abc"      =  3
```

## Step 1: Think about the last characters

Compare `a = "abc"` and `b = "yabd"`. Look at the **last** characters, `c` and `d`. In an optimal edit sequence, one of these happens:

1. They are matched with a **substitution** (`c` becomes `d`): then the rest is turning `"ab"` into `"yab"`.
2. `c` is **deleted**: then the rest is turning `"ab"` into `"yabd"`.
3. `d` is **inserted** at the end: then the rest is turning `"abc"` into `"yab"`.

If the last characters were **equal**, no edit is needed for them: the rest is turning the two shorter prefixes into each other.

Every case reduces to the same problem on **shorter prefixes**. That is the definition of a DP.

## Step 2: The DP

**Subproblem:** `E[i][j]` = edit distance between the first `i` characters of `a` and the first `j` characters of `b`.

**Base cases:**
- `E[0][j] = j`: from the empty string, insert `j` characters.
- `E[i][0] = i`: delete all `i` characters.

**Recurrence:**

```
if a[i-1] == b[j-1]:
    E[i][j] = E[i-1][j-1]
else:
    E[i][j] = 1 + min( E[i-1][j-1],     # substitute
                       E[i-1][j],       # delete a[i-1]
                       E[i][j-1] )      # insert b[j-1]
```

Answer: `E[n][m]`.

### The table for "abc" -> "yabd"

```
        ""  y  a  b  d
   ""    0  1  2  3  4
   a     1  1  1  2  3
   b     2  2  2  1  2
   c     3  3  3  2  2
```

Read cell `(c, d)` = 2: `c != d`, so `1 + min(diagonal 1, above 2, left 2) = 2`. Filling this table once by hand is the best way to make the recurrence stick.

## Step 3: Space optimization

Each row only depends on the row above. Keep two rows. Because edit distance is **symmetric** (turning `a` into `b` costs the same as `b` into `a`, since insert and delete are mirror operations), the code puts the **shorter** string along the row, so the rows have length `min(n, m) + 1`.

## Step 4: The code

<!-- CODE:START -->

Full source: [`levenshtein_distance.dart`](levenshtein_distance.dart) (run it with `dart run`).

```dart
// Levenshtein Distance: min insertions, deletions, substitutions to turn str1 into str2.
// Classic 2D DP with a rolling row. O(n * m) time, O(min(n, m)) space.

int levenshteinDistance(String str1, String str2) {
  // Make str2 the shorter string so the row is as small as possible.
  final (long, short) = str1.length >= str2.length ? (str1, str2) : (str2, str1);
  var prev = List<int>.generate(short.length + 1, (j) => j); // "" -> short[0..j)
  for (var i = 1; i <= long.length; i++) {
    final curr = List<int>.filled(short.length + 1, 0)..[0] = i;
    for (var j = 1; j <= short.length; j++) {
      if (long[i - 1] == short[j - 1]) {
        curr[j] = prev[j - 1];
      } else {
        final replace = prev[j - 1], delete = prev[j], insert = curr[j - 1];
        curr[j] = 1 + [replace, delete, insert].reduce((a, b) => a < b ? a : b);
      }
    }
    prev = curr;
  }
  return prev[short.length];
}
```

<!-- CODE:END -->

### Walkthrough

- `final (long, short) = ...` orders the strings so rows are sized by the shorter one.
- `prev` starts as row 0: `[0, 1, 2, ..., short.length]`.
- For each character of `long`, `curr[0] = i` (delete all i characters), then each cell follows the recurrence.
- The names `replace`, `delete`, `insert` refer to the diagonal, the cell above, and the cell to the left.
- `prev = curr;` moves to the next row. The answer is the last cell of the last row.

## Step 5: Dry run

With the swap, `long = "yabd"` (rows) and `short = "abc"` (columns). Row by row:

| row (char of long) | values for "", a, b, c |
|---|---|
| start | 0 1 2 3 |
| y | 1 1 2 3 |
| a | 2 1 2 3 |
| b | 3 2 1 2 |
| d | 4 3 2 **2** |

Answer: 2. (This table is the transpose of the one above, as expected by symmetry.)

## Complexity

- **Time: O(n * m)**.
- **Space: O(min(n, m))** with two rows. The full O(n * m) table is needed if you want to reconstruct the actual edit sequence (walk back from the bottom-right cell).

## Common mistakes

- Wrong base cases (all zeros).
- Adding 1 even when the characters match.
- Mixing up which neighbor means insert and which means delete. (It does not change the result, only the explanation.)

## Follow-ups

1. **Edit Distance (LeetCode #72):** identical.
2. **One Edit (medium 72):** only asks whether the distance is at most 1; solvable in O(n) without a table.
3. **Longest Common Subsequence (hard 16):** the same table structure with a different recurrence.
4. **Different operation costs** (for example substitution costs 2): replace the `1 +` with the specific costs.
5. **Real-world uses:** spell checkers ("did you mean"), DNA alignment, fuzzy search. Google interviewers like the autocorrect framing.

## What to remember

Two-string DP: `E[i][j]` over prefixes. Decide what happens to the last characters, and each choice points to a neighboring cell.
