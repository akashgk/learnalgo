# Missing Numbers

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Math / XOR partitioning

## The problem

You get an unsorted array of **distinct** integers taken from the range `1..n`, where `n = array.length + 2`. Exactly two numbers from the range are missing. Return them in ascending order.

```
[1, 4, 3]     ->  [2, 5]     (n = 5)
[]            ->  [1, 2]     (n = 2)
[4, 5, 1, 3]  ->  [2, 6]     (n = 6)
```

## Step 1: Work an example by hand

With `[1, 4, 3]`, `n = 5`, you would check 1, 2, 3, 4, 5 against the list: 2 and 5 are missing. That is a hash set solution: O(n) time, O(n) space. It is correct, and you should say it first.

The interviewer's follow-up is predictable: **"Can you do it in O(1) extra space?"**

## Step 2: Warm-up: only ONE number missing

Two classic O(1)-space tricks:

- **Sum:** expected sum of `1..n` is `n(n+1)/2`. Subtract the actual sum: the difference is the missing number.
- **XOR:** XOR all numbers `1..n` and all numbers in the array. Every present number appears twice and cancels (`x ^ x = 0`), leaving the missing one.

## Step 3: Two missing numbers

Call them `a` and `b`. If you XOR everything (range and array), you get `a ^ b`: the two cannot be separated directly. The trick is to **split the numbers into two groups so that `a` and `b` land in different groups**.

1. `a != b`, so `a ^ b` has at least one bit set to 1. At that bit position, `a` and `b` **differ**: one has a 1, the other a 0.
2. Pick such a bit. The lowest set bit is easy: `x & -x` (a two's complement trick worth memorizing: for `x = 0b0110` it gives `0b0010`).
3. Split **all** numbers (the full range 1..n and the array) into two groups by that bit.
4. XOR each group separately. In each group, every present number still appears twice (once from the range, once from the array) and cancels. What remains in one group is `a`, in the other `b`.

### Alternative: the sum split

Missing sum `S = a + b` is easy to compute. Since `a != b`, one is below `S / 2` and the other above. Sum only the numbers `<= S ~/ 2` in both the range and the array; the difference is the smaller missing number, and the other is `S - smaller`. Also O(n) time, O(1) space, but sums can overflow in fixed-width languages; XOR cannot.

## Step 4: The code

<!-- CODE:START -->

Full source: [`missing_numbers.dart`](missing_numbers.dart) (run it with `dart run`).

```dart
// Missing Numbers: array holds distinct numbers from 1..n+2 with exactly two missing.
// XOR approach: xor of all = a ^ b; split by a set bit. O(n) time, O(1) space.

List<int> missingNumbers(List<int> nums) {
  final n = nums.length + 2;
  var xorAll = 0;
  for (var v = 1; v <= n; v++) {
    xorAll ^= v;
  }
  for (final x in nums) {
    xorAll ^= x;
  }
  // xorAll == a ^ b, and a != b so some bit differs. Take the lowest set bit.
  final bit = xorAll & -xorAll;
  var a = 0, b = 0;
  for (var v = 1; v <= n; v++) {
    if (v & bit != 0) {
      a ^= v;
    } else {
      b ^= v;
    }
  }
  for (final x in nums) {
    if (x & bit != 0) {
      a ^= x;
    } else {
      b ^= x;
    }
  }
  return a < b ? [a, b] : [b, a];
}
```

<!-- CODE:END -->

### Walkthrough

- `final n = nums.length + 2;` is the top of the range.
- The first two loops compute `xorAll = a ^ b`.
- `final bit = xorAll & -xorAll;` isolates the lowest set bit.
- The next two loops XOR each number into group `a` (bit set) or group `b` (bit clear). Paired numbers cancel within each group.
- `return a < b ? [a, b] : [b, a];` sorts the two results.

## Step 5: Dry run

`[1, 4, 3]`, n = 5:

- XOR of 1..5: `1 ^ 2 ^ 3 ^ 4 ^ 5 = 1`. XOR with the array `1 ^ 4 ^ 3`: `1 ^ 1 ^ 4 ^ 3 = 7`. So `a ^ b = 7` (binary 111). Check: `2 ^ 5 = 010 ^ 101 = 111`. Correct.
- Lowest set bit of 7 is 1 (binary 001): split by odd/even.

| group | range numbers | array numbers | XOR of all |
|---|---|---|---|
| bit set (odd) | 1, 3, 5 | 1, 3 | 1^3^5^1^3 = **5** |
| bit clear (even) | 2, 4 | 4 | 2^4^4 = **2** |

Result: `[2, 5]`.

## Complexity

| Approach | Time | Space |
|---|---|---|
| Hash set | O(n) | O(n) |
| Sort then scan | O(n log n) | O(1) |
| XOR partition / sum split | O(n) | O(1) |

## Common mistakes

- Using `n = array.length` instead of `array.length + 2`.
- Forgetting to XOR the full range into the groups (only XORing the array).
- In languages where `&` binds more loosely than `!=` (C, Java), `v & bit != 0` must be written `(v & bit) != 0`. Dart's precedence makes the parentheses optional, but adding them never hurts.

## Follow-ups

1. **Single Number III (LeetCode #260):** every number appears twice except two. Identical XOR-partition trick.
2. **Missing Number (#268):** one missing number, range 0..n.
3. **One number missing and one duplicated (#645):** the XOR of range and array again gives `missing ^ duplicate`; same split.

## What to remember

XOR cancels pairs. To separate two unknowns, split by a bit where they differ (`x & -x` finds one).
