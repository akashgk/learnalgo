# Reverse Bits

**Difficulty:** Easy | **Category:** Bit Manipulation | **Pattern:** Shift out of one number, shift into another | **Source:** LeetCode 190; NeetCode 150, Blind 75

## The problem

Reverse the 32 bits of an unsigned 32-bit integer.

```
00000010100101000001111010011100  (43261596)
00111001011110000010100101000000  (964176192)
```

## Step 1: Bit by bit

Repeat 32 times:

1. take the lowest bit of `n`: `n & 1`;
2. append it to `result` from the right: `result = (result << 1) | bit`;
3. drop it from `n`: `n >>= 1`.

The first bit taken from `n` (its lowest) is shifted left 31 more times, ending as the **highest** bit of the result. That is the reversal.

All 32 iterations are required, even if `n` becomes 0 early: the remaining zeros still need to be shifted in (they push the earlier bits to their high positions).

## Step 2: The code

<!-- CODE:START -->

Full source: [`reverse_bits.dart`](reverse_bits.dart) (run it with `dart run`).

```dart
// Reverse Bits of a 32-bit unsigned integer (given and returned as a non-negative int).
// Shift the lowest bit of n into the result 32 times. O(32) time.

int reverseBits(int n) {
  var result = 0;
  for (var i = 0; i < 32; i++) {
    result = (result << 1) | (n & 1); // append n's lowest bit
    n >>= 1;
  }
  return result;
}
```

<!-- CODE:END -->

### Walkthrough

- Dart's `int` is 64-bit, so `result` never overflows while holding 32 bits; the answer is returned as a non-negative int (LeetCode's "unsigned" output).
- In Java, `int` is signed: use `>>>` for shifting `n` and interpret the result as unsigned.

## Step 3: Dry run (4-bit version for clarity)

Reverse `1011` in 4 bits:

| step | n | bit | result |
|---|---|---|---|
| 1 | 1011 | 1 | 1 |
| 2 | 101 | 1 | 11 |
| 3 | 10 | 0 | 110 |
| 4 | 1 | 1 | 1101 |

`1011` reversed is `1101`.

## Complexity

- Time: **O(32)**.
- Space: **O(1)**.

## Edge cases

- 0 -> 0.
- 1 -> 2^31 (the lowest bit becomes the highest).

## Common mistakes

- Stopping when `n` becomes 0 (the result is then too small).
- Signed shifts in languages with 32-bit signed ints.

## Follow-ups you should be ready for

1. **Called many times.** Precompute reversals of all 256 bytes, then reverse 4 bytes and swap their order: 4 lookups per call.
2. **Divide and conquer masks.** Swap halves, then quarters, and so on: `n = (n >> 16) | (n << 16)`, then swap bytes with masks `0xff00ff00`, and so on. O(log 32) operations.

## What to remember

Take bits from the bottom of `n` and push them into the bottom of `result`; after 32 steps the first bit is on top.
