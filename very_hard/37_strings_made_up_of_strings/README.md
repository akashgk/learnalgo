# Strings Made Up Of Strings

**Difficulty:** Very Hard | **Category:** Strings | **Pattern:** Word break DP accelerated with a trie

## The problem

Given a list of strings and a list of substrings, return (in their original order) the strings that can be formed **entirely** by concatenating substrings from the list. A substring may be used any number of times.

> Statement note: this is my reconstruction of AlgoExpert's problem from memory (the statement is paywalled). If the site's version differs (for example, no reuse), the trie + DP core still applies.

```
strings    = ["bar", "are", "foo", "ba", "b", "barely"]
substrings = ["b", "a", "r", "ba", "ar", "bar", "ely"]
->  ["bar", "ba", "b", "barely"]
```

- "barely" = "bar" + "ely".
- "are" fails: nothing covers the "e" at position 2 (only "ely" starts with "e", and "are" ends too soon).
- "foo" fails: no piece starts with "f".

## Step 1: One string is a Word Break problem

For a single string s: `ok[i]` = "the prefix of length i can be built".

```
ok[0] = true
ok[j] = true if some ok[i] is true and s[i..j) is one of the substrings
```

The string can be built iff `ok[len(s)]`.

## Step 2: The slow part

Checking every pair `(i, j)` with a hash set: O(m^2) pairs, each building and hashing a substring of length up to m: **O(m^3)** per string.

## Step 3: Trie of the substrings

Put all substrings in a **trie**. For each reachable position `i` (where `ok[i]` is true), walk the trie following `s[i], s[i+1], ...`:

- every word-end node reached at position `k` means `s[i..k]` is a substring: set `ok[k + 1] = true`;
- stop as soon as the trie has no matching child.

A walk never goes deeper than the longest substring L. So each string costs **O(m * L)**. Build the trie once and reuse it for all strings.

## Step 4: The code

<!-- CODE:START -->

Full source: [`strings_made_up_of_strings.dart`](strings_made_up_of_strings.dart) (run it with `dart run`).

```dart
// Strings Made Up Of Strings: which strings can be formed by concatenating substrings from the
// given list (each substring may be reused)? Trie of substrings + DP (word break) per string.
// O(sum over strings of m * L) time with a trie (m = string length, L = max substring length),
// O(total substring length) space.

class _TrieNode {
  final children = <int, _TrieNode>{};
  bool isEnd = false;
}

List<String> stringsMadeUpOfStrings(List<String> strings, List<String> substrings) {
  final root = _TrieNode();
  for (final s in substrings) {
    var node = root;
    for (final c in s.codeUnits) {
      node = node.children.putIfAbsent(c, _TrieNode.new);
    }
    node.isEnd = true;
  }

  bool canBuild(String s) {
    // ok[i] = s[0..i) can be built. Walk the trie forward from every reachable position.
    final ok = List<bool>.filled(s.length + 1, false)..[0] = true;
    for (var start = 0; start < s.length; start++) {
      if (!ok[start]) continue;
      var node = root;
      for (var k = start; k < s.length; k++) {
        final next = node.children[s.codeUnitAt(k)];
        if (next == null) break;
        node = next;
        if (node.isEnd) ok[k + 1] = true;
      }
    }
    return ok[s.length];
  }

  return [
    for (final s in strings)
      if (s.isNotEmpty && canBuild(s)) s,
  ];
}
```

<!-- CODE:END -->

### Walkthrough

- `_TrieNode` uses character codes as keys and marks word ends with `isEnd`.
- `canBuild(s)` runs the DP from Step 3.
- The final comprehension keeps the strings that can be built (and skips empty strings).

## Step 5: Dry run for "barely"

| start i (ok[i] true) | trie walk | ok values set |
|---|---|---|
| 0 | b (end), ba (end), bar (end), then "e" has no child | ok[1], ok[2], ok[3] |
| 1 | a (end), ar (end), then "e" has no child | ok[2], ok[3] |
| 2 | r (end), then "e" has no child | ok[3] |
| 3 | e, el, ely (end) | **ok[6]** |

`ok[6]` is true: "barely" can be built.

## Complexity

- **Build the trie:** O(total length of the substrings).
- **Per string of length m:** O(m * L).
- **Space:** O(total substring length) for the trie, O(m) for the DP array.

## Common mistakes

- Greedy longest match (can fail when a shorter piece is needed first).
- Forgetting that pieces can be reused (they can; the DP naturally allows it).

## Follow-ups

1. **Word Break (LeetCode #139):** one string.
2. **Concatenated Words (#472):** the dictionary and the strings are the same list; sort by length and add each word to the trie after checking it (a word must be made of at least two shorter words).
3. **Word Break II (#140):** return all splits.

## What to remember

"Can this string be split into dictionary pieces?" is a prefix DP. Walking a trie of the pieces from each reachable position finds all valid next positions in one pass.
