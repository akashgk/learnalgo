# Valid Palindrome

**Difficulty:** Easy | **Category:** Two Pointers | **Pattern:** Two pointers skipping ignored characters | **Source:** LeetCode 125; NeetCode 150, Blind 75

## The problem

After converting uppercase letters to lowercase and removing every non-alphanumeric character, does the string read the same forwards and backwards?

```
"A man, a plan, a canal: Panama"  ->  true   ("amanaplanacanalpanama")
"race a car"                      ->  false  ("raceacar")
" "                               ->  true   (empty after cleaning)
```

AlgoExpert easy 24 Palindrome Check is the plain version without cleaning.

## Step 1: Simple version

Build the cleaned string, then compare it with its reverse. O(n) time, **O(n) extra space** for the copy. Perfectly fine as a first answer.

## Step 2: No copy

Use two pointers from both ends of the **original** string. At each step:

- if the left character is ignored (not a letter or digit), move left forward;
- else if the right character is ignored, move right backward;
- else compare them case-insensitively; a mismatch means false; otherwise move both inward.

Moving one pointer at a time in the skip branches keeps the logic simple: each loop iteration does exactly one thing.

## Step 3: The code

<!-- CODE:START -->

Full source: [`valid_palindrome.dart`](valid_palindrome.dart) (run it with `dart run`).

```dart
// Valid Palindrome: after lowercasing and removing every non-alphanumeric character,
// does the string read the same both ways? Two pointers that skip ignored characters.
// O(n) time, O(1) extra space (no cleaned copy).

bool isPalindrome(String s) {
  var lo = 0, hi = s.length - 1;
  while (lo < hi) {
    if (!_isAlnum(s.codeUnitAt(lo))) {
      lo++;
    } else if (!_isAlnum(s.codeUnitAt(hi))) {
      hi--;
    } else {
      if (_lower(s.codeUnitAt(lo)) != _lower(s.codeUnitAt(hi))) return false;
      lo++;
      hi--;
    }
  }
  return true;
}

bool _isAlnum(int c) => (c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122);

/// ASCII lowercase: 'A'..'Z' (65..90) differ from 'a'..'z' by 32.
int _lower(int c) => (c >= 65 && c <= 90) ? c + 32 : c;
```

<!-- CODE:END -->

### Walkthrough

- `_isAlnum` checks the ASCII ranges `0-9`, `A-Z`, `a-z` by code unit.
- `_lower` adds 32 to uppercase letters (in ASCII, `'a' - 'A' == 32`); digits and lowercase letters pass through.
- The loop ends when the pointers meet or cross; a middle character never needs checking.

## Step 4: Dry run

`"0P"`:

| lo | hi | chars | action |
|---|---|---|---|
| 0 | 1 | '0', 'P' | both alphanumeric, '0' != 'p': **false** |

`".,"`: both are skipped; the pointers cross with nothing compared: **true**.

## Complexity

- Time: **O(n)**. Each step moves at least one pointer.
- Space: **O(1)**.

## Edge cases

- Only punctuation or spaces: true.
- Digits count as alphanumeric (`"0P"` is false).
- Mixed case (`"Aa"`): true.

## Common mistakes

- Forgetting digits.
- Lowercasing with a library call that handles Unicode differently than the problem expects (LeetCode's input is ASCII).
- Skipping with nested `while` loops that do not re-check `lo < hi` (index out of range on strings of only punctuation).

## Follow-ups you should be ready for

1. **Valid Palindrome II (LeetCode 680).** You may delete at most one character: on the first mismatch, check whether skipping the left or the right character leaves a palindrome.
2. **Longest palindromic substring.** Expand around centers; see AlgoExpert medium 67.
3. **Unicode letters.** Use `RegExp(r'[\p{L}\p{N}]', unicode: true)` to classify characters.

## What to remember

Two pointers can skip characters in place instead of building a cleaned copy. Advance only one pointer per iteration when skipping.
