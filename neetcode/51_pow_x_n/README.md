# Pow(x, n)

**Difficulty:** Medium | **Category:** Math & Geometry | **Pattern:** Exponentiation by squaring | **Source:** LeetCode 50; NeetCode 150

## The problem

Compute `x^n` for a double `x` and a 32-bit integer `n` (possibly negative), without calling a library power function.

```
myPow(2, 10)  -> 1024
myPow(2, -2)  -> 0.25
```

## Step 1: Brute force

Multiply `x` by itself `|n|` times: O(|n|). With `|n|` up to 2^31, that is two billion multiplications: too slow.

## Step 2: Square instead of multiply

`x^10 = (x^5)^2`, and `x^5 = x * (x^2)^2`. Each halving of the exponent costs one squaring (plus one multiplication when the exponent is odd). The exponent reaches 0 after about `log2 |n|` steps.

The iterative form reads the **bits** of `n`:

```
x^13 = x^(8 + 4 + 1) = x^8 * x^4 * x^1         (13 = 1101 in binary)
```

Keep `base = x, x^2, x^4, x^8, ...` by squaring each step, and multiply it into the result when the current bit is 1.

## Step 3: Negative exponents

`x^-n = 1 / x^n`. Compute with `|n|`, then invert.

In languages with 32-bit ints, `-(-2^31)` overflows: `|n|` does not fit. Use a 64-bit variable. In Dart, `int` is 64-bit, so `n.abs()` is safe.

## Step 4: The code

<!-- CODE:START -->

Full source: [`pow_x_n.dart`](pow_x_n.dart) (run it with `dart run`).

```dart
// Pow(x, n): x raised to an integer power n (n may be negative).
// Fast exponentiation (exponentiation by squaring): process n's bits; square the base each step
// and multiply it in when the bit is 1. O(log |n|) multiplications, O(1) space.

double myPow(double x, int n) {
  var e = n.abs(); // Dart ints are 64-bit, so |n| for a 32-bit n never overflows
  var base = x, result = 1.0;
  while (e > 0) {
    if (e & 1 == 1) result *= base; // this bit contributes base^(2^k)
    base *= base;
    e >>= 1;
  }
  return n < 0 ? 1 / result : result;
}
```

<!-- CODE:END -->

### Walkthrough

- `e & 1` tests the lowest bit; `e >>= 1` moves to the next one.
- `base *= base` after each bit: `base` is `x^(2^k)` at step k.
- The inversion happens once at the end.

## Step 5: Dry run

`x = 2`, `n = 10` (binary 1010):

| e (binary) | bit | result | base after squaring |
|---|---|---|---|
| 1010 | 0 | 1 | 4 |
| 101 | 1 | 1 * 4 = 4 | 16 |
| 10 | 0 | 4 | 256 |
| 1 | 1 | 4 * 256 = **1024** | 65536 |

## Complexity

- Time: **O(log |n|)** multiplications.
- Space: **O(1)** (the recursive version uses O(log |n|) stack).

## Edge cases

- `n = 0`: 1 (even for `x = 0`, by convention).
- `x = 1` or `x = -1` with huge `n`.
- `n = -2^31`: handled by 64-bit `abs`.
- `x = 0`, negative `n`: division by zero gives infinity in floating point.

## Common mistakes

- Recursing as `pow(x, n/2) * pow(x, n/2)` (computes the half twice: back to O(n)).
- Negating `n` in a 32-bit int.
- Using integer types for `x`.

## Follow-ups you should be ready for

1. **Modular exponentiation (`x^n mod m`).** Same loop with `% m` after each multiplication; the basis of RSA and many hashing tricks.
2. **Matrix exponentiation.** The same loop with matrices computes the n-th Fibonacci number in O(log n).
3. **Super Pow (LeetCode 372).** Exponent given as a digit array.

## What to remember

Square the base, halve the exponent, and multiply in the base whenever the exponent's current bit is 1: O(log n).
