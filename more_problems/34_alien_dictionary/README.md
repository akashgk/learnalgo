# Alien Dictionary

**Difficulty:** Hard | **Category:** Graphs | **Pattern:** Build a precedence graph, then topological sort | **Source:** LeetCode 269 (premium); Striver A2Z, NeetCode 150

## The problem

An alien language uses lowercase English letters in an unknown order. You get a list of words **sorted** in that language's dictionary order. Return **any** order of the letters consistent with the list, or `""` if the list is contradictory.

```
["wrt", "wrf", "er", "ett", "rftt"]  ->  "wertf"
["z", "x"]                           ->  "zx"
["z", "x", "z"]                      ->  ""      (z < x and x < z)
["abc", "ab"]                        ->  ""      (a longer word before its own prefix)
```

## Step 1: What does a sorted pair of words tell us?

Compare `"wrt"` and `"wrf"`. They agree on `w`, `r`, then differ: `t` vs `f`. Dictionary order is decided by the **first difference**, so `t < f`. Everything after the first difference says **nothing** (just like "ab..." vs "ac..." in English: the letters after b and c are irrelevant).

Only **adjacent** pairs need comparing: if w1 <= w2 <= w3, any fact implied by (w1, w3) is implied by the adjacent pairs (the order is transitive).

From the example:

| pair | first difference | fact |
|---|---|---|
| wrt, wrf | t, f | t < f |
| wrf, er | w, e | w < e |
| er, ett | r, t | r < t |
| ett, rftt | e, r | e < r |

## Step 2: It is a graph problem

Letters are nodes, each fact `a < b` is a directed edge `a -> b`. A valid alphabet is an ordering where every edge goes forward: a **topological order**. A contradiction is a **cycle**, and then no order exists.

Here: `w -> e -> r -> t -> f`, so the answer is `"wertf"`.

## Step 3: The invalid-prefix case

If two adjacent words share their whole shorter length (no difference) and the **first** is longer, like `"abc"` before `"ab"`, the input is invalid in any alphabet: a prefix must come before its extensions. Return `""`. This is easy to forget, and test suites check it.

## Step 4: Topological sort with Kahn's algorithm

1. Every letter that appears in any word is a node (even letters with no edges; they can go anywhere).
2. Compute in-degrees. Start with all letters of in-degree 0 in a queue.
3. Pop a letter, append it to the answer, decrement the in-degree of its successors, enqueue those that reach 0.
4. If the answer has fewer letters than the graph, the remaining letters are on a cycle: return `""`.

DFS-based topological sort (with a three-color cycle check) also works. See AlgoExpert hard 27 Topological Sort.

## Step 5: The code

<!-- CODE:START -->

Full source: [`alien_dictionary.dart`](alien_dictionary.dart) (run it with `dart run`).

```dart
// Alien Dictionary: given words sorted in an unknown alphabet, return one valid letter order
// ("" if the input is contradictory). Compare adjacent words to get edges, then topological sort
// (Kahn's algorithm). O(C) time where C = total characters, O(1) extra space for 26 letters.

import 'dart:collection';

String alienOrder(List<String> words) {
  final graph = <String, Set<String>>{};
  final indegree = <String, int>{};
  for (final w in words) {
    for (final ch in w.split('')) {
      graph.putIfAbsent(ch, () => {});
      indegree.putIfAbsent(ch, () => 0);
    }
  }
  for (var i = 0; i + 1 < words.length; i++) {
    final a = words[i], b = words[i + 1];
    final len = a.length < b.length ? a.length : b.length;
    var j = 0;
    while (j < len && a[j] == b[j]) {
      j++;
    }
    if (j == len) {
      // One word is a prefix of the other: the longer one must come second.
      if (a.length > b.length) return '';
      continue;
    }
    // Only the first difference gives information: a[j] comes before b[j].
    if (graph[a[j]]!.add(b[j])) indegree[b[j]] = indegree[b[j]]! + 1;
  }
  final queue = Queue<String>.of([
    for (final e in indegree.entries)
      if (e.value == 0) e.key,
  ]);
  final order = StringBuffer();
  while (queue.isNotEmpty) {
    final ch = queue.removeFirst();
    order.write(ch);
    for (final next in graph[ch]!) {
      indegree[next] = indegree[next]! - 1;
      if (indegree[next] == 0) queue.add(next);
    }
  }
  // Letters left over are on a cycle: the ordering is contradictory.
  return order.length == indegree.length ? order.toString() : '';
}

/// Checks that [order] is consistent with [words] (any valid order is accepted).
bool isValidOrder(List<String> words, String order) {
  final rank = {for (var i = 0; i < order.length; i++) order[i]: i};
  for (var i = 0; i + 1 < words.length; i++) {
    final a = words[i], b = words[i + 1];
    var j = 0;
    while (j < a.length && j < b.length && a[j] == b[j]) {
      j++;
    }
    if (j == a.length || j == b.length) {
      if (a.length > b.length) return false;
    } else if (rank[a[j]]! > rank[b[j]]!) {
      return false;
    }
  }
  return true;
}
```

<!-- CODE:END -->

### Walkthrough

- The first loop registers every letter as a node with in-degree 0.
- For each adjacent pair, scan to the first difference `j`. If none, check the prefix rule. Otherwise add the edge `a[j] -> b[j]`.
- `graph[a[j]]!.add(b[j])` returns false if the edge already exists, so duplicate facts do not inflate in-degrees. Counting a duplicate edge twice would leave `b[j]` with a positive in-degree forever and falsely report a cycle.
- Kahn's loop, then the cycle check `order.length == indegree.length`.
- `isValidOrder` is a checker used by the tests, because many answers can be valid.

## Step 6: Dry run

Edges: `t -> f`, `w -> e`, `r -> t`, `e -> r`. In-degrees: w 0, r 1, t 1, f 1, e 1.

| queue | pop | output | in-degree changes |
|---|---|---|---|
| w | w | w | e: 0, enqueue e |
| e | e | we | r: 0, enqueue r |
| r | r | wer | t: 0, enqueue t |
| t | t | wert | f: 0, enqueue f |
| f | f | wertf | |

All 5 letters output: `"wertf"`.

## Complexity

Let C be the total number of characters in all words, and U the number of distinct letters (at most 26).

- Time: **O(C)** to build edges (each character is compared at most once per adjacent pair) + **O(U + E)** for the sort, with E at most U^2. Overall O(C).
- Space: **O(U + E)**, which is O(1) for a fixed alphabet of 26 letters.

## Edge cases

- One word: any order of its letters.
- Duplicate adjacent words: no information, no error.
- Letters that appear but have no constraints: output anywhere (in-degree 0 from the start).

## Common mistakes

- Using more than the first differing character of a pair.
- Missing the prefix rule.
- Adding duplicate edges and double counting in-degrees.
- Only adding letters that appear in edges (letters with no constraints go missing from the output).

## Follow-ups you should be ready for

1. **Verifying an Alien Dictionary (LeetCode 953).** Given the order, check the list: the easy direction.
2. **Is the order unique?** Unique if and only if the queue never holds more than one letter at a time during Kahn's algorithm.
3. **Course Schedule I/II (LeetCode 207, 210).** Same topological sort with an explicit edge list.

## What to remember

Each adjacent pair of sorted words gives at most one edge: the first differing letters. The alphabet is a topological order of those edges; a cycle or a longer-word-before-its-prefix means no valid order.
