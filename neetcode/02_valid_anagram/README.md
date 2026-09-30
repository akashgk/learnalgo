# Valid Anagram

**Difficulty:** Easy | **Category:** Arrays & Hashing | **Pattern:** Frequency counting | **Source:** LeetCode 242; NeetCode 150, Blind 75

## The problem

Return true if `t` is an anagram of `s`: the same characters with the same counts, in any order.

```
"anagram", "nagaram"  ->  true
"rat", "car"          ->  false
```

## Step 1: Two ideas

1. **Sort both strings** and compare: anagrams have the same sorted form. O(n log n).
2. **Count characters.** Anagrams have identical character counts. O(n).

## Step 2: One counter instead of two

Instead of building two count maps and comparing them, use **one** map: add 1 for each character of `s`, subtract 1 for each character of `t`. The strings are anagrams exactly when every count ends at 0.

Check the lengths first: different lengths can never be anagrams, and equal lengths let one loop handle both strings.

## Step 3: The code

<!-- CODE:START -->

Full source: [`valid_anagram.dart`](valid_anagram.dart) (run it with `dart run`).

```dart
// Valid Anagram: is t a rearrangement of s?
// Count characters up for s and down for t; every count must end at zero. O(n) time, O(k) space
// (k = alphabet size; 26 for lowercase letters).

bool isAnagram(String s, String t) {
  if (s.length != t.length) return false;
  final count = <int, int>{}; // code unit -> net count (a map also handles non-lowercase input)
  for (var i = 0; i < s.length; i++) {
    count[s.codeUnitAt(i)] = (count[s.codeUnitAt(i)] ?? 0) + 1;
    count[t.codeUnitAt(i)] = (count[t.codeUnitAt(i)] ?? 0) - 1;
  }
  return count.values.every((c) => c == 0);
}
```

<!-- CODE:END -->

### Walkthrough

- `count` maps a character code to its net count. A `List.filled(26, 0)` is faster for lowercase letters only; the map also handles Unicode code units (see the follow-up).
- Both strings are processed in the same loop because their lengths are equal.
- `every((c) => c == 0)` checks that nothing is left over.

## Step 4: Dry run

`"rat"`, `"car"`:

| i | s[i] | t[i] | counts after |
|---|---|---|---|
| 0 | r | c | r:1, c:-1 |
| 1 | a | a | r:1, c:-1, a:0 |
| 2 | t | r | r:0, c:-1, a:0, t:1 |

`c` and `t` are nonzero: **false**.

## Complexity

- Time: **O(n)**.
- Space: **O(k)**, k = number of distinct characters (26 for lowercase letters, so O(1)).

## Edge cases

- Different lengths: false immediately.
- Empty strings: true.
- Same letters, different counts (`"aacc"`, `"ccac"`): false.

## Common mistakes

- Comparing sets of characters (ignores counts).
- Forgetting the length check when using one loop over both strings.

## Follow-ups you should be ready for

1. **Unicode.** Dart strings are UTF-16; characters outside the Basic Multilingual Plane use two code units. Count `runes` (code points), or grapheme clusters with `package:characters` for user-perceived characters.
2. **Group Anagrams.** Use the sorted string (or the count tuple) as a map key; see AlgoExpert medium 68.
3. **Find All Anagrams in a String (LeetCode 438).** Sliding window of counts; see neetcode 06 Permutation in String.

## What to remember

Anagram = same multiset of characters. One counter up for `s`, down for `t`, all zeros at the end.
