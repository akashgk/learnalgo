# Run-Length Encoding

**Difficulty:** Easy | **Category:** Strings | **Pattern:** Track runs in one pass

## The problem

Encode a non-empty string with run-length encoding: each run of identical consecutive characters becomes `<length><character>`. Runs longer than 9 must be split into runs of at most 9.

```
"AAAAAAAAAAAAABBCCCCDD"  ->  "9A4A2B4C2D"
"aA"                     ->  "1a1A"
"122333"                 ->  "112233"
```

### Why the 9 limit?

Because the input may contain digits, a multi-digit count would be ambiguous. For example, the encoded string `"1213"` could decode as `"23"` (one `2`, then one `3`) or as 121 copies of `3`. Both readings are valid. With counts capped at 9, every run is **exactly one digit followed by one character**, so the encoding splits into fixed-size pairs and decoding is trivial and unambiguous.

## Step 1: Work an example by hand

`"AAAAAAAAAAAAABBCCCCDD"` has 13 A's, 2 B's, 4 C's, 2 D's.

- The A-run reaches 9: emit `"9A"`, start a new run. 4 A's remain: `"4A"`.
- Then `"2B"`, `"4C"`, `"2D"`.

Result: `"9A4A2B4C2D"`.

## Step 2: The approach

Scan left to right with a counter for the current run. A run **ends** when:

1. the next character is different, or
2. the run has reached 9, or
3. the string ends.

When a run ends, append the count and the character, then reset the counter.

**Avoiding the "forgot the last run" bug:** most implementations loop to `length - 1` and then need a separate flush after the loop, which people forget. This implementation loops to `i == length` and treats "end of string" as one of the run-ending conditions inside the loop.

## Step 3: The code

<!-- CODE:START -->

Full source: [`run_length_encoding.dart`](run_length_encoding.dart) (run it with `dart run`).

```dart
// Run-Length Encoding with runs capped at 9 so the output stays unambiguous
// ("AAAAAAAAAAAA" -> "9A3A"). O(n) time, O(n) space.

String runLengthEncoding(String string) {
  final out = StringBuffer();
  var runLength = 1;
  for (var i = 1; i <= string.length; i++) {
    final atEnd = i == string.length;
    if (atEnd || string[i] != string[i - 1] || runLength == 9) {
      out
        ..write(runLength)
        ..write(string[i - 1]);
      runLength = 0;
    }
    runLength++;
  }
  return out.toString();
}
```

<!-- CODE:END -->

### Walkthrough

- `final out = StringBuffer();` builds the output efficiently (appending to a buffer is amortized O(1); `+=` on strings copies every time).
- `var runLength = 1;` counts the character at index 0.
- The loop visits `i = 1..length`. At each step it decides whether the run that ends at `i - 1` is finished.
- `if (atEnd || string[i] != string[i - 1] || runLength == 9)` has the three ending conditions. Order matters: `atEnd` is checked first, so `string[i]` is never read out of bounds (short-circuit evaluation).
- On a finished run: write the count and `string[i - 1]`, reset `runLength = 0`. The `runLength++` at the end of the iteration then counts `string[i]` as the first character of the next run.

## Step 4: Dry run

`"AAAB"`:

| i | atEnd | string[i] vs string[i-1] | runLength before | run ends? | output | runLength after |
|---|---|---|---|---|---|---|
| 1 | no | A == A | 1 | no | "" | 2 |
| 2 | no | A == A | 2 | no | "" | 3 |
| 3 | no | B != A | 3 | yes | "3A" | 1 |
| 4 | yes | | 1 | yes | "3A1B" | 1 |

## Complexity

- **Time: O(n)**.
- **Space: O(n)** for the output.

## Edge cases

- Digits in the input (`"122333"` -> `"112233"`): fine, because every run is one digit + one character.
- Mixed case: `'a'` and `'A'` are different characters.
- Exactly 9, exactly 10, exactly 18 repeats: test these boundaries.

## Common mistakes

- Forgetting to flush the last run.
- Checking `runLength == 9` after incrementing in a way that produces runs of 10.
- String concatenation in a loop (O(n^2)).

## Follow-ups

1. **Decoder:** read pairs `(digit, char)` and repeat.
2. **String Compression (LeetCode #443):** compress in place in a char array; write pointer and read pointer.
3. **When is RLE useful?** Data with long runs (simple images, fax, some genome data). On text it usually makes things bigger (`"ab"` becomes `"1a1b"`).

## What to remember

Track the current run; define precisely when a run ends (including end of input); use a buffer for output.
