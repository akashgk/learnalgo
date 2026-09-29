# Reverse Words In String

**Difficulty:** Medium | **Category:** Strings | **Pattern:** Tokenize and reverse (or reverse twice)

## The problem

Reverse the order of the words in a string. Words are separated by one or more spaces, and **all whitespace must be preserved exactly**. The point of the exercise is to implement the logic yourself rather than relying on built-in split/reverse helpers.

```
"AlgoExpert is the best!"  ->  "best! the is AlgoExpert"
"whitespaces    4"         ->  "4    whitespaces"
" leading"                 ->  "leading "
```

## Step 1: Why "split on space and join" is not enough

Splitting on single spaces and joining with single spaces would turn `"whitespaces    4"` (four spaces) into `"4 whitespaces"`. The runs of spaces are part of the data and must move too, mirrored.

## Step 2: Tokens: words AND space runs

Treat the string as a sequence of **tokens** where a token is either a maximal run of non-space characters (a word) or a maximal run of spaces:

```
"whitespaces    4"  ->  ["whitespaces", "    ", "4"]
```

Reversing the token list and concatenating gives `"4" + "    " + "whitespaces"`: exactly right. Space runs stay between the same two words, just in mirrored order.

A token boundary is wherever "is this a space?" changes between two neighboring characters.

## Step 3: The in-place alternative (classic follow-up)

With a **mutable** character array (C, C++, Java `char[]`):

1. reverse the whole string: `"the sky"` -> `"yks eht"`;
2. reverse each word back: `"sky the"`.

O(n) time, O(1) extra space. Dart strings are immutable, so this repo uses tokenizing, but you should know this trick; it also solves "rotate an array by k" (reverse all, then reverse both parts).

## Step 4: The code

<!-- CODE:START -->

Full source: [`reverse_words_in_string.dart`](reverse_words_in_string.dart) (run it with `dart run`).

```dart
// Reverse Words In String, preserving all whitespace exactly (words and space runs are
// both tokens). Tokenize manually, then reverse the token list. O(n) time and space.

String reverseWordsInString(String string) {
  final tokens = <String>[];
  var start = 0;
  for (var i = 1; i <= string.length; i++) {
    final boundary = i == string.length || (string[i] == ' ') != (string[i - 1] == ' ');
    if (boundary) {
      tokens.add(string.substring(start, i));
      start = i;
    }
  }
  return tokens.reversed.join();
}
```

<!-- CODE:END -->

### Walkthrough

- `start` marks where the current token began.
- The loop runs `i = 1..length`; at each `i` it asks whether a token ends just before `i`: either the string ended, or the space/non-space status changed between `i - 1` and `i`.
- `tokens.add(string.substring(start, i));` stores the token; `start = i`.
- `tokens.reversed.join()` concatenates tokens in reverse order.

## Step 5: Dry run on `" leading"`

| i | boundary? | token added | start |
|---|---|---|---|
| 1 | space -> 'l': yes | " " | 1 |
| 2..7 | no (all letters) | | 1 |
| 8 | end of string | "leading" | 8 |

Tokens `[" ", "leading"]` reversed: `"leading "`.

## Complexity

- **Time: O(n)**.
- **Space: O(n)** for the tokens and the result.

## Common mistakes

- Collapsing or trimming whitespace when it must be preserved.
- Forgetting the last token at the end of the string.

## Follow-ups

1. **Reverse Words in a String (LeetCode #151):** the opposite requirement: collapse multiple spaces and trim. Always ask which one is wanted.
2. **Reverse Words in a String III (#557):** reverse each word's characters but keep word order.
3. **Rotate Array (#189):** the "reverse all, then reverse the parts" trick.

## What to remember

Decide what counts as a token (here: words and space runs), reverse the tokens, and rejoin. With mutable arrays, "reverse all, then reverse each word" does it in place.
