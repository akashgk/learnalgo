# Group Anagrams

**Difficulty:** Medium | **Category:** Strings | **Pattern:** Canonical key + hash map grouping

## The problem

Given a list of words, group together the words that are **anagrams** of each other (same letters with the same counts, in any order). Return the groups in any order.

```
["yo", "act", "flop", "tac", "foo", "cat", "oy", "olfp"]
->  [["yo", "oy"], ["act", "tac", "cat"], ["flop", "olfp"], ["foo"]]
```

## Step 1: Brute force

For each word, compare it with every existing group's representative using an anagram check (sort both, or count letters). O(w^2 * n) for w words of length up to n.

## Step 2: The canonical key idea

Anagrams look different but share a **canonical form**: something that is identical for all words in a group and different across groups. If we can compute that key, grouping is a single hash map pass: `key -> list of words`.

Two good keys:

| Key | Example for "tac" | Cost per word |
|---|---|---|
| Sorted letters | `"act"` | O(n log n) |
| Letter-count signature | `"1#0#1#0#...#1#..."` (26 counts) | O(n) |

For the count signature, include separators: without them, counts like `1, 11` and `11, 1` would both serialize to `"111"`.

## Step 3: The code

<!-- CODE:START -->

Full source: [`group_anagrams.dart`](group_anagrams.dart) (run it with `dart run`).

```dart
// Group Anagrams: key each word by its sorted letters. O(w * n log n) time, O(w * n) space.
// (A 26-count signature key gives O(w * n).)

List<List<String>> groupAnagrams(List<String> words) {
  final groups = <String, List<String>>{};
  for (final word in words) {
    final key = String.fromCharCodes(word.codeUnits.toList()..sort());
    (groups[key] ??= []).add(word);
  }
  return groups.values.toList();
}
```

<!-- CODE:END -->

### Walkthrough

- `word.codeUnits.toList()..sort()` sorts the characters; `String.fromCharCodes` turns them back into the key.
- `(groups[key] ??= []).add(word);` gets the group list for this key, creating it if missing, then appends. This is the idiomatic Dart "get or create".
- `groups.values.toList()` returns the groups. Dart's default `Map` preserves insertion order, which is why the test output order is predictable.

## Step 4: Dry run

| word | key | groups after |
|---|---|---|
| yo | oy | {oy: [yo]} |
| act | act | {..., act: [act]} |
| flop | flop | {..., flop: [flop]} |
| tac | act | act: [act, tac] |
| foo | foo | {..., foo: [foo]} |
| cat | act | act: [act, tac, cat] |
| oy | oy | oy: [yo, oy] |
| olfp | flop | flop: [flop, olfp] |

## Complexity

- **Time: O(w * n log n)** with sorted keys; O(w * n) with count keys.
- **Space: O(w * n)** for the map.

## Common mistakes

- Using a set of letters as the key (loses counts: "aab" and "abb" would collide).
- Count keys without separators.

## Follow-ups

1. **Group Anagrams (LeetCode #49):** identical.
2. **Group Shifted Strings (#249):** key = differences between consecutive letters modulo 26.
3. **Find All Anagrams in a String (#438):** sliding window of letter counts.

## What to remember

To group "equivalent" items, compute a canonical key that is equal exactly for equivalent items, then group with a hash map.
