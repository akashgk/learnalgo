# Single Number III

**Difficulty:** Medium | **Category:** Bit manipulation | **Pattern:** XOR, then partition by a differing bit | **Source:** LeetCode 260; Striver A2Z

## The problem

Every value appears exactly **twice**, except **two** values that appear once. Find those two. O(n) time, O(1) space.

```
[1, 2, 1, 3, 2, 5]  ->  [3, 5]
```

## Step 1: Recall Single Number I

With only one single value, XOR everything: `x ^ x = 0` and `x ^ 0 = x`, and XOR is commutative and associative, so pairs cancel and the single value remains.

## Step 2: Apply it here

XOR of the whole array gives `a ^ b`, where `a` and `b` are the two singles. That is not `a` and `b` separately, but it tells us **where they differ**: every 1 bit of `a ^ b` is a position where exactly one of `a`, `b` has a 1. Since `a != b`, `a ^ b != 0`, so at least one such bit exists.

## Step 3: Split the array into two groups

Pick any set bit of `a ^ b`, for example the lowest one. Put each number in group 1 if it has that bit, group 2 otherwise.

- `a` and `b` land in **different** groups (they differ at that bit).
- Both copies of any pair land in the **same** group (they are equal).

So each group is a "Single Number I" problem: XOR each group to get `a` and `b`. In practice, XOR only one group to get `a`, then `b = (a ^ b) ^ a`.

**Lowest set bit trick:** `x & -x` isolates the lowest 1 bit of `x` (two's complement: `-x = ~x + 1` flips all bits above the lowest 1 and keeps that bit).

## Step 4: The code

<!-- CODE:START -->

Full source: [`single_number_iii.dart`](single_number_iii.dart) (run it with `dart run`).

```dart
// Single Number III: every value appears exactly twice except two values that appear once.
// Find those two. XOR everything to get a ^ b, split all numbers by one bit where a and b differ,
// and XOR each group. O(n) time, O(1) space.

List<int> singleNumber(List<int> nums) {
  var both = 0;
  for (final x in nums) {
    both ^= x; // pairs cancel: both == a ^ b, and it is non-zero because a != b
  }
  final lowBit = both & -both; // lowest set bit: a and b differ here
  var a = 0;
  for (final x in nums) {
    if (x & lowBit != 0) a ^= x; // this group contains a (or b) plus whole pairs
  }
  final b = both ^ a;
  return a < b ? [a, b] : [b, a];
}
```

<!-- CODE:END -->

### Walkthrough

- `both` is `a ^ b`.
- `lowBit = both & -both` is a power of two marking one differing bit.
- `a` accumulates the XOR of numbers with that bit set; `b` follows from `both`.
- The result is sorted for a deterministic output.

## Step 5: Dry run

`[1, 2, 1, 3, 2, 5]`:

| step | value |
|---|---|
| XOR of all | 1^2^1^3^2^5 = 3^5 = `011 ^ 101` = `110` = 6 |
| lowBit | 6 & -6 = `010` = 2 |
| numbers with bit 2 set | 2, 3, 2 |
| a | 2 ^ 3 ^ 2 = 3 |
| b | 6 ^ 3 = 5 |

Answer `[3, 5]`.

## Complexity

- Time: **O(n)**, two passes.
- Space: **O(1)**.

## Edge cases

- Negative numbers: two's complement bits work the same way (`[-1, 0]` -> `[-1, 0]`).
- One of the singles is 0: fine; 0 goes to the group without the bit.

## Common mistakes

- Trying to recover `a` and `b` from `a ^ b` alone.
- `both & (both - 1)` (that **clears** the lowest bit, the opposite of what is needed).
- In languages with fixed-width ints, `-x` overflows for the minimum value; use `x & (~x + 1)` in unsigned arithmetic or `x & -x` with care. Dart ints are 64-bit, so 32-bit inputs are safe.

## Follow-ups you should be ready for

1. **Single Number II (LeetCode 137): every value three times except one.** Count each bit modulo 3, or use the `ones`/`twos` bitmask state machine.
2. **Missing and repeating number (Striver).** XOR of the array with 1..n gives `missing ^ repeated`; partition by a set bit the same way.
3. **Why not a hash map?** O(n) space. The whole point is O(1).

## What to remember

XOR cancels pairs. With two unknowns, `a ^ b` gives a bit where they differ; partition by that bit so each half has one unknown.
