# Add Binary

**Difficulty:** Easy | **Category:** Math / Strings | **Pattern:** Digit-by-digit addition with carry | **Source:** LeetCode 67; Grind 75

## The problem

Given two binary strings, return their sum as a binary string.

```
"11" + "1"       ->  "100"
"1010" + "1011"  ->  "10101"
```

## Step 1: Why not parse them?

The strings can be up to 10^4 bits long: no built-in integer holds that. (Dart's `BigInt` would, and is fine for a quick answer, but the interview wants the algorithm.)

## Step 2: Column addition in base 2

Exactly like decimal addition on paper, from the rightmost column:

```
sum = bit of a + bit of b + carry      (0, 1, 2 or 3)
digit = sum % 2      (sum & 1)
carry = sum / 2      (sum >> 1)
```

Keep going while either string has bits left **or** the carry is 1 (a final carry adds a new leading 1, as in `1 + 1 = 10`).

## Step 3: The code

<!-- CODE:START -->

Full source: [`add_binary.dart`](add_binary.dart) (run it with `dart run`).

```dart
// Add Binary: add two binary strings. Grade-school addition from the right with a carry.
// O(max(m, n)) time, O(max(m, n)) space for the result.

String addBinary(String a, String b) {
  final out = <int>[]; // result bits, least significant first
  var i = a.length - 1, j = b.length - 1, carry = 0;
  while (i >= 0 || j >= 0 || carry > 0) {
    var sum = carry;
    if (i >= 0) sum += a.codeUnitAt(i--) - 48;
    if (j >= 0) sum += b.codeUnitAt(j--) - 48;
    out.add(sum & 1); // sum is 0..3: low bit is the digit
    carry = sum >> 1; // high bit is the carry
  }
  return out.reversed.join();
}
```

<!-- CODE:END -->

### Walkthrough

- `i` and `j` walk the strings from the right; a finished string contributes 0.
- The loop condition includes `carry > 0` so a final carry is written.
- Bits are collected least significant first and reversed at the end (inserting at the front of a string each time would be O(n^2)).

## Step 4: Dry run

`"1010" + "1011"`:

| column | a bit | b bit | carry in | sum | digit | carry out |
|---|---|---|---|---|---|---|
| 0 | 0 | 1 | 0 | 1 | 1 | 0 |
| 1 | 1 | 1 | 0 | 2 | 0 | 1 |
| 2 | 0 | 0 | 1 | 1 | 1 | 0 |
| 3 | 1 | 1 | 0 | 2 | 0 | 1 |
| 4 | | | 1 | 1 | 1 | 0 |

Digits from column 4 down: **10101**.

## Complexity

- Time: **O(max(m, n))**.
- Space: **O(max(m, n))** for the result.

## Edge cases

- `"0" + "0"`: `"0"`.
- Different lengths.
- A carry that ripples out (`"1111" + "1"`).

## Common mistakes

- Forgetting the final carry.
- Building the string by prepending inside the loop (quadratic).
- Parsing into a fixed-width integer (overflows for long inputs).

## Follow-ups you should be ready for

1. **Add Strings (LeetCode 415), Plus One (neetcode 50), Add Two Numbers (AlgoExpert medium 49).** The same carry loop in base 10.
2. **Without `+`.** Bitwise addition with XOR and carry; see neetcode 59 Sum of Two Integers.
3. **Base k.** Replace 2 with k.

## What to remember

Addition in any base: from the right, digit = sum mod base, carry = sum div base, and keep going while there is a carry.
