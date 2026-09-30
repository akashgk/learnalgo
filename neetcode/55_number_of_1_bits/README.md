# Number of 1 Bits

**Difficulty:** Easy | **Category:** Bit Manipulation | **Pattern:** `n & (n - 1)` clears the lowest set bit | **Source:** LeetCode 191; NeetCode 150, Blind 75

## The problem

Return the number of 1 bits in the binary representation of a non-negative integer (its Hamming weight, or popcount).

```
11  (1011)      ->  3
128 (10000000)  ->  1
```

## Step 1: Check every bit

Loop 32 times: add `n & 1`, then shift `n >>= 1`. O(32), fine.

## Step 2: Only visit the 1 bits

Subtracting 1 from `n` flips the **lowest set bit** to 0 and all the zeros below it to 1:

```
n       = 1011000
n - 1   = 1010111
n & n-1 = 1010000      (the lowest 1 is gone, everything else unchanged)
```

So `n &= n - 1` removes exactly one 1 bit. Count how many times until `n` is 0: that is the number of 1 bits. The loop runs once per set bit, not 32 times (Brian Kernighan's trick).

## Step 3: The code

<!-- CODE:START -->

Full source: [`number_of_1_bits.dart`](number_of_1_bits.dart) (run it with `dart run`).

```dart
// Number of 1 Bits (Hamming weight) of a non-negative integer.
// n & (n - 1) clears the lowest set bit, so the loop runs once per 1 bit. O(number of 1 bits).

int hammingWeight(int n) {
  var count = 0;
  while (n != 0) {
    n &= n - 1;
    count++;
  }
  return count;
}
```

<!-- CODE:END -->

### Walkthrough

- The loop condition `n != 0` stops when every 1 bit has been cleared.

## Step 4: Dry run

`11 = 1011`:

| n | n - 1 | n & (n - 1) | count |
|---|---|---|---|
| 1011 | 1010 | 1010 | 1 |
| 1010 | 1001 | 1000 | 2 |
| 1000 | 0111 | 0000 | 3 |

## Complexity

- Time: **O(number of 1 bits)**, at most 32.
- Space: **O(1)**.

## Edge cases

- 0: 0.
- All 31 low bits set: 31.

## Common mistakes

- In Java/C++, using signed right shift on negative inputs loops forever; use unsigned shift (`>>>`) or the `n & (n - 1)` form. Dart's `int` is 64-bit and the input here is non-negative.

## Follow-ups you should be ready for

1. **Counting Bits for every number up to n.** neetcode 56.
2. **Is n a power of two?** `n > 0 && n & (n - 1) == 0`.
3. **Hardware popcount.** Most CPUs have an instruction; languages expose it (`Integer.bitCount` in Java).

## What to remember

`n & (n - 1)` clears the lowest set bit. Counting how often you can do that counts the 1 bits.
