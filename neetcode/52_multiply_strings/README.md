# Multiply Strings

**Difficulty:** Medium | **Category:** Math & Geometry | **Pattern:** Grade-school multiplication with position arithmetic | **Source:** LeetCode 43; NeetCode 150

## The problem

Multiply two non-negative integers given as strings and return the product as a string. You may not convert the inputs to integers directly or use a big-integer library.

```
"2"   * "3"    ->  "6"
"123" * "456"  ->  "56088"
```

## Step 1: How big can the result be?

A number with `m` digits is less than `10^m`, so the product of an `m`-digit and an `n`-digit number is less than `10^(m + n)`: it has **at most m + n digits**. Allocate an array of `m + n` digit slots.

## Step 2: Where does each digit product go?

On paper, the digit at position `i` of `num1` times the digit at position `j` of `num2` contributes to a specific column. Counting positions **from the left** in arrays of length m and n, and in a result array of length m + n:

```
num1[i] * num2[j]  lands in result[i + j + 1], with its carry going to result[i + j]
```

Check with the last digits: `i = m - 1`, `j = n - 1`: position `m + n - 1`, the last slot (the ones column). Correct.

## Step 3: Accumulate with carries as you go

For each pair (right to left in both numbers):

```
sum = num1[i] * num2[j] + result[i + j + 1]
result[i + j + 1] = sum % 10
result[i + j]    += sum ~/ 10
```

`result[i + j]` may temporarily exceed 9; it is normalized later when it is itself the `i + j + 1` slot of a later (more significant) pair, or it ends as the leading digit, which is always below 10 because the product has at most m + n digits.

## Step 4: The code

<!-- CODE:START -->

Full source: [`multiply_strings.dart`](multiply_strings.dart) (run it with `dart run`).

```dart
// Multiply Strings: multiply two non-negative integers given as strings, without converting them
// to big integers. Grade-school multiplication: the product of digits i and j (from the right)
// lands in position i + j of the result. O(m * n) time, O(m + n) space.

String multiply(String num1, String num2) {
  if (num1 == '0' || num2 == '0') return '0';
  final m = num1.length, n = num2.length;
  final result = List<int>.filled(m + n, 0); // a product has at most m + n digits
  for (var i = m - 1; i >= 0; i--) {
    final a = num1.codeUnitAt(i) - 48;
    for (var j = n - 1; j >= 0; j--) {
      final b = num2.codeUnitAt(j) - 48;
      // Positions counted from the left: digits i and j contribute to i + j + 1, carry to i + j.
      final sum = a * b + result[i + j + 1];
      result[i + j + 1] = sum % 10;
      result[i + j] += sum ~/ 10;
    }
  }
  final start = result[0] == 0 ? 1 : 0; // at most one leading zero
  return result.sublist(start).join();
}
```

<!-- CODE:END -->

### Walkthrough

- The early return handles zero (otherwise the result would be all zeros, stripped to empty).
- Digits are read as code units minus 48 (`'0'`).
- Only one leading zero is possible (the product has either m + n or m + n - 1 digits), so `start` is 0 or 1.

## Step 5: Dry run

`"99" * "99"`: result has 4 slots `[0, 0, 0, 0]`.

| i, j | digits | sum | result after |
|---|---|---|---|
| 1, 1 | 9 * 9 | 81 + 0 | [0, 0, 8, 1] |
| 1, 0 | 9 * 9 | 81 + 8 | [0, 8, 9, 1] |
| 0, 1 | 9 * 9 | 81 + 9 | [0, 17, 0, 1] |
| 0, 0 | 9 * 9 | 81 + 17 | [9, 8, 0, 1] |

Result `"9801"`.

## Complexity

- Time: **O(m * n)**.
- Space: **O(m + n)**.

## Edge cases

- Either input `"0"`: `"0"`.
- Single digits.
- Results with a leading zero slot (for example `"2" * "3"` fills only the last slot).

## Common mistakes

- Converting to `int` (overflows past 18 digits).
- Wrong positions (`i + j` vs `i + j + 1`).
- Stripping all leading zeros including the last one (turns `"0"` into `""`).

## Follow-ups you should be ready for

1. **Karatsuba multiplication.** O(n^1.585) by splitting numbers in halves; FFT-based methods reach O(n log n). Worth naming for very large inputs.
2. **Add Strings (LeetCode 415).** The same carry loop for addition.
3. **Plus One.** neetcode 50.

## What to remember

Digit i times digit j lands in slot i + j + 1 (carry into i + j). A product has at most m + n digits.
