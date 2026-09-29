# Suffix Trie Construction

**Difficulty:** Medium | **Category:** Tries | **Pattern:** Insert every suffix into a trie

## The problem

Build a **suffix trie** for a string: a trie containing every suffix of the string, each suffix ending with a special end marker `*`. Support:

- construction from a string;
- `contains(string)`: whether the given string is a **suffix** of the original.

```
"babc" has suffixes: "babc", "abc", "bc", "c"

root
 |-- b
 |   |-- a -- b -- c -- *
 |   |-- c -- *
 |-- a -- b -- c -- *
 |-- c -- *

contains("abc") -> true    contains("ab") -> false (a prefix of a suffix, but not a suffix)
```

## Step 1: What is a trie?

A trie (prefix tree) stores strings character by character along paths from the root. Each node maps a character to a child node. Strings that share a prefix share the same path, so `"babc"` and `"bc"` share the node for `b`.

Looking up a string of length m is O(m): follow one edge per character. It does not depend on how many strings are stored.

## Step 2: Build the suffix trie

For each starting index `i`, insert the suffix `string[i..]`:

```
for i in 0..n-1:
    node = root
    for each character c of string[i..]:
        node = node.child(c), creating it if missing
    mark node with the end symbol '*'
```

The end marker distinguishes "a suffix ends here" from "a suffix passes through here". Without it, `contains("ab")` would be true, because `"ab"` is a prefix of the suffix `"abc"`.

## Step 3: contains(s)

Walk from the root following the characters of `s`. If an edge is missing, return false. At the end, return whether the node has the end marker.

Useful fact: **without** checking the end marker, the same walk answers "is `s` a **substring** of the original string?", because every substring is a prefix of some suffix. That is the main practical use of suffix tries.

## Step 4: The code

<!-- CODE:START -->

Full source: [`suffix_trie_construction.dart`](suffix_trie_construction.dart) (run it with `dart run`).

```dart
// Suffix Trie Construction: trie of all suffixes, each terminated by '*'.
// Build O(n^2) time and space; contains(s) O(m).

class SuffixTrie {
  SuffixTrie(String string) {
    for (var i = 0; i < string.length; i++) {
      _insertSubstringStartingAt(string, i);
    }
  }

  final root = <String, Object>{};
  static const endSymbol = '*';

  void _insertSubstringStartingAt(String string, int start) {
    var node = root;
    for (var j = start; j < string.length; j++) {
      node = node.putIfAbsent(string[j], () => <String, Object>{}) as Map<String, Object>;
    }
    node[endSymbol] = true;
  }

  /// True if [string] is a suffix (not merely a substring) of the original string.
  bool contains(String string) {
    var node = root;
    for (final ch in string.split('')) {
      final next = node[ch];
      if (next == null) return false;
      node = next as Map<String, Object>;
    }
    return node.containsKey(endSymbol);
  }
}
```

<!-- CODE:END -->

### Walkthrough

- `root` is a `Map<String, Object>`: children are nested maps, and the end marker maps `'*'` to `true`. A nested map is the quickest trie in an interview; a `TrieNode` class with `children` and `isEnd` is cleaner for larger problems (used in the hard section).
- `_insertSubstringStartingAt(string, i)` walks and creates nodes with `putIfAbsent`, then sets the end marker.
- `contains` follows edges and checks the marker. The `as Map<String, Object>` casts are needed because the map values are typed `Object` (they can be maps or the `true` marker).

## Step 5: Dry run: contains("ab")

| char | node has edge? |
|---|---|
| a | yes (from suffix "abc") |
| b | yes |
| end | node has no `*` (it continues to `c`) -> false |

## Complexity

- **Build: O(n^2) time and space**: n suffixes with total length n + (n-1) + ... + 1 = n(n+1)/2.
- **contains: O(m)** for a query of length m.

## Common mistakes

- Forgetting the end marker (turns "is suffix" into "is substring").
- Inserting only the whole string instead of every suffix.

## Follow-ups

1. **Multi String Search (hard 56):** find which small strings occur in a big string; a suffix trie of the big string answers each in O(m).
2. **Production structures:** suffix **trees** (built in O(n) with Ukkonen's algorithm, compressing chains of single-child nodes) and suffix **arrays** (O(n log n) build, O(n) space). You are not expected to implement them in interviews; naming them shows depth.
3. **Implement Trie (LeetCode #208):** insert, search, startsWith for a set of words.

## What to remember

A trie stores strings as paths of characters. Inserting every suffix gives O(m) substring and suffix queries at the cost of O(n^2) memory.
