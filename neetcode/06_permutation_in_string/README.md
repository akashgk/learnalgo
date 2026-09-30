# Permutation in String

**Difficulty:** Medium | **Category:** Sliding Window | **Pattern:** Fixed-size window with a "matches" counter | **Source:** LeetCode 567; NeetCode 150

## The problem

Given lowercase strings `s1` and `s2`, return true if some **substring** of `s2` is a permutation of `s1` (an anagram of it).

```
s1 = "ab", s2 = "eidbaooo"  ->  true   ("ba")
s1 = "ab", s2 = "eidboaoo"  ->  false
```

## Step 1: Reduce to anagram checks

A permutation of `s1` has exactly `|s1|` characters, so only windows of length `|s1|` in `s2` matter. The question is: does any such window have the **same letter counts** as `s1`?

## Step 2: Brute force

For each of the `|s2| - |s1| + 1` windows, count its letters and compare with `s1`'s counts: O(|s2| * |s1|) (or O(|s2| * 26) with count arrays).

## Step 3: Slide the window

Moving the window one step to the right changes exactly two counts: the entering letter +1, the leaving letter -1. So maintain `have` (window counts) incrementally, and compare with `need`. Comparing 26 counts per step gives O(26 * |s2|), already linear.

## Step 4: O(1) comparison per step

Track `matches` = number of letters (out of 26) whose `have` count equals `need`. The window is an anagram exactly when `matches == 26`.

When one count changes, only that letter's match status can change:

- if it matched before the change, it no longer does: `matches--`;
- after the change, if it matches now: `matches++`.

That is what `_update` does. Each slide costs O(1).

## Step 5: The code

<!-- CODE:START -->

Full source: [`permutation_in_string.dart`](permutation_in_string.dart) (run it with `dart run`).

```dart
// Permutation in String: does s2 contain some permutation of s1 as a substring?
// Fixed-size sliding window of length |s1| with letter counts, plus a counter of how many of the
// 26 letters currently have equal counts. O(|s2|) time, O(1) space.

bool checkInclusion(String s1, String s2) {
  final n = s1.length;
  if (n > s2.length) return false;
  final need = List<int>.filled(26, 0), have = List<int>.filled(26, 0);
  for (var i = 0; i < n; i++) {
    need[s1.codeUnitAt(i) - 97]++;
    have[s2.codeUnitAt(i) - 97]++;
  }
  var matches = 0; // letters whose counts agree between the window and s1
  for (var c = 0; c < 26; c++) {
    if (need[c] == have[c]) matches++;
  }
  for (var right = n; right < s2.length; right++) {
    if (matches == 26) return true;
    // Slide: letter entering on the right, letter leaving on the left.
    matches = _update(need, have, s2.codeUnitAt(right) - 97, 1, matches);
    matches = _update(need, have, s2.codeUnitAt(right - n) - 97, -1, matches);
  }
  return matches == 26;
}

/// Changes have[c] by [delta] and returns the updated number of matching letters.
int _update(List<int> need, List<int> have, int c, int delta, int matches) {
  if (have[c] == need[c]) matches--; // it matched before the change, so it no longer does
  have[c] += delta;
  if (have[c] == need[c]) matches++;
  return matches;
}
```

<!-- CODE:END -->

### Walkthrough

- The first loop fills `need` from `s1` and `have` from the first window of `s2`.
- `matches` is initialized by comparing all 26 letters once.
- In the main loop, the check `matches == 26` happens **before** sliding, so it tests the current window; the final `return` tests the last window.
- `_update` handles "was equal, now different" and "was different, now equal" symmetrically.

## Step 6: Dry run

`s1 = "ab"`, `s2 = "eidbaooo"`. Windows of length 2 and whether their counts match `{a:1, b:1}`:

| window | counts | anagram? |
|---|---|---|
| ei | e1 i1 | no |
| id | i1 d1 | no |
| db | d1 b1 | no |
| ba | b1 a1 | **yes**: `matches` reaches 26, return true |

## Complexity

- Time: **O(|s1| + |s2|)**.
- Space: **O(1)** (two arrays of 26).

## Edge cases

- `s1` longer than `s2`: false.
- `s1 == s2`: true (the whole string is a window).
- Repeated letters (`"aab"`): counts, not sets, are compared.

## Common mistakes

- Using a variable-size window (this one is fixed at `|s1|`).
- Forgetting to test the last window after the loop.
- Updating `matches` without first checking whether the letter matched before the change.

## Follow-ups you should be ready for

1. **Find All Anagrams in a String (LeetCode 438).** Same loop; record every window start where `matches == 26`.
2. **Minimum Window Substring (AlgoExpert very_hard 35 Smallest Substring Containing).** Variable-size window: the target letters must be contained, not matched exactly.
3. **Large alphabets.** Use a map for counts and track matches over the letters of `s1` only.

## What to remember

For "is some window an anagram", slide a fixed-size window, update two counts per step, and keep a running count of matching letters so each step is O(1).
