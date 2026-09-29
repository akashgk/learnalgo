# First Non-Repeating Character

**Difficulty:** Easy | **Category:** Strings | **Pattern:** Frequency map, two passes

## The problem

Given a string of lowercase letters, return the index of the first character that occurs exactly once in the string. Return -1 if every character repeats.

```
"abcdcaf"        ->  1   ('b' appears once; 'a' and 'c' repeat)
"faadabcbbebdf"  ->  6   ('c')
"aabb"           ->  -1
```

## Step 1: Work an example by hand

`"abcdcaf"`. Is `a` unique? Scan: another `a` at index 5. No. Is `b` unique? Scan the whole string: yes. Answer 1.

For each candidate you scanned the whole string. For long strings that is slow, and you are recounting the same letters again and again.

## Step 2: Brute force

For each index `i`, check every `j != i` for the same character. Return the first `i` with no match. **O(n^2)** time, O(1) space.

## Step 3: Optimize

**Duplicated work:** "how many times does character c appear?" is recomputed for every occurrence of c. Precompute all counts in one pass.

Why two passes and not one? The count of a character is only final after reading the **entire** string (the second `a` might be at the very end). So:

1. **Pass 1:** count every character.
2. **Pass 2:** walk in the original order and return the first index whose character has count 1.

The second pass is what preserves "first" in the original order.

## Step 4: The code

<!-- CODE:START -->

Full source: [`first_non_repeating_character.dart`](first_non_repeating_character.dart) (run it with `dart run`).

```dart
// First Non-Repeating Character: index of the first char that occurs exactly once, else -1.
// Two passes with a frequency map. O(n) time, O(1) space (bounded alphabet).

int firstNonRepeatingCharacter(String string) {
  final freq = <int, int>{};
  for (final c in string.codeUnits) {
    freq.update(c, (v) => v + 1, ifAbsent: () => 1);
  }
  for (var i = 0; i < string.length; i++) {
    if (freq[string.codeUnitAt(i)] == 1) return i;
  }
  return -1;
}
```

<!-- CODE:END -->

### Walkthrough

- Pass 1 fills `freq` with character code -> count.
- Pass 2 checks `freq[string.codeUnitAt(i)] == 1` in index order and returns the first hit.
- `return -1` if no character is unique.

## Step 5: Dry run

`"abcdcaf"`: counts after pass 1 are `{a: 2, b: 1, c: 2, d: 1, f: 1}`.

| i | char | count | result |
|---|---|---|---|
| 0 | a | 2 | continue |
| 1 | b | 1 | **return 1** |

## Complexity

- **Time: O(n)** (two passes).
- **Space: O(1)**: at most 26 keys for lowercase letters. Say why: "the alphabet is fixed, so the map has at most 26 entries". Interviewers want the justification, not just the label.

## Common mistakes

- Returning the character instead of the index (read the output format).
- Trying to do it in one pass by returning the first count-1 character seen so far, which is wrong because counts are not final.

## Follow-ups

1. **Streaming characters (LeetCode #387 follow-up, and "first unique character in a stream"):** answer after every new character. Keep counts plus a queue of candidate characters in arrival order; pop from the front while the front's count is above 1. Each character is pushed and popped at most once, so it is amortized O(1) per character. A `LinkedHashSet` or doubly linked list with a map (like LRU Cache) also works.
2. **Store first index instead of count:** keep `firstIndex` for characters seen once and mark repeats; then the answer is the minimum stored index. This needs only one pass over the string plus one over the (26-entry) map.

## What to remember

When the same count is needed repeatedly, precompute it. When the answer depends on the whole input (like "occurs exactly once"), you need a full pass before answering.
