# Radix Sort

**Difficulty:** Hard | **Category:** Sorting | **Pattern:** Non-comparison sort: digit by digit with a stable counting sort

## The problem

Sort an array of **non-negative** integers using Radix Sort.

```
[8762, 654, 3008, 345, 87, 65, 234, 12, 2]  ->  [2, 12, 65, 87, 234, 345, 654, 3008, 8762]
```

## Step 1: Beating the comparison lower bound

Any sort that only **compares** elements needs Omega(n log n) comparisons in the worst case (a decision tree with n! leaves has height at least log2(n!)). Radix sort does not compare elements with each other; it looks at their **digits**, so the bound does not apply.

## Step 2: LSD radix sort

Sort by the **ones** digit, then by the **tens** digit, then the hundreds, and so on, up to the most significant digit of the largest number.

The crucial requirement: each per-digit pass must be **stable**. Numbers with the same current digit must keep the order produced by the previous passes (which sorted them by all less significant digits). After the last pass, numbers are ordered by their most significant digit, and ties are ordered by the rest: fully sorted.

## Step 3: Counting sort for one digit

For the digit at `place` (1, 10, 100, ...):

1. **Count** how many numbers have each digit 0..9.
2. **Prefix-sum** the counts: `counts[d]` becomes the end position (exclusive) of digit `d`'s block in the output.
3. **Place** numbers into the output, iterating **backward** through the input and decrementing `counts[d]`. Iterating backward is what makes it stable: the last number with a given digit goes to the last slot of that digit's block.
4. Copy the output back.

## Step 4: The code

<!-- CODE:START -->

Full source: [`radix_sort.dart`](radix_sort.dart) (run it with `dart run`).

```dart
// Radix Sort (LSD, base 10) for non-negative integers, using a stable counting sort per digit.
// O(d * (n + b)) time, O(n + b) space; d = digits of the max value, b = 10.

List<int> radixSort(List<int> array) {
  if (array.isEmpty) return array;
  final maxValue = array.reduce((a, b) => a > b ? a : b);
  for (var place = 1; maxValue ~/ place > 0; place *= 10) {
    _countingSortByDigit(array, place);
  }
  return array;
}

void _countingSortByDigit(List<int> a, int place) {
  final counts = List<int>.filled(10, 0);
  for (final x in a) {
    counts[(x ~/ place) % 10]++;
  }
  for (var d = 1; d < 10; d++) {
    counts[d] += counts[d - 1]; // prefix sums: end position of each digit bucket
  }
  final out = List<int>.filled(a.length, 0);
  for (var i = a.length - 1; i >= 0; i--) {
    // iterate backwards to keep the sort stable
    final d = (a[i] ~/ place) % 10;
    out[--counts[d]] = a[i];
  }
  a.setAll(0, out);
}
```

<!-- CODE:END -->

### Walkthrough

- `maxValue` determines how many digit passes are needed.
- `for (var place = 1; maxValue ~/ place > 0; place *= 10)` runs one pass per digit.
- `(x ~/ place) % 10` extracts the digit at `place`.
- `out[--counts[d]] = a[i];` places each number at the end of its digit block and moves the block's end left.
- `a.setAll(0, out)` copies the pass result back.

## Step 5: Dry run (first pass, ones digit)

| number | ones digit |
|---|---|
| 8762 | 2 |
| 654 | 4 |
| 3008 | 8 |
| 345 | 5 |
| 87 | 7 |
| 65 | 5 |
| 234 | 4 |
| 12 | 2 |
| 2 | 2 |

After the ones pass (stable within each digit): `[8762, 12, 2, 654, 234, 345, 65, 87, 3008]`. Then the tens pass, the hundreds pass, and the thousands pass produce the sorted array.

## Complexity

- **Time: O(d * (n + b))**, with d = number of digits of the maximum and b = base (10). For fixed-width integers, d is a constant, so this is **O(n)**.
- **Space: O(n + b)** for the output buffer and counts.
- **Stable:** yes.

## Common mistakes

- Iterating forward in the placement step (loses stability, gives wrong results).
- Forgetting the pass count depends on the **maximum**, not on the first element.
- Negative numbers: not handled by this version.

## Extensions

- **Negative numbers:** sort negatives and non-negatives separately (negatives by absolute value, then reversed), or add an offset.
- **Base 256 (bytes):** 32-bit integers need only 4 passes; this is how high-performance integer sorts work.
- **Counting sort alone** is best when the value range is small (see Three Number Sort, medium 58).

## What to remember

Radix sort = stable counting sort per digit, from least to most significant. O(n) for fixed-width keys, and stability is what makes it correct.
