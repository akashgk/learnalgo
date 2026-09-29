# Permutation Sequence

**Difficulty:** Hard | **Category:** Recursion / Math | **Pattern:** Factorial number system | **Source:** LeetCode 60; Striver A2Z

## The problem

The permutations of `[1, 2, ..., n]` listed in lexicographic order are numbered from 1. Return the `k`-th one as a string.

```
n = 3: 123, 132, 213, 231, 312, 321
n = 3, k = 3  ->  "213"
n = 4, k = 9  ->  "2314"
```

## Step 1: Brute force

Generate permutations in order (or call Next Permutation, more_problems 02, `k - 1` times). O(k * n), and k can be as large as n!. For n = 9, 9! = 362880 is still feasible, but the point of the problem is to jump straight to the answer.

## Step 2: Count blocks

Look at n = 4. The 24 permutations split into **4 blocks of 3! = 6** by their first digit:

```
k  1-6   start with 1
k  7-12  start with 2
k 13-18  start with 3
k 19-24  start with 4
```

So the first digit is determined by **which block k falls in**. Using a 0-indexed rank `r = k - 1` makes the arithmetic clean: the block index is `r ~/ 3!`. For k = 9, r = 8, 8 ~/ 6 = 1: the second smallest available digit, which is 2.

Within that block, the remaining position is `r % 3! = 2`, and the same reasoning repeats with the remaining digits `[1, 3, 4]` and blocks of 2! = 2.

This is writing `r` in the **factorial number system**: `r = d1 * (n-1)! + d2 * (n-2)! + ... + d_n * 0!`, where each digit `d_i` picks the index among the remaining digits.

## Step 3: The code

<!-- CODE:START -->

Full source: [`permutation_sequence.dart`](permutation_sequence.dart) (run it with `dart run`).

```dart
// Permutation Sequence: the k-th (1-indexed) permutation of [1..n] in lexicographic order.
// Factorial number system: each block of (n-1)! permutations shares its first digit.
// O(n^2) time (list removals), O(n) space.

String getPermutation(int n, int k) {
  final digits = [for (var i = 1; i <= n; i++) i];
  final fact = List<int>.filled(n + 1, 1);
  for (var i = 1; i <= n; i++) {
    fact[i] = fact[i - 1] * i;
  }
  var rank = k - 1; // 0-indexed rank is easier to divide
  final out = StringBuffer();
  for (var remaining = n; remaining >= 1; remaining--) {
    final block = fact[remaining - 1]; // permutations per choice of the next digit
    final index = rank ~/ block;
    out.write(digits.removeAt(index));
    rank %= block;
  }
  return out.toString();
}
```

<!-- CODE:END -->

### Walkthrough

- `fact[i]` holds `i!`.
- `rank = k - 1` switches to 0-indexed.
- For each position: `index = rank ~/ block` chooses among the remaining digits, `digits.removeAt(index)` takes it out, `rank %= block` is the position inside the chosen block.

## Step 4: Dry run

n = 4, k = 9, rank = 8:

| remaining digits | block = (remaining - 1)! | index = rank ~/ block | chosen | rank after |
|---|---|---|---|---|
| 1 2 3 4 | 6 | 1 | 2 | 8 % 6 = 2 |
| 1 3 4 | 2 | 1 | 3 | 2 % 2 = 0 |
| 1 4 | 1 | 0 | 1 | 0 |
| 4 | 1 | 0 | 4 | 0 |

Result `"2314"`.

## Complexity

- Time: **O(n^2)** because `removeAt` on a list is O(n). With a Fenwick tree or order-statistics tree, O(n log n); for n <= 9 it does not matter.
- Space: **O(n)**.

## Edge cases

- k = 1: the sorted order.
- k = n!: the reversed order.
- n = 1: "1".

## Common mistakes

- Using `k` instead of `k - 1` (off by one on every block boundary; for k = 6 and n = 3, `6 ~/ 2 = 3` is out of range).
- Dividing by `n!` instead of `(n - 1)!` for the first digit.
- Forgetting to remove the chosen digit.

## Follow-ups you should be ready for

1. **The inverse: given a permutation, find its rank.** For each position, count the smaller unused digits and multiply by the factorial of the remaining length.
2. **With duplicate digits.** Blocks have multinomial sizes: `(remaining)! / (product of count!)`.
3. **Next permutation.** more_problems 02, when you need neighbors instead of random access.

## What to remember

Lexicographic permutations come in blocks of `(n - 1)!` per first digit. Divide the 0-indexed rank by the block size to choose each digit; the remainder is the rank inside the block.
