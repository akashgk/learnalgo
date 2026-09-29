# Product Sum

**Difficulty:** Easy | **Category:** Recursion | **Pattern:** Recursion over a nested structure

## The problem

A "special" array is a non-empty array whose elements are either integers or other special arrays. Its **product sum** is the sum of its elements, where each nested special array contributes its own product sum, and the whole total is multiplied by the array's **depth**. The outermost array has depth 1.

```
[x, y]              ->  1 * (x + y)
[x, [y, z]]         ->  x + 2 * (y + z)
[x, [y, [z]]]       ->  x + 2 * (y + 3 * z)

[5, 2, [7, -1], 3, [6, [-13, 8], 4]]  ->  12
```

Check: `5 + 2 + 2*(7 - 1) + 3 + 2*(6 + 3*(-13 + 8) + 4) = 5 + 2 + 12 + 3 + 2*(6 - 15 + 4) = 22 + 2*(-5) = 12`.

## Step 1: Understand the structure

The input is recursive by definition: an array can contain arrays, which can contain arrays. When the **data** is recursive, the **code** that processes it is almost always recursive too.

Notice the multipliers **compound**. In `[x, [y, [z]]]`, `z` is multiplied by 3 inside its own array, then that result is multiplied by 2 inside the middle array, then by 1 at the top. So `z` is effectively multiplied by 3 * 2 * 1 = 6. Verify this on the example before coding; misreading it is the most common error.

## Step 2: Recursive definition

```
productSum(array, depth):
    sum = 0
    for each element:
        if element is an int: sum += element
        else: sum += productSum(element, depth + 1)
    return sum * depth
```

Base case: an array containing only integers (no further recursion). The recursion ends because every nested array is strictly smaller than the array containing it.

## Step 3: The code

<!-- CODE:START -->

Full source: [`product_sum.dart`](product_sum.dart) (run it with `dart run`).

```dart
// Product Sum
// A "special array" contains ints or nested special arrays. Sum of an array at depth d
// is multiplied by d (outermost depth = 1). O(n) time where n counts all elements, O(d) space.

int productSum(List<Object> array, [int depth = 1]) {
  var sum = 0;
  for (final element in array) {
    sum += switch (element) {
      int n => n,
      List<Object> nested => productSum(nested, depth + 1),
      _ => throw ArgumentError('unexpected element $element'),
    };
  }
  return sum * depth;
}
```

<!-- CODE:END -->

### Walkthrough

- `List<Object> array` accepts a heterogeneous list (ints and lists). Dart's type system needs `Object` here.
- `[int depth = 1]` is an optional positional parameter, so callers just write `productSum(list)`.
- The `switch` expression uses **type patterns**:
  - `int n => n` for a number;
  - `List<Object> nested => productSum(nested, depth + 1)` for a nested special array;
  - `_ => throw ...` rejects anything else.
- `return sum * depth;` applies this level's multiplier **after** summing, which is exactly what makes the multipliers compound.

## Step 4: Dry run

`[5, 2, [7, -1], 3, [6, [-13, 8], 4]]`:

| call | depth | elements summed | sum | returns |
|---|---|---|---|---|
| `[-13, 8]` | 3 | -13 + 8 | -5 | -15 |
| `[6, [-13, 8], 4]` | 2 | 6 + (-15) + 4 | -5 | -10 |
| `[7, -1]` | 2 | 7 - 1 | 6 | 12 |
| outer | 1 | 5 + 2 + 12 + 3 + (-10) | 12 | **12** |

## Complexity

- **Time: O(n)** where n counts every element, including the nested arrays themselves. Each is visited once.
- **Space: O(d)** where d is the maximum nesting depth (one stack frame per level).

## Common mistakes

- Multiplying each integer by its own depth only (no compounding). That is a different problem (LeetCode #339). Check with `[[[5]]]`: compounding gives 5 * 3 * 2 * 1 = 30 (the test uses `[[[[5]]]]` = 5 * 4 * 3 * 2 * 1 = 120).
- Starting the depth at 0, which makes everything 0.

## Follow-ups

1. **Nested List Weight Sum (LeetCode #339):** each integer times its own depth. Pass depth down and multiply at the leaves instead of at the end.
2. **Inverse depth weights (LeetCode #364):** deepest level has weight 1. Either compute the max depth first, or use the trick "accumulate a running unweighted sum level by level and add it at each level".
3. **Iterative version:** a stack of `(iterator, depth)` frames. Useful if nesting can be very deep.

## What to remember

Recursive data -> recursive function. Decide what each call returns (here, its own product sum) and let the parent combine the results.
