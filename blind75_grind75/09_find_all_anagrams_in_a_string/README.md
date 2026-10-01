# Find All Anagrams in a String

**Difficulty:** Medium | **Category:** Sliding Window | **Pattern:** Fixed-size window with a matching-letters counter | **Source:** LeetCode 438; Grind 75

## The problem

Return all start indices of substrings of `s` that are anagrams of `p` (lowercase letters).

```
s = "cbaebabacd", p = "abc"  ->  [0, 6]     ("cba" and "bac")
s = "abab", p = "ab"         ->  [0, 1, 2]
```

This is Permutation in String (neetcode 06) returning **every** match instead of the first.

## Step 1: Fixed-size windows

An anagram of `p` has exactly `|p|` letters. Check every window of that length: does it have the same letter counts as `p`?

Brute force recounts each window: O(|s| * |p|).

## Step 2: Slide, and compare in O(1)

Moving the window right by one changes two counts (one letter enters, one leaves). Keep a running count `have` for the window and the fixed `need` for `p`.

To avoid comparing 26 counts per step, track `matches`: how many of the 26 letters currently have `have == need`. When a count changes, only that letter's status can flip:

- equal before the change: `matches--`;
- equal after the change: `matches++`.

The window is an anagram exactly when `matches == 26`.

## Step 3: The code

<!-- CODE:START -->

Full source: [`find_all_anagrams_in_a_string.dart`](find_all_anagrams_in_a_string.dart) (run it with `dart run`).

```dart
// Find All Anagrams in a String: start indices of every substring of s that is an anagram of p
// (lowercase letters). Fixed-size sliding window with a count of letters whose counts match.
// O(|s| + |p|) time, O(1) space.

List<int> findAnagrams(String s, String p) {
  final n = p.length, result = <int>[];
  if (n > s.length) return result;
  final need = List<int>.filled(26, 0), have = List<int>.filled(26, 0);
  for (var i = 0; i < n; i++) {
    need[p.codeUnitAt(i) - 97]++;
    have[s.codeUnitAt(i) - 97]++;
  }
  var matches = 0; // how many of the 26 letters have equal counts in window and p
  for (var c = 0; c < 26; c++) {
    if (need[c] == have[c]) matches++;
  }
  if (matches == 26) result.add(0);
  for (var right = n; right < s.length; right++) {
    matches = _update(need, have, s.codeUnitAt(right) - 97, 1, matches); // enters
    matches = _update(need, have, s.codeUnitAt(right - n) - 97, -1, matches); // leaves
    if (matches == 26) result.add(right - n + 1);
  }
  return result;
}

int _update(List<int> need, List<int> have, int c, int delta, int matches) {
  if (have[c] == need[c]) matches--;
  have[c] += delta;
  if (have[c] == need[c]) matches++;
  return matches;
}
```

<!-- CODE:END -->

### Walkthrough

- The first window (index 0) is checked before the loop.
- Each loop step adds the entering letter, removes the leaving one, and records the new window's start `right - n + 1` if it matches.

## Step 4: Dry run

`s = "cbaebabacd"`, `p = "abc"`. Windows of length 3:

| start | window | anagram? |
|---|---|---|
| 0 | cba | **yes** |
| 1 | bae | no |
| 2 | aeb | no |
| 3 | eba | no |
| 4 | bab | no |
| 5 | aba | no |
| 6 | bac | **yes** |
| 7 | acd | no |

Result `[0, 6]`.

## Complexity

- Time: **O(|s| + |p|)**.
- Space: **O(1)** (26-element arrays).

## Edge cases

- `p` longer than `s`: empty result.
- Overlapping matches (`"aaaa"`, `"aa"`): every start counts.

## Common mistakes

- Forgetting the first window.
- Off-by-one in the start index (`right - n + 1`).
- Comparing sorted substrings for every window (O(|s| * |p| log |p|)).

## Follow-ups you should be ready for

1. **Permutation in String.** Return true at the first match; neetcode 06.
2. **Minimum Window Substring.** Variable-size window with "contains" instead of "equals"; AlgoExpert very_hard 35.
3. **Unicode or large alphabets.** Use maps and track matches only over letters of `p`.

## What to remember

All anagram windows: slide a fixed-size window, update two counts per step, and keep a counter of matching letters so each step is O(1).
