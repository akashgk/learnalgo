# Counting Bits

**Difficulty:** Easy | **Category:** Bit Manipulation | **Pattern:** DP on the binary representation | **Source:** LeetCode 338; NeetCode 150, Blind 75

## The problem

For every `i` from 0 to `n`, return the number of 1 bits in `i`. Aim for O(n) (not O(n log n)).

```
n = 5  ->  [0, 1, 1, 2, 1, 2]
            0  1 10 11 100 101
```

## Step 1: Straightforward

Run Number of 1 Bits (neetcode 55) on each `i`: O(n log n) (up to about log n bits each).

## Step 2: Reuse smaller answers

Shifting `i` right by one drops its lowest bit; the remaining bits are exactly those of `i >> 1`, a **smaller** number whose answer is already known. So:

```
bits[i] = bits[i >> 1] + (i & 1)
```

`i & 1` adds back the dropped bit. Each entry is O(1): O(n) total.

Another valid recurrence: `bits[i] = bits[i & (i - 1)] + 1` (remove the lowest set bit, then add it back).

## Step 3: The code

<!-- CODE:START -->

Full source: [`counting_bits.dart`](counting_bits.dart) (run it with `dart run`).

```dart
// Counting Bits: for every i in 0..n, the number of 1 bits in i.
// DP on the binary representation: i has the same bits as i >> 1, plus its lowest bit.
// bits[i] = bits[i >> 1] + (i & 1). O(n) time.

List<int> countBits(int n) {
  final bits = List<int>.filled(n + 1, 0);
  for (var i = 1; i <= n; i++) {
    bits[i] = bits[i >> 1] + (i & 1);
  }
  return bits;
}
```

<!-- CODE:END -->

### Walkthrough

- `bits[0] = 0` from `List.filled`.
- The loop reads `bits[i >> 1]`, which is always already filled because `i >> 1 < i` for `i >= 1`.

## Step 4: Dry run

| i | binary | i >> 1 | bits[i >> 1] | i & 1 | bits[i] |
|---|---|---|---|---|---|
| 1 | 1 | 0 | 0 | 1 | 1 |
| 2 | 10 | 1 | 1 | 0 | 1 |
| 3 | 11 | 1 | 1 | 1 | 2 |
| 4 | 100 | 2 | 1 | 0 | 1 |
| 5 | 101 | 2 | 1 | 1 | 2 |

## Complexity

- Time: **O(n)**.
- Space: **O(n)** for the output.

## Edge cases

- `n = 0`: `[0]`.

## Common mistakes

- Using `i ~/ 2` and `i % 2` is equally correct; mixing up the order of reading and writing is the only real risk (read smaller indices only).

## Follow-ups you should be ready for

1. **Recurrence by the highest power of two:** `bits[i] = 1 + bits[i - highestPowerOfTwo(i)]`.
2. **Sum of all bits up to n in O(log n).** Count, for each bit position, how many numbers in `0..n` have it set.

## What to remember

A number's bits are its right shift's bits plus its lowest bit. Build the table from small to large.
