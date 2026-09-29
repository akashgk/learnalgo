# Boggle Board

**Difficulty:** Hard | **Category:** Graphs | **Pattern:** Trie + backtracking DFS on a grid

## The problem

Given a 2D board of characters and a list of words, return all words that can be formed on the board. A word is formed by a path of **adjacent** cells (horizontally, vertically, or **diagonally**), and a cell may be used **at most once per word**.

```
board:                      words:
t h i s i s a               this, is, not, a, simple, boggle,
s i m p l e x               board, test, REPEATED, NOTRE-PEATED
b x x x x e b
x o g g l x o
x x x D T r a
R E P E A d x
x x x x x x x
N O T R E - P
x x D E T A E

->  [this, is, a, simple, boggle, board, NOTRE-PEATED]
```

## Step 1: One word at a time

For each word, try to start a DFS from every cell that matches its first letter, extending to neighbors that match the next letter, never reusing a cell. That is Word Search (LeetCode #79) repeated for every word.

**Problem:** with many words, the board is explored again and again, and words sharing a prefix (`"simp"` in several words, or `"NOTRE"` and ...) repeat identical work.

## Step 2: Search all words at once with a trie

Put all the words into a **trie** (prefix tree). Now run **one** DFS from every cell, walking down the trie **at the same time** as you walk across the board:

- If the current path of letters is not a prefix of any word, the trie has no matching child: **stop immediately** (pruning).
- If the trie node marks the end of a word, record that word.

The trie turns "does any word start with this path?" into an O(1) child lookup. That pruning is what makes the search fast in practice.

## Step 3: Backtracking details

- Mark a cell as visited when you step onto it, and **unmark** it when you leave (other paths, and other words, may need it).
- Store the complete word at its terminal trie node, so you do not need to rebuild the string from the path.
- A word can be found along several paths; keep results in a set.

## Step 4: The code

<!-- CODE:START -->

Full source: [`boggle_board.dart`](boggle_board.dart) (run it with `dart run`).

```dart
// Boggle Board: which words can be formed by paths of adjacent cells (8 directions),
// using each cell at most once per word? Build a trie of words, DFS from every cell.
// O(w * h * 8^s + total word length) time, O(total word length + w * h) space.

class _TrieNode {
  final children = <String, _TrieNode>{};
  String? word; // set on the node where a word ends
}

List<String> boggleBoard(List<List<String>> board, List<String> words) {
  final root = _TrieNode();
  for (final w in words) {
    var node = root;
    for (final ch in w.split('')) {
      node = node.children.putIfAbsent(ch, _TrieNode.new);
    }
    node.word = w;
  }
  final rows = board.length, cols = board[0].length;
  final visited = List.generate(rows, (_) => List<bool>.filled(cols, false));
  final found = <String>{};

  void explore(int r, int c, _TrieNode parent) {
    if (r < 0 || r >= rows || c < 0 || c >= cols || visited[r][c]) return;
    final node = parent.children[board[r][c]];
    if (node == null) return; // no word continues with this prefix: prune
    if (node.word != null) found.add(node.word!);
    visited[r][c] = true;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr != 0 || dc != 0) explore(r + dr, c + dc, node);
      }
    }
    visited[r][c] = false; // backtrack so other paths can use this cell
  }

  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      explore(r, c, root);
    }
  }
  return [
    for (final w in words)
      if (found.contains(w)) w,
  ];
}
```

<!-- CODE:END -->

### Walkthrough

- `_TrieNode` has a `children` map and an optional `word` set at word ends.
- Building the trie inserts each word character by character (`putIfAbsent(ch, _TrieNode.new)` creates missing children).
- `explore(r, c, parent)`:
  - returns on out-of-bounds or already-visited cells;
  - looks up the child for this cell's character; if missing, prunes;
  - records a word if one ends here;
  - marks the cell, explores all 8 neighbors, then unmarks it.
- The result keeps the input order of the words that were found.

## Complexity

- **Build the trie:** O(total characters in the words).
- **Search:** O(w * h * 8^s) in the worst case, where s is the length of the longest word (each step has up to 8 directions, 7 excluding where you came from). Pruning makes typical runs far faster.
- **Space:** O(total word characters) for the trie plus O(w * h) for the visited grid and recursion.

## Common mistakes

- Not unmarking cells after exploring (other words can no longer use them).
- Only allowing 4 directions (Boggle allows diagonals).
- Running a separate search per word (correct, but slow).

## Follow-ups

1. **Word Search II (LeetCode #212):** the same problem with 4 directions; one of the most asked hard problems at Google and Amazon.
2. **Extra optimization:** once a word is found, remove it from the trie (and prune empty branches), so later searches skip it.

## What to remember

To search for many words at once, put them in a trie and walk the trie together with the DFS; a missing child ends the path immediately.
