# Reverse Integer

**Difficulty:** Medium | **Category:** Math / Bit Manipulation | **Pattern:** Digit popping with overflow checks before each step | **Source:** LeetCode 7; NeetCode 150

## The problem

Reverse the digits of a signed 32-bit integer. If the reversed value is outside `[-2^31, 2^31 - 1]`, return 0. Assume the environment cannot store 64-bit integers (so you cannot compute the result in a bigger type and check afterwards).

```
123         ->  321
-123        ->  -321
120         ->  21
1534236469  ->  0       (9646324351 does not fit)
```

## Step 1: Popping and pushing digits

```
digit = x % 10;   x = x / 10;        // pop the last digit
result = result * 10 + digit;        // push it onto the result
```

For negative `x`, use a remainder that keeps the sign (`-123 -> -3`) and division that truncates toward zero (`-123 / 10 = -12`). Then the same loop handles negatives. In Dart, `remainder` keeps the sign (Dart's `%` would give `7` for `-123 % 10`), and `~/` truncates toward zero.

## Step 2: Check before overflowing

The only step that can overflow is `result * 10 + digit`. Check it **before** doing it:

- positive side: overflow if `result > MAX / 10`, or `result == MAX / 10` and `digit > 7` (MAX = 2147483647 ends in 7);
- negative side: overflow if `result < MIN / 10`, or `result == MIN / 10` and `digit < -8` (MIN = -2147483648 ends in 8).

These are the standard "does `r * 10 + d` fit?" checks, and they use only values that fit in 32 bits.

(Dart ints are 64-bit, so the code could just check the result afterwards. It deliberately follows the 32-bit rules because that is what the interview asks for.)

## Step 3: The code

<!-- CODE:START -->

Full source: [`reverse_integer.dart`](reverse_integer.dart) (run it with `dart run`).

```dart
// Reverse Integer: reverse the digits of a signed 32-bit integer; return 0 if the result leaves the
// 32-bit range. Written as if only 32-bit arithmetic were available: check for overflow BEFORE
// multiplying by 10. O(number of digits).

const _max = 2147483647, _min = -2147483648;

int reverse(int x) {
  var result = 0;
  while (x != 0) {
    final digit = x.remainder(10); // keeps the sign of x (Dart's % would not)
    x = x ~/ 10; // truncates toward zero
    // result * 10 + digit must stay within [_min, _max].
    if (result > _max ~/ 10 || (result == _max ~/ 10 && digit > 7)) return 0;
    if (result < _min ~/ 10 || (result == _min ~/ 10 && digit < -8)) return 0;
    result = result * 10 + digit;
  }
  return result;
}
```

<!-- CODE:END -->

### Walkthrough

- `x.remainder(10)` and `x ~/ 10` both follow the sign of `x`.
- The two `if` lines are the positive and negative overflow checks.
- `_max ~/ 10 = 214748364` and `_min ~/ 10 = -214748364`.

## Step 4: Dry run

`-123`:

| x before | digit | x after | result |
|---|---|---|---|
| -123 | -3 | -12 | -3 |
| -12 | -2 | -1 | -32 |
| -1 | -1 | 0 | **-321** |

`1534236469`: after 9 digits, `result = 964632435 > 214748364`, so the next push would overflow: **0**.

## Complexity

- Time: **O(number of digits)**, at most 10.
- Space: **O(1)**.

## Edge cases

- Trailing zeros: `120 -> 21` (leading zeros vanish naturally).
- `0 -> 0`.
- Values near the limits: `1463847412 -> 2147483641` fits.

## Common mistakes

- Using a floored modulo for negatives (Dart `%`, Python `%`).
- Checking overflow after the multiplication (too late in 32-bit arithmetic).
- Converting to a string and back without a range check.

## Follow-ups you should be ready for

1. **String to Integer (atoi, LeetCode 8).** The same overflow checks while parsing.
2. **Palindrome Number (LeetCode 9).** Reverse only half the digits and compare.
3. **Reverse bits.** neetcode 57.

## What to remember

Pop digits with a sign-preserving remainder, and check `result * 10 + digit` against the limits before computing it.
