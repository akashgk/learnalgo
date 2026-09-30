# Encode and Decode Strings

**Difficulty:** Medium | **Category:** Arrays & Hashing | **Pattern:** Length-prefix framing | **Source:** LeetCode 271 (premium); NeetCode 150, Blind 75

## The problem

Design `encode(List<String>) -> String` and `decode(String) -> List<String>` so that `decode(encode(x)) == x` for **any** list of strings. The strings may contain any characters, including whatever you would like to use as a separator.

```
["neet", "code", "love", "you"]  ->  "4#neet4#code4#love3#you"  ->  back to the list
```

## Step 1: Why a separator alone fails

Join with `","`: `["a,b", "c"]` and `["a", "b", "c"]` both encode to `"a,b,c"`. Two different inputs, one output: decoding is impossible. Any single separator character can appear inside a string.

**Escaping** fixes it (write `,` as `\,` and `\` as `\\`), just like CSV or JSON. It works, but decoding must scan every character and handle escape sequences carefully.

## Step 2: Tell the decoder how long each string is

Write each string as `<length>#<string>`. The decoder:

1. reads digits up to the first `#`: that is the length `L`,
2. takes the next `L` characters **blindly** as the string, no matter what they contain,
3. continues right after them.

The `#` inside a payload is never inspected, because the decoder jumps over the payload by length. The `#` after the digits is safe to search for, because the length field contains only digits.

This is exactly how real protocols frame messages (HTTP `Content-Length`, length-prefixed binary formats such as Protocol Buffers).

## Step 3: The code

<!-- CODE:START -->

Full source: [`encode_and_decode_strings.dart`](encode_and_decode_strings.dart) (run it with `dart run`).

```dart
// Encode and Decode Strings: turn a list of arbitrary strings into one string and back.
// Length-prefix framing: each string is written as "<length>#<string>". The decoder reads the
// length first, so '#' (or any character) inside the strings is harmless. O(total length) both ways.

String encode(List<String> strs) {
  final out = StringBuffer();
  for (final s in strs) {
    out
      ..write(s.length)
      ..write('#')
      ..write(s);
  }
  return out.toString();
}

List<String> decode(String data) {
  final result = <String>[];
  var i = 0;
  while (i < data.length) {
    final hash = data.indexOf('#', i); // the first '#' after i ends the length field
    final length = int.parse(data.substring(i, hash));
    final start = hash + 1;
    result.add(data.substring(start, start + length));
    i = start + length; // jump over the payload without inspecting it
  }
  return result;
}
```

<!-- CODE:END -->

### Walkthrough

- `encode` writes the length, a `#`, then the raw string.
- `decode` uses `indexOf('#', i)` to find the end of the length field starting at `i`. That `#` is the first one after `i`, and it must belong to the header because the header is only digits.
- `i = start + length` skips the payload.

## Step 4: Dry run

`["a#b", "12#", "#", ""]` encodes to `3#a#b3#12#1##0#`.

| i | header | length | payload | next i |
|---|---|---|---|---|
| 0 | `3#` | 3 | `a#b` | 5 |
| 5 | `3#` | 3 | `12#` | 10 |
| 10 | `1#` | 1 | `#` | 13 |
| 13 | `0#` | 0 | `` | 15 (end) |

## Complexity

- Time: **O(total length)** for both functions.
- Space: **O(total length)** for the output.

## Edge cases

- Empty list: encodes to `""`, decodes to `[]`.
- A list with one empty string: `"0#"` decodes to `[""]`. (Note this differs from the empty list: the framing preserves it.)
- Strings with digits and `#`.

## Common mistakes

- Using a separator without escaping.
- Searching for `#` from the start of the whole string instead of from the current position.
- Using a fixed-width length field that is too small (4 bytes is common in binary protocols; decimal with a terminator avoids the limit).

## Follow-ups you should be ready for

1. **Binary version.** Write each length as a fixed 4-byte integer; no terminator needed.
2. **Streaming.** The decoder can emit each string as soon as its payload has arrived, because it knows the length in advance.
3. **Escaping-based alternative.** Double every `#` inside strings and use `" # "` as a separator; explain why it is more error-prone.

## What to remember

To delimit arbitrary data, put the length first. The decoder then never has to interpret the payload.
