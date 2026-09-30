# Design Add and Search Words Data Structure

**Difficulty:** Medium | **Category:** Tries | **Pattern:** Trie + DFS branching on wildcards | **Source:** LeetCode 211; NeetCode 150, Blind 75

## The problem

Support `addWord(word)` and `search(pattern)`, where the pattern may contain `.` meaning "any one letter". The whole word must match (same length).

```
addWord("bad"), addWord("dad"), addWord("mad")
search("pad") -> false
search("bad") -> true
search(".ad") -> true
search("b..") -> true
```

## Step 1: Why a trie

With a plain list of words, each search compares the pattern against every word: O(N * L). A trie shares prefixes, so a pattern without dots is a single O(L) walk (neetcode 19).

## Step 2: Handling the dot

At a `.`, the next character can be anything, so the search must try **every child** of the current node. That turns the walk into a DFS:

```
dfs(node, i):
  if i == length: return node.isWord
  if pattern[i] == '.': return any child c with dfs(c, i + 1)
  else: follow the matching child, or fail
```

The trie keeps this efficient: branches only exist where words actually differ, so a `.` explores only letters that occur at that position after the current prefix.

## Step 3: The code

<!-- CODE:START -->

Full source: [`design_add_and_search_words.dart`](design_add_and_search_words.dart) (run it with `dart run`).

```dart
// Design Add and Search Words Data Structure: addWord(word), search(pattern) where '.' matches any
// one letter. Trie + DFS that branches into every child on '.'.
// addWord O(L); search O(L) without dots, up to O(26^d * L) with d dots in the worst case.

class _TrieNode {
  final children = <String, _TrieNode>{};
  bool isWord = false;
}

class WordDictionary {
  final _root = _TrieNode();

  void addWord(String word) {
    var node = _root;
    for (final ch in word.split('')) {
      node = node.children.putIfAbsent(ch, _TrieNode.new);
    }
    node.isWord = true;
  }

  bool search(String word) {
    bool dfs(_TrieNode node, int i) {
      if (i == word.length) return node.isWord;
      final ch = word[i];
      if (ch == '.') {
        // Wildcard: any child may continue the match.
        for (final child in node.children.values) {
          if (dfs(child, i + 1)) return true;
        }
        return false;
      }
      final next = node.children[ch];
      return next != null && dfs(next, i + 1);
    }

    return dfs(_root, 0);
  }
}
```

<!-- CODE:END -->

### Walkthrough

- `addWord` is Trie insert.
- `dfs` returns `node.isWord` at the end of the pattern, so `"b."` fails (the node after `b`, `a` is not the end of a word).
- The loop over `node.children.values` returns true as soon as one branch matches.

## Step 4: Dry run

Trie: root has children `b`, `d`, `m`, each followed by `a -> d*`.

`search(".ad")`:

| i | char | action |
|---|---|---|
| 0 | `.` | try child `b` |
| 1 | `a` | follow `a` |
| 2 | `d` | follow `d` |
| 3 | end | `isWord` true: **match** (children `d`, `m` never tried) |

## Complexity

- `addWord`: **O(L)**.
- `search`: **O(L)** without dots; with d dots, up to **O(26^d * L)** in the worst case (each dot can branch 26 ways). LeetCode limits dots to at most 2 per query.
- Space: **O(total characters)**.

## Edge cases

- Pattern of only dots: matches any word of that length.
- Pattern longer or shorter than every word: false.

## Common mistakes

- Returning true when the pattern ends at a non-word node.
- Using a regular expression over all words (O(N * L) per query).

## Follow-ups you should be ready for

1. **`*` wildcard (any sequence).** At `*`, try "match nothing" (advance the pattern) or "consume one letter and stay" for each child.
2. **Group words by length first.** A map from length to a trie avoids exploring words of the wrong length.
3. **Word Search II.** Trie + grid DFS; see AlgoExpert hard 30 Boggle Board.

## What to remember

A wildcard in a trie search means "try every child here": the walk becomes a DFS, bounded by what the trie actually contains.
