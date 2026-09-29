# Word Search

**Difficulty:** Medium | **Category:** Recursion / Backtracking | **Pattern:** Grid DFS with in-place visited marking | **Source:** LeetCode 79; Striver A2Z, NeetCode 150

## The problem

Given a grid of letters and a word, return whether the word can be formed by a path of **horizontally or vertically adjacent** cells, using each cell **at most once**.

```
A B C E
S F C S
A D E E

"ABCCED" -> true,  "SEE" -> true,  "ABCB" -> false
```

"ABCB" fails because the only B next to the second C is the one already used.

## Step 1: Why backtracking

Two sub-questions:

1. Where does the word start? Any cell holding `word[0]`: try them all.
2. From a cell, which neighbor continues the word? Possibly several: try each, and if a branch fails, **undo** and try the next.

"Try, and undo on failure" is backtracking. The "each cell at most once" rule means the path must remember which cells it has used, and forget them when it backtracks.

## Step 2: The recursive function

`dfs(r, c, i)`: can the suffix `word[i..]` be matched starting at cell (r, c)?

- If `i == word.length`: the whole word is matched, return true.
- If (r, c) is outside the grid, already used, or `board[r][c] != word[i]`: return false.
- Otherwise mark (r, c) as used, try the four neighbors with `i + 1`, unmark, and return whether any neighbor succeeded.

## Step 3: Marking visited without extra memory

A separate `visited` grid works. A common trick is to overwrite the cell with a character that can never match (like `'#'`) while it is on the current path, and restore it afterwards. That also makes the "already used" check free: `'#'` never equals `word[i]`.

The restore is not optional: other starting cells and other branches need the original board.

## Step 4: The code

<!-- CODE:START -->

Full source: [`word_search.dart`](word_search.dart) (run it with `dart run`).

```dart
// Word Search: does the word exist in the grid as a path of horizontally/vertically adjacent
// cells, using each cell at most once? DFS backtracking from every cell.
// O(rows * cols * 3^L) time where L = word length, O(L) recursion space.

bool exist(List<List<String>> board, String word) {
  final rows = board.length, cols = board[0].length;
  bool dfs(int r, int c, int i) {
    if (i == word.length) return true;
    if (r < 0 || c < 0 || r >= rows || c >= cols || board[r][c] != word[i]) return false;
    final saved = board[r][c];
    board[r][c] = '#'; // mark visited in place instead of a separate visited set
    final found = dfs(r + 1, c, i + 1) || dfs(r - 1, c, i + 1) || dfs(r, c + 1, i + 1) || dfs(r, c - 1, i + 1);
    board[r][c] = saved; // backtrack: restore for other paths
    return found;
  }

  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      if (dfs(r, c, 0)) return true;
    }
  }
  return false;
}
```

<!-- CODE:END -->

### Walkthrough

- The `i == word.length` check comes **before** the bounds check. Success is detected by the call made **after** the last letter matched, and that call may point outside the grid (the last letter was on an edge). Checking bounds first would wrongly reject it.
- `||` short-circuits: once a neighbor succeeds, the rest are not explored.
- The board is restored on both success and failure paths, because the restore line runs before `return found`.

## Step 5: Dry run

`"SEE"`:

| Call | Cell | Letter needed | Result |
|---|---|---|---|
| start (0,0) | A | S | no |
| ... | | | |
| start (1,3) | S | S | match, mark |
| down (2,3) | E | E | match, mark |
| down (3,3) | out of grid | E | no |
| up (1,3) | '#' | E | no (used) |
| right (2,4) | out of grid | E | no |
| left (2,2) | E | E | match, then `i == 3`: **true** |

## Complexity

- Time: **O(R * C * 3^L)**, L = word length. Each start cell launches a search whose branching factor is at most 4 at the first step and 3 afterwards (you never go back to the cell you came from, since it is marked).
- Space: **O(L)** recursion depth.

## Edge cases

- One-cell grid.
- Word longer than R * C: impossible, can return false immediately.
- Repeated letters (`"aaa"` in a 1x2 grid of `a`): the visited marking prevents reusing a cell.

## Common mistakes

- Forgetting to restore the cell (later searches fail).
- Using a global visited set that is never cleared between start cells.
- Checking bounds after indexing into the board.

## Follow-ups you should be ready for

1. **Pruning.** If the board does not contain enough of some letter, return false before searching. If the last letter of the word is rarer than the first, search for the reversed word (fewer start cells).
2. **Word Search II (LeetCode 212).** Many words: build a trie of the words and run one DFS over the board walking the trie; see AlgoExpert hard 30 Boggle Board.
3. **Diagonal moves allowed.** Eight directions, same code.

## What to remember

Grid path search with "each cell once" = DFS that marks the cell on the way in and unmarks it on the way out.
