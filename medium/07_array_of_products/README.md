# Array Of Products

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Prefix and suffix products

## The problem

Given a non-empty array of integers, return an array of the same length where `output[i]` is the product of every number in the input **except** `input[i]`. You may not use division.

```
[5, 1, 4, 2]  ->  [8, 40, 10, 20]
output[0] = 1 * 4 * 2 = 8
output[1] = 5 * 4 * 2 = 40
output[2] = 5 * 1 * 2 = 10
output[3] = 5 * 1 * 4 = 20
```

## Step 1: Work an example by hand

Write "everything except index 2" for `[5, 1, 4, 2]` as two groups: **left** of index 2 is `5 * 1 = 5`, **right** of it is `2`. The answer is `5 * 2 = 10`.

Every answer is (product of everything to the left) * (product of everything to the right). And those left products are cumulative: left of index 3 is left of index 2 times `array[2]`. So they can all be computed in one pass.

## Step 2: Brute force

For each `i`, multiply all `j != i`. **O(n^2)** time.

## Why not divide?

Compute the total product and divide by each element: O(n). But:

- the problem forbids it (on purpose);
- it breaks with zeros. With exactly one zero, every position except the zero's gets 0, and the zero's position gets the product of the others. With two or more zeros, everything is 0. You would need special cases.

Knowing **why** division fails is a good thing to say.

## Step 3: Optimize with prefix and suffix products

Define `left[i]` = product of `array[0..i-1]` (1 for i = 0), `right[i]` = product of `array[i+1..n-1]` (1 for the last index). Then `output[i] = left[i] * right[i]`.

- Fill `left` in one pass left to right with a running product.
- Fill `right` in one pass right to left.

That is O(n) time with two extra arrays.

### Space optimization

Store `left` directly in the output array. Then sweep right to left with a **single running variable** for the right-side product, multiplying it in. Extra space drops to O(1) (the output array does not count as extra, because it is required).

## Step 4: The code

<!-- CODE:START -->

Full source: [`array_of_products.dart`](array_of_products.dart) (run it with `dart run`).

```dart
// Array Of Products: output[i] = product of all elements except array[i], no division.
// Prefix products left-to-right, then multiply by suffix products right-to-left.
// O(n) time, O(n) output, O(1) extra.

List<int> arrayOfProducts(List<int> array) {
  final products = List<int>.filled(array.length, 1);
  var running = 1;
  for (var i = 0; i < array.length; i++) {
    products[i] = running; // product of everything left of i
    running *= array[i];
  }
  running = 1;
  for (var i = array.length - 1; i >= 0; i--) {
    products[i] *= running; // times product of everything right of i
    running *= array[i];
  }
  return products;
}
```

<!-- CODE:END -->

### Walkthrough

- `List<int>.filled(array.length, 1)` creates the output.
- First loop: before multiplying in `array[i]`, `running` holds the product of everything left of `i`. Store it, then include `array[i]` for the next index.
- `running = 1;` resets for the second pass.
- Second loop (right to left): `running` holds the product of everything right of `i`. Multiply it into the stored left product.

## Step 5: Dry run

`[5, 1, 4, 2]`:

First pass (left products):

| i | products[i] = running | running after (*= array[i]) |
|---|---|---|
| 0 | 1 | 5 |
| 1 | 5 | 5 |
| 2 | 5 | 20 |
| 3 | 20 | 40 |

Second pass (right products):

| i | running (right of i) | products[i] after | running after |
|---|---|---|---|
| 3 | 1 | 20 | 2 |
| 2 | 2 | 10 | 8 |
| 1 | 8 | 40 | 8 |
| 0 | 8 | 8 | 40 |

Result: `[8, 40, 10, 20]`.

## Complexity

| Approach | Time | Extra space |
|---|---|---|
| Brute force | O(n^2) | O(1) |
| Left and right arrays | O(n) | O(n) |
| Output array + one running variable | O(n) | O(1) |

## Edge cases

- Zeros: handled naturally, no special cases (`[0, 0, -2, 4, 5]` gives all zeros).
- Single element: the product of "nothing" is 1, so `[7] -> [1]`.

## Common mistakes

- Multiplying `array[i]` into `running` before storing it (includes the element itself).
- Overflow: products grow very fast. In Java/C++ ask whether values fit in 32/64 bits.

## Follow-ups

1. **LeetCode #238 (Product of Array Except Self):** the same problem; the O(1) extra space version is the expected answer.
2. **Prefix sums** are the additive version of this idea and appear everywhere (Zero Sum Subarray, Longest Subarray With Sum, range sum queries).
3. **Trapping Rain Water (hard 18)** uses prefix maximums and suffix maximums the same way.

## What to remember

"Everything except i" = (everything left of i) combined with (everything right of i). Compute both with running totals in two passes.
