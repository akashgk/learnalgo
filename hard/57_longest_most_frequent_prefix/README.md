# Longest Most Frequent Prefix

**Difficulty:** Hard | **Category:** Tries | **Pattern:** Trie with pass-through counts

## The problem

Given a list of non-empty strings, consider every prefix of every string. Find the prefixes shared by the **most** strings, and among those return the **longest**.

```
["algoexpert", "algorithm", "frontendexpert", "mlexpert"]  ->  "algo"
```

The prefixes "a", "al", "alg", "algo" are each shared by 2 strings (the maximum). The longest of them is "algo".

> Statement note: this is my reading of AlgoExpert's problem (the statement is paywalled). Ties at the same count and length are broken by first occurrence here.

## Step 1: Hash map of prefixes

Count every prefix of every string in a map `prefix -> count`, then scan for the best. There are O(n * m) prefixes (n strings, max length m), but each prefix costs O(m) to build and hash: **O(n * m^2)** time and memory.

## Step 2: A trie shares prefixes

In a trie, **each node represents exactly one prefix** (the path from the root). Strings with a common prefix share its nodes. So:

- when inserting a string, increment a **counter** on every node you pass through;
- a node's counter = the number of strings that have that node's prefix.

That costs O(1) per character: **O(n * m)** total.

Then scan all nodes and keep the best by (count, then depth).

## Step 3: A useful property

A node's count is never larger than its parent's count (every string passing through the child also passes through the parent). So for the maximum count, the answer is the **deepest** node that still has that count.

## Step 4: The code

<!-- CODE:START -->

Full source: [`longest_most_frequent_prefix.dart`](longest_most_frequent_prefix.dart) (run it with `dart run`).

```dart
// Longest Most Frequent Prefix: among all prefixes, find those shared by the most strings;
// return the longest of them. Trie with pass-through counts.
// O(n * m) time and space (n strings, m = max length).

class _TrieNode {
  final children = <String, _TrieNode>{};
  int count = 0; // number of strings that pass through this node
}

String longestMostFrequentPrefix(List<String> strings) {
  final root = _TrieNode();
  var bestCount = 0;
  var bestPrefix = '';
  for (final s in strings) {
    var node = root;
    for (var i = 0; i < s.length; i++) {
      node = node.children.putIfAbsent(s[i], _TrieNode.new);
      node.count++;
    }
  }
  // Evaluate every prefix once, after all counts are final.
  void visit(_TrieNode node, String prefix) {
    for (final MapEntry(key: ch, value: child) in node.children.entries) {
      final p = prefix + ch;
      if (child.count > bestCount || (child.count == bestCount && p.length > bestPrefix.length)) {
        bestCount = child.count;
        bestPrefix = p;
      }
      visit(child, p);
    }
  }

  visit(root, '');
  return bestPrefix;
}
```

<!-- CODE:END -->

### Walkthrough

- `_TrieNode.count` is the number of strings passing through the node.
- The insertion loop increments counts along each string's path.
- `visit` is a DFS over the trie that carries the prefix string and updates the best by count, then length.

## Step 5: Dry run (counts along the "algo..." branch)

| node (prefix) | count |
|---|---|
| a | 2 |
| al | 2 |
| alg | 2 |
| algo | 2 |
| algoe / algor | 1 each |
| f... , m... | 1 each |

Maximum count 2; the deepest node with count 2 is "algo".

## Complexity

- **Time: O(n * m)** to build, plus a traversal of all O(n * m) nodes. (Building the prefix strings during the DFS adds cost; tracking only the best node and its depth, then rebuilding the string once, keeps it linear.)
- **Space: O(n * m)** for the trie.

## Common mistakes

- Counting how many **times** a prefix occurs inside strings (substring counting) instead of how many strings **start** with it.
- Returning the most frequent prefix without the "longest" tie-break (it would return "a").

## Follow-ups

1. **Implement Trie II (LeetCode #1804):** `countWordsStartingWith(prefix)` is exactly this counter.
2. **Autocomplete ranking:** counts on trie nodes rank suggestions by popularity.
3. **Shortest Unique Prefixes (hard 58):** the same counters, looking for count 1.

## What to remember

A trie node is a prefix. Incrementing a counter on every node during insertion gives "how many strings start with this prefix" for all prefixes at once.
