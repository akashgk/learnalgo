# Product Sum

**Difficulty:** Easy | **Category:** Recursion | **Pattern:** Recursion over nested structure

## Problem
A "special" array is a non-empty array containing integers or other special arrays. Its product sum is the sum of its elements, where nested special arrays contribute their own product sum, all multiplied by the array's depth. The outermost array has depth 1.

```
[x, [y, z]]  ->  x + 2 * (y + z)
[x, [y, [z]]] -> x + 2 * (y + 3 * z)
[5, 2, [7, -1], 3, [6, [-13, 8], 4]]  ->  12
```

## Building up the logic
1. The structure is recursive (arrays inside arrays), so the solution is recursive.
2. Define `productSum(array, depth)`: sum the elements, recursing into nested arrays with `depth + 1`, then multiply the total by `depth`.
3. Note the multiplication compounds: a value at depth 3 is multiplied by 3 and then by 2 and then by 1 as the results bubble up. Check this against the example before coding.

## Complexity
- Time: O(n), where n is the total number of elements including nested arrays.
- Space: O(d), where d is the maximum nesting depth (recursion stack).

## Interview notes
- Dart 3 type patterns in a `switch` expression (`int n => ...`, `List<Object> nested => ...`) express "is it a number or a list" cleanly and safely.
- Similar: LeetCode #339 / #364 (Nested List Weight Sum). Note #339 does **not** compound; it multiplies each integer by its own depth. Read carefully which one you are asked.
