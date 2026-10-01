# Longest Palindrome

**Difficulty:** Easy | **Category:** Hashing / Greedy | **Pattern:** Count pairs, allow one odd center | **Source:** LeetCode 409; Grind 75

## The problem

Given a string of upper- and lowercase letters, return the length of the longest palindrome that can be **built** by rearranging some of its letters (each letter used at most as many times as it appears). Letters are case-sensitive.

```
"abccccdd"  ->  7    e.g. "dccaccd"
"a"         ->  1
"Aa"        ->  1    ('A' and 'a' are different)
```

Not to be confused with Longest Palindromic Substring (AlgoExpert medium 67): here the letters can be rearranged freely.

## Step 1: The structure of a palindrome

A palindrome reads the same from both ends, so its letters come in **mirrored pairs**, plus at most **one** unpaired letter in the exact center.

So any letter can contribute all of its complete pairs: a letter appearing c times contributes `c ~/ 2 * 2` letters. If **any** letter has an odd count, one leftover letter can be placed in the middle: add 1 once.

## Step 2: Why this is optimal

Every palindrome uses at most `c ~/ 2` pairs of each letter (there are not more pairs available), and at most one center letter. The greedy construction reaches both bounds at once.

## Step 3: The code

<!-- CODE:START -->

Full source: [`longest_palindrome.dart`](longest_palindrome.dart) (run it with `dart run`).

```dart
// Longest Palindrome (LeetCode 409): length of the longest palindrome that can be BUILT from the
// letters of s (case-sensitive), using each letter at most as often as it appears.
// Every pair of equal letters can be placed symmetrically; one odd leftover can sit in the middle.
// O(n) time, O(1) space (52 letters).

int longestPalindrome(String s) {
  final count = <int, int>{};
  for (final c in s.codeUnits) {
    count[c] = (count[c] ?? 0) + 1;
  }
  var length = 0;
  var hasOdd = false;
  for (final c in count.values) {
    length += c ~/ 2 * 2; // all complete pairs
    if (c.isOdd) hasOdd = true;
  }
  return hasOdd ? length + 1 : length; // one leftover letter in the center
}
```

<!-- CODE:END -->

### Walkthrough

- `count` maps each code unit to its frequency (case-sensitive by construction).
- `c ~/ 2 * 2` drops the odd leftover.
- `hasOdd` decides whether the center slot is used.

## Step 4: Dry run

`"abccccdd"`: counts a 1, b 1, c 4, d 2.

| letter | count | pairs used | odd? |
|---|---|---|---|
| a | 1 | 0 | yes |
| b | 1 | 0 | yes |
| c | 4 | 4 | no |
| d | 2 | 2 | no |

Pairs: 6, plus 1 center = **7**.

## Complexity

- Time: **O(n)**.
- Space: **O(1)** (at most 52 distinct letters).

## Edge cases

- All letters distinct: 1.
- All counts even: no center, the whole string.

## Common mistakes

- Adding 1 for **every** odd count instead of once.
- Adding odd counts entirely (`3` contributes 2 to the pairs, not 3, unless it is the single center).
- Ignoring case-sensitivity.

## Follow-ups you should be ready for

1. **Can a permutation of the string be a palindrome? (LeetCode 266).** True iff at most one letter has an odd count.
2. **Build the palindrome.** Place half of each pair on the left, the mirror on the right, and one odd letter in the middle.
3. **Palindrome Pairs, Longest Palindromic Subsequence.** Order matters there; see more_problems 40.

## What to remember

A palindrome is pairs plus at most one center. Count each letter's pairs, and add 1 if any letter has an odd count.
