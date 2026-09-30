# Decode Ways

**Difficulty:** Medium | **Category:** 1-D Dynamic Programming | **Pattern:** Linear DP over the last one or two characters | **Source:** LeetCode 91; NeetCode 150, Blind 75

## The problem

Letters are encoded as `A = 1, ..., Z = 26`. Given a digit string, count how many ways it can be decoded.

```
"12"     ->  2   ("AB" or "L")
"226"    ->  3   ("BBF", "BZ", "VF")
"06"     ->  0   ("06" is not a valid code, and "0" alone is not a letter)
"11106"  ->  2   ("AAJF", "KJF")
```

## Step 1: Think about the last step

A decoding of the first `i` digits ends with either:

- a **one-digit** code: the last digit alone, valid if it is `1`..`9`;
- a **two-digit** code: the last two digits, valid if they form `10`..`26` (no leading zero).

These two cases are disjoint (the last letter uses one digit or two), so the counts **add**:

```
dp[i] = (s[i-1] != '0' ? dp[i-1] : 0) + (10 <= s[i-2..i-1] <= 26 ? dp[i-2] : 0)
dp[0] = 1   (the empty prefix has one decoding: nothing)
```

## Step 2: Zeros are the whole difficulty

A `0` can only appear as the second digit of `10` or `20`. So:

- `"10"`: the `0` alone is invalid, but `10` works: 1 way.
- `"100"`: the last `0` cannot be alone and `00` is not valid: 0 ways.
- `"06"`: `0` alone invalid, `06` invalid (leading zero): 0 ways.

The two validity checks above handle all of these without special cases.

## Step 3: O(1) space

`dp[i]` depends only on `dp[i-1]` and `dp[i-2]`: two variables, as in Climbing Stairs.

## Step 4: The code

<!-- CODE:START -->

Full source: [`decode_ways.dart`](decode_ways.dart) (run it with `dart run`).

```dart
// Decode Ways: letters A-Z are encoded as 1-26. Count the ways to decode a digit string.
// dp[i] = ways to decode the first i digits = (last digit alone, if not '0') dp[i-1]
//       + (last two digits together, if 10..26) dp[i-2]. O(n) time, O(1) space.

int numDecodings(String s) {
  var twoBack = 1, oneBack = s.isEmpty || s[0] == '0' ? 0 : 1; // dp[0] = 1 (empty), dp[1]
  for (var i = 2; i <= s.length; i++) {
    var here = 0;
    if (s[i - 1] != '0') here += oneBack; // single digit 1..9
    final two = int.parse(s.substring(i - 2, i));
    if (two >= 10 && two <= 26) here += twoBack; // two digits 10..26 (no leading zero)
    twoBack = oneBack;
    oneBack = here;
  }
  return s.isEmpty ? 0 : oneBack;
}
```

<!-- CODE:END -->

### Walkthrough

- `oneBack` starts as `dp[1]`: 1 if the first digit is not `0`, else 0.
- `two >= 10` rejects leading zeros like `"06"`.
- An empty string returns 0 here (a convention; LeetCode's strings are non-empty).

## Step 5: Dry run

`"11106"`:

| i | last digit | last two | dp[i] |
|---|---|---|---|
| 0 | | | 1 |
| 1 | 1 | | 1 |
| 2 | 1 | 11 | 1 + 1 = 2 |
| 3 | 1 | 11 | 2 + 1 = 3 |
| 4 | 0 | 10 | 0 + 2 = 2 |
| 5 | 6 | 06 | 2 + 0 = **2** |

## Complexity

- Time: **O(n)**.
- Space: **O(1)**.

## Edge cases

- Leading zero: 0.
- `"27"`: 1 (27 is not a letter).
- Any `"00"` or a `0` after a digit other than 1 or 2 (like `"30"`): 0.

## Common mistakes

- Treating `0` as a valid single digit.
- Accepting two-digit codes like `"06"`.
- Initializing `dp[0] = 0` (then everything is 0).

## Follow-ups you should be ready for

1. **Decode Ways II (LeetCode 639).** `*` can be 1-9: the same DP with case counting, modulo 10^9 + 7.
2. **Return all decodings.** Backtracking; the count can be exponential.
3. **Climbing Stairs with restrictions.** The same "last step was 1 or 2" structure.

## What to remember

Count decodings by the size of the last code (one or two digits). Validity checks on those two cases handle every zero.
