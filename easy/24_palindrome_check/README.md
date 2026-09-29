# Palindrome Check

**Difficulty:** Easy | **Category:** Strings | **Pattern:** Two pointers

## The problem

Given a non-empty string, return whether it is a palindrome: it reads the same forward and backward.

```
"abcdcba"  ->  true
"abba"     ->  true
"ab"       ->  false
"a"        ->  true
```

### Clarifying questions

- Case-sensitive? Ignore spaces and punctuation? (Here: compare characters exactly. The popular variant ignores non-alphanumerics and case; see Follow-ups.)
- Unicode? (Assume simple characters; see the note at the end.)

## Step 1: Work an example by hand

`"abcdcba"`: compare the first and last characters (`a`, `a`), then the second and second-to-last (`b`, `b`), then (`c`, `c`). Now you reach the middle `d`, which is compared with nothing. All pairs matched: palindrome.

## Step 2: Approaches

**A. Reverse and compare.** Build the reversed string and check equality.

- O(n) time and O(n) extra space for the copy.
- Warning: building the reversed string with repeated `+=` in a loop is **O(n^2)** in most languages (each concatenation copies the string). Use a buffer or a built-in reverse.

**B. Recursion.** `isPal(s) = s[0] == s[last] && isPal(middle of s)`. Elegant but O(n) stack and, if you create substrings, O(n^2) copying.

**C. Two pointers (best).** One pointer at each end, compare, move both inward, stop when they meet. O(n) time, **O(1) space**.

## Step 3: The code

<!-- CODE:START -->

Full source: [`palindrome_check.dart`](palindrome_check.dart) (run it with `dart run`).

```dart
// Palindrome Check. Two pointers from both ends. O(n) time, O(1) space.

bool isPalindrome(String string) {
  var lo = 0, hi = string.length - 1;
  while (lo < hi) {
    if (string.codeUnitAt(lo) != string.codeUnitAt(hi)) return false;
    lo++;
    hi--;
  }
  return true;
}
```

<!-- CODE:END -->

### Walkthrough

- `var lo = 0, hi = string.length - 1;` start at both ends.
- `while (lo < hi)` stops when the pointers meet (odd length, middle character) or cross (even length).
- `string.codeUnitAt(lo) != string.codeUnitAt(hi)` compares character codes; returning early on the first mismatch.

## Step 4: Dry run

`"abba"`:

| lo | hi | chars | equal? |
|---|---|---|---|
| 0 | 3 | a, a | yes |
| 1 | 2 | b, b | yes |
| 2 | 1 | | stop, return true |

## Complexity

- **Time: O(n)**: at most n/2 comparisons.
- **Space: O(1)**.

## Edge cases

- Empty string or one character: true (loop does not run).
- Even vs odd length: both handled by `lo < hi`.

## Common mistakes

- `while (lo <= hi)` is harmless here (comparing the middle with itself) but shows an unclear invariant.
- Building the reversed string with `+=` in a loop (O(n^2)).

## Follow-ups

1. **Valid Palindrome (LeetCode #125):** ignore non-alphanumeric characters and case. Skip non-alphanumerics with inner `while` loops on each pointer, then compare lowercase characters.
2. **Valid Palindrome II (LeetCode #680):** may delete at most one character. On the first mismatch, check whether `s[lo+1..hi]` or `s[lo..hi-1]` is a palindrome.
3. **Longest Palindromic Substring (medium 67)** and **Palindrome Partitioning Min Cuts (very hard 13).**
4. **Linked list palindrome (very hard 26):** no random access, so find the middle and reverse half.

## Unicode note

`codeUnitAt` compares UTF-16 code units. Emoji and some other characters use two code units (a surrogate pair), and accented letters may be composed of several code points. Reversing code units can break them. For real text, compare `string.runes` or grapheme clusters (`package:characters`). Mentioning this in an interview shows production awareness.

## What to remember

Two pointers from both ends, move inward, stop at the first mismatch: O(n) time, O(1) space.
