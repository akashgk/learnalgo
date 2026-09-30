# Sum of Two Integers

**Difficulty:** Medium | **Category:** Bit Manipulation | **Pattern:** XOR is addition without carry; AND-shift is the carry | **Source:** LeetCode 371; NeetCode 150, Blind 75

## The problem

Return `a + b` for 32-bit signed integers without using `+` or `-`.

```
1 + 2  ->  3
-1 + 1 ->  0
```

## Step 1: How binary addition works

Add one bit column at a time:

| a bit | b bit | sum bit | carry out |
|---|---|---|---|
| 0 | 0 | 0 | 0 |
| 0 | 1 | 1 | 0 |
| 1 | 0 | 1 | 0 |
| 1 | 1 | 0 | 1 |

The sum bit is `a ^ b`; the carry is `a & b`, moving one column left. For whole numbers at once:

```
partial = a ^ b          // add every column, ignoring carries
carry   = (a & b) << 1   // carries, moved to the column they affect
```

`a + b == partial + carry`, a new addition problem. Repeat until the carry is 0. Each round pushes carries at least one column further left, so at most 32 rounds for 32-bit numbers.

## Step 2: Negative numbers in Dart

In two's complement, negative numbers work with the same bit rules, as long as everything is **truncated to 32 bits** (a carry out of bit 31 is discarded). Java and C++ ints do that automatically. Dart ints are 64-bit, so:

- mask every intermediate value with `0xFFFFFFFF` (keep 32 bits);
- at the end, if bit 31 is set, the 32-bit value is negative: subtract `2^32` to convert it to a negative Dart int.

(Python has the same issue with arbitrary-size ints and uses the same mask trick.)

## Step 3: The code

<!-- CODE:START -->

Full source: [`sum_of_two_integers.dart`](sum_of_two_integers.dart) (run it with `dart run`).

```dart
// Sum of Two Integers without + or -: 32-bit two's complement addition from bit operations.
// a ^ b adds without carries; (a & b) << 1 is the carry. Repeat until there is no carry.
// Dart ints are 64-bit, so every step is masked to 32 bits and the result is sign-extended.
// At most 32 iterations.

int getSum(int a, int b) {
  const mask = 0xFFFFFFFF;
  a &= mask;
  b &= mask;
  while (b != 0) {
    final carry = ((a & b) << 1) & mask;
    a = (a ^ b) & mask;
    b = carry;
  }
  // Bit 31 set means a negative 32-bit number: convert back to a negative Dart int.
  return a > 0x7FFFFFFF ? a - 0x100000000 : a;
}
```

<!-- CODE:END -->

### Walkthrough

- Both inputs are masked first, so negatives become their 32-bit two's complement patterns.
- The loop is the partial-sum / carry iteration, with masking.
- The final line sign-extends from 32 bits.

## Step 4: Dry run

`2 + 3` (`010 + 011`):

| round | a | b (carry) |
|---|---|---|
| start | 010 | 011 |
| 1 | 010 ^ 011 = 001 | (010 & 011) << 1 = 100 |
| 2 | 001 ^ 100 = 101 | (001 & 100) << 1 = 000 |

Result `101 = 5`.

## Complexity

- Time: **O(32)** iterations at most.
- Space: **O(1)**.

## Edge cases

- `-1 + 1`: the carry ripples through all 32 bits and falls off the end; the masked result is 0.
- Two negatives.

## Common mistakes

- Infinite loop with negatives in languages with unbounded ints (the carry keeps moving left forever without a mask).
- Forgetting the final sign conversion (returning 4294967295 instead of -1).

## Follow-ups you should be ready for

1. **Subtraction.** `a - b = a + (~b + 1)`, the two's complement negation.
2. **Multiplication with shifts and adds.** Shift-and-add over the bits of one operand.
3. **Why hardware adders use carry lookahead.** Rippling carries is O(bits); lookahead computes carries in O(log bits) depth.

## What to remember

`a ^ b` adds without carries, `(a & b) << 1` is the carries. Repeat until no carry. Mask to 32 bits in languages with wide integers.
