# Minimum Characters For Words

**Difficulty:** Medium | **Category:** Strings | **Pattern:** Per-key maximum of frequency maps

## The problem

Given a list of words, return the **smallest collection of characters** (with repeats) such that **each** word can be spelled using characters from the collection. Words are spelled **one at a time**, so the same characters can be reused for different words. Order does not matter.

```
["this", "that", "did", "deed", "them!", "a"]
->  ["t", "t", "h", "i", "s", "a", "d", "d", "e", "e", "m", "!"]   (any order)
```

## Step 1: Work an example by hand

How many `t`s do we need? `"that"` needs two, the others need at most one. Since words are spelled separately, two `t`s are enough for every word: **the maximum over words**, not the sum.

How many `d`s? `"did"` needs two, `"deed"` needs two: still two. How many `e`s? `"deed"` needs two, `"them!"` needs one: two.

So for each character, the answer is the **maximum count needed by any single word**.

## Step 2: The algorithm

1. For each word, count its characters (a small map).
2. Merge into a global map by taking, for each character, `max(global, thisWord)`.
3. Expand the global map into a list with each character repeated its count.

## Step 3: The code

<!-- CODE:START -->

Full source: [`minimum_characters_for_words.dart`](minimum_characters_for_words.dart) (run it with `dart run`).

```dart
// Minimum Characters For Words: smallest multiset of characters that can spell each word
// on its own. For every char, take the maximum count needed by any single word.
// O(n * l) time, O(c) space.

List<String> minimumCharactersForWords(List<String> words) {
  final need = <String, int>{};
  for (final word in words) {
    final counts = <String, int>{};
    for (final ch in word.split('')) {
      counts.update(ch, (v) => v + 1, ifAbsent: () => 1);
    }
    counts.forEach((ch, c) {
      if (c > (need[ch] ?? 0)) need[ch] = c;
    });
  }
  return [for (final MapEntry(key: ch, value: c) in need.entries) ...List.filled(c, ch)];
}
```

<!-- CODE:END -->

### Walkthrough

- `need` is the global character -> maximum count map.
- For each word, `counts` holds that word's character counts.
- `counts.forEach((ch, c) { if (c > (need[ch] ?? 0)) need[ch] = c; })` merges with max.
- The final list comprehension uses a pattern (`MapEntry(key: ch, value: c)`) and the spread `...List.filled(c, ch)` to repeat each character.

## Step 4: Dry run (selected characters)

| word | t | d | e | h |
|---|---|---|---|---|
| this | 1 | 0 | 0 | 1 |
| that | **2** | 0 | 0 | 1 |
| did | | **2** | | |
| deed | | 2 | **2** | |
| them! | 1 | | 1 | 1 |
| max | 2 | 2 | 2 | 1 |

## Complexity

- **Time: O(n * l)**, n words of length up to l.
- **Space: O(c)**, the number of distinct characters.

## Common mistakes

- Summing counts across words (that would be the answer if all words had to be spelled **at the same time**).
- Forgetting non-letter characters like `"!"`.

## Follow-ups

1. **Word Subsets (LeetCode #916):** the same max-merge of counts, then filter words that contain the merged requirement.
2. **Spell all words simultaneously:** sum instead of max.

## What to remember

"Each item separately" -> take the per-key maximum. "All items together" -> take the per-key sum. Read which one the problem asks for.
