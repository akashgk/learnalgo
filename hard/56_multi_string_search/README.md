# Multi String Search

**Difficulty:** Hard | **Category:** Tries | **Pattern:** Trie of the small strings, scanned from every position of the big string

## The problem

Given a big string and a list of small strings, return a list of booleans saying, for each small string, whether it appears somewhere in the big string.

```
bigString    = "this is a big string"
smallStrings = ["this", "yo", "is", "a", "bigger", "string", "kappa"]
->  [true, false, true, true, false, true, false]
```

## Step 1: Naive

For each small string, test every starting position of the big string: O(b * n * s) for b = big length, n = number of small strings, s = max small length.

## Step 2: Option A: suffix trie of the big string

Build a suffix trie of the big string (Suffix Trie Construction, medium 73): O(b^2) time and space. Then each small string is a substring iff it is a path from the root: O(s) per query. Great when the big string is short and there are many queries, terrible when the big string is long.

## Step 3: Option B: trie of the small strings (this code)

Put all the **small** strings into a trie, marking where each one ends (store its index). Then, for **each starting position** of the big string, walk down the trie following the big string's characters:

- every word-end node you pass is a small string that occurs starting at this position: mark it found;
- stop as soon as the trie has no matching child.

A walk never goes deeper than the longest small string, so each start costs O(s).

## Step 4: Which trie should you build?

Build the trie over the **smaller** total input:

| | Build | Search | Best when |
|---|---|---|---|
| Suffix trie of big string | O(b^2) | O(n * s) | big string short, many queries |
| Trie of small strings | O(n * s) | O(b * s) | big string long |

Explaining this trade-off is exactly what the interviewer is looking for.

## Step 5: The code

<!-- CODE:START -->

Full source: [`multi_string_search.dart`](multi_string_search.dart) (run it with `dart run`).

```dart
// Multi String Search: for each small string, is it contained in the big string?
// Trie of small strings; walk the trie from every start index of the big string.
// O(ns + b * s) time, O(ns) space (n small strings of max length s, big string length b).

class _TrieNode {
  final children = <String, _TrieNode>{};
  int? wordIndex; // index into smallStrings if a word ends here
}

List<bool> multiStringSearch(String bigString, List<String> smallStrings) {
  final root = _TrieNode();
  for (var i = 0; i < smallStrings.length; i++) {
    var node = root;
    for (final ch in smallStrings[i].split('')) {
      node = node.children.putIfAbsent(ch, _TrieNode.new);
    }
    node.wordIndex = i;
  }
  final found = List<bool>.filled(smallStrings.length, false);
  for (var start = 0; start < bigString.length; start++) {
    var node = root;
    for (var j = start; j < bigString.length; j++) {
      final next = node.children[bigString[j]];
      if (next == null) break; // no small string continues this way
      node = next;
      if (node.wordIndex != null) found[node.wordIndex!] = true;
    }
  }
  return found;
}
```

<!-- CODE:END -->

### Walkthrough

- `_TrieNode.wordIndex` stores which small string ends at this node.
- Building the trie inserts every small string.
- The double loop: for each `start`, walk the trie along `bigString[start..]`; break when there is no child; mark every word end encountered.

## Step 6: Dry run (start = 0, "this is a big string")

| char | trie node | word ends here? |
|---|---|---|
| t | t | no |
| h | th | no |
| i | thi | no |
| s | this | **yes: "this"** |
| (space) | no child | stop |

At start = 2, the walk `i -> s` finds "is". At start = 8, `a` finds "a". And so on.

## Complexity

- **Time: O(n * s + b * s)**: building the trie plus one bounded walk per start position.
- **Space: O(n * s)** for the trie.

## The optimal answer: Aho-Corasick

Add **failure links** to the trie of small strings (like KMP's failure function, but for many patterns). Then the big string is scanned **once**, never restarting: O(b + n * s + number of matches). It powers `grep -F` and network intrusion detection. Naming it is a strong signal; implementing it is rarely expected.

## Common mistakes

- Stopping at the first word end found during a walk (longer words on the same path can also match).
- Reporting a small string that is only a prefix of a path (you must check the word-end marker).

## What to remember

To find many patterns in one text, put the patterns in a trie and walk it from every text position; build the trie over whichever input is smaller.
