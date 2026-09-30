# Implement Trie (Prefix Tree)

**Difficulty:** Medium | **Category:** Tries | **Pattern:** Character-indexed tree with end-of-word flags | **Source:** LeetCode 208; NeetCode 150, Blind 75

## The problem

Implement a trie with:

- `insert(word)`
- `search(word)`: true if `word` was inserted.
- `startsWith(prefix)`: true if some inserted word starts with `prefix`.

```
insert("apple")
search("apple")   -> true
search("app")     -> false   (only a prefix)
startsWith("app") -> true
insert("app")
search("app")     -> true
```

## Step 1: Why a trie?

A hash set answers `search` in O(L), but `startsWith` would need to check every stored word: O(total characters). A trie stores words **by shared prefixes**, so any prefix query walks at most L nodes, no matter how many words are stored.

## Step 2: Structure

Each node has:

- `children`: a map from character to child node (or an array of 26 for lowercase letters).
- `isWord`: whether some inserted word ends **exactly** at this node.

The `isWord` flag is what distinguishes "app was inserted" from "app is only a prefix of apple": both walks reach the same node.

## Step 3: Operations

- `insert`: walk from the root, creating missing children, then set `isWord = true` on the last node.
- `search`: walk; fail if a child is missing; at the end, return `isWord`.
- `startsWith`: walk; fail if a child is missing; at the end, return true (the node exists, so some word passes through it).

`search` and `startsWith` share the walk (`_walk`).

## Step 4: The code

<!-- CODE:START -->

Full source: [`implement_trie.dart`](implement_trie.dart) (run it with `dart run`).

```dart
// Implement Trie (Prefix Tree): insert(word), search(word), startsWith(prefix).
// Each node maps a character to a child and marks whether a word ends there.
// Every operation is O(L) for a word or prefix of length L.

class _TrieNode {
  final children = <String, _TrieNode>{};
  bool isWord = false;
}

class Trie {
  final _root = _TrieNode();

  void insert(String word) {
    var node = _root;
    for (final ch in word.split('')) {
      node = node.children.putIfAbsent(ch, _TrieNode.new);
    }
    node.isWord = true; // the path alone is not enough: "app" is a prefix of "apple"
  }

  bool search(String word) => _walk(word)?.isWord ?? false;

  bool startsWith(String prefix) => _walk(prefix) != null;

  /// Follows [s] from the root; null if the path breaks.
  _TrieNode? _walk(String s) {
    _TrieNode? node = _root;
    for (final ch in s.split('')) {
      node = node!.children[ch];
      if (node == null) return null;
    }
    return node;
  }
}
```

<!-- CODE:END -->

### Walkthrough

- `putIfAbsent(ch, _TrieNode.new)` creates a child only if needed and returns it (Dart constructor tear-off).
- `_walk` returns null on a broken path; `?.isWord ?? false` turns that into false for `search`.

## Step 5: Dry run

After inserting "apple" the trie is one chain `a -> p -> p -> l -> e*` (`*` = `isWord`).

| operation | walk | result |
|---|---|---|
| search("app") | a, p, p (node exists, isWord false) | false |
| startsWith("app") | a, p, p (node exists) | true |
| insert("app") | a, p, p: set isWord | chain `a -> p -> p* -> l -> e*` |
| search("app") | a, p, p* | true |

## Complexity

- Each operation: **O(L)** time, L = length of the word or prefix.
- Space: **O(total characters inserted)** nodes in the worst case (no shared prefixes).

## Edge cases

- Empty prefix: `startsWith("")` is true (the root exists). LeetCode never asks it.
- Inserting the same word twice: harmless.

## Common mistakes

- Returning true from `search` whenever the path exists (forgetting `isWord`).
- Using `List.filled(26, _TrieNode())` (shares one node across all slots).

## Follow-ups you should be ready for

1. **Delete a word.** Clear `isWord`; optionally prune nodes with no children and no `isWord` on the way back.
2. **Count words with a prefix.** Store a counter in each node, incremented on insert.
3. **Wildcard search.** neetcode 20.
4. **Suffix trie.** Insert every suffix; see AlgoExpert medium 73 Suffix Trie Construction.

## What to remember

A trie node is `children + isWord`. Prefix queries walk the path; word queries also require the end flag.
