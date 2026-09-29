# Shortest Unique Prefixes

**Difficulty:** Hard | **Category:** Tries | **Pattern:** Trie with pass-through counts

## The problem

Given a list of strings where **no string is a prefix of another**, return, for each string, its **shortest prefix that is not a prefix of any other string** in the list.

```
["zebra", "dog", "duck", "dove"]            ->  ["z", "dog", "du", "dov"]
["algoexpert", "algorithm", "foo", "frontend"] ->  ["algoe", "algor", "fo", "fr"]
```

## Step 1: Work an example by hand

For "dove": "d" is shared with "dog" and "duck"; "do" is shared with "dog"; "dov" is only in "dove". Answer "dov".

The question for each prefix is: **how many strings start with it?** The answer is the first prefix where that number is 1.

## Step 2: Brute force

For each string, try prefixes of increasing length and check every other string: O(n^2 * m) or worse.

## Step 3: Trie with counts

As in Longest Most Frequent Prefix (hard 57): insert every string into a trie and increment a counter on every node passed. A node's count is the number of strings that start with that node's prefix.

Then, for each string, walk its path from the root and stop at the **first node with count 1**: that prefix belongs to this string only.

The guarantee "no string is a prefix of another" ensures such a node always exists (at the latest at the string's last character). Without it, `"do"` next to `"dog"` would have no unique prefix; you would return the whole string or report it.

## Step 4: The code

<!-- CODE:START -->

Full source: [`shortest_unique_prefixes.dart`](shortest_unique_prefixes.dart) (run it with `dart run`).

```dart
// Shortest Unique Prefixes: for each string, the shortest prefix no other string shares.
// (Assumes no string is a prefix of another.) Trie with pass-through counts.
// O(n * m) time and space.

class _TrieNode {
  final children = <String, _TrieNode>{};
  int count = 0;
}

List<String> shortestUniquePrefixes(List<String> strings) {
  final root = _TrieNode();
  for (final s in strings) {
    var node = root;
    for (var i = 0; i < s.length; i++) {
      node = node.children.putIfAbsent(s[i], _TrieNode.new);
      node.count++;
    }
  }
  return [for (final s in strings) _uniquePrefix(root, s)];
}

String _uniquePrefix(_TrieNode root, String s) {
  var node = root;
  for (var i = 0; i < s.length; i++) {
    node = node.children[s[i]]!;
    if (node.count == 1) return s.substring(0, i + 1); // only this string passes here
  }
  return s;
}
```

<!-- CODE:END -->

### Walkthrough

- Building the trie increments `count` along each path.
- `_uniquePrefix` walks the string's path and returns the first prefix whose node has count 1.
- The final `return s;` covers the case where no node reaches count 1 (only possible if the guarantee is violated).

## Step 5: Dry run for ["zebra", "dog", "duck", "dove"]

| node | count |
|---|---|
| z | 1 |
| d | 3 |
| do | 2 |
| dog | 1 |
| du | 1 |
| dov | 1 |

- zebra: "z" has count 1: `"z"`.
- dog: d (3), do (2), dog (1): `"dog"`.
- duck: d (3), du (1): `"du"`.
- dove: d (3), do (2), dov (1): `"dov"`.

## Complexity

- **Time: O(n * m)** to build and query.
- **Space: O(n * m)** for the trie.

## Common mistakes

- Returning the prefix one character too short (stop **at** the node with count 1, including its character).
- Ignoring the "no string is a prefix of another" assumption.

## Follow-ups

1. **Command abbreviations:** tools like `git` and shells accept the shortest unambiguous prefix of a command; this is the algorithm behind it.
2. **Streaming insertions:** counts update in O(m) per new string; answers for existing strings may get longer as new strings arrive.

## What to remember

With pass-through counts on a trie, "unique prefix" means "first node on my path with count 1".
