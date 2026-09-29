# Largest Rectangle Under Skyline

**Difficulty:** Hard | **Category:** Stacks | **Pattern:** Monotonic stack (previous and next smaller element)

## The problem

Building heights (each of width 1) form a skyline. Return the area of the largest rectangle that fits entirely under the skyline.

```
[1, 3, 3, 2, 4, 1, 5, 3, 2]  ->  9
```

The 9 is the full-width rectangle of height 1. Close competitors: height 2 across indices 1..4 (area 8), height 3 across indices 1..2 (area 6).

## Step 1: Every best rectangle is limited by one bar

Take any optimal rectangle. Its height must equal the height of **some bar** inside it (otherwise you could raise it). So for each bar `i`, consider the widest rectangle of height exactly `height[i]`: extend left and right until you meet a **lower** bar.

```
area(i) = height[i] * (nextSmaller(i) - previousSmaller(i) - 1)
answer  = max over i of area(i)
```

## Step 2: Brute force

For each bar, walk left and right to the first lower bar: **O(n^2)**.

## Step 3: Find all previous/next smaller bars at once

"Nearest smaller element on each side" for every index is the classic **monotonic stack** job (see Next Greater Element, medium 64):

- Keep a stack of indices with **increasing** heights.
- When the new bar `i` is **lower than or equal to** the top, the top's rectangle cannot extend past `i`: `i` is its right limit. Pop it. Its left limit is the new top after popping (the previous smaller bar), or -1 if the stack is empty.
- Width = `i - left - 1`.
- Push `i`.
- At the end, a **sentinel** bar of height 0 flushes everything left on the stack.

## Step 4: The code

<!-- CODE:START -->

Full source: [`largest_rectangle_under_skyline.dart`](largest_rectangle_under_skyline.dart) (run it with `dart run`).

```dart
// Largest Rectangle Under Skyline (histogram). Monotonic increasing stack of indices;
// when a bar is popped, the current index is its right boundary and the new stack top its left.
// O(n) time, O(n) space.

int largestRectangleUnderSkyline(List<int> buildings) {
  final stack = <int>[];
  var best = 0;
  for (var i = 0; i <= buildings.length; i++) {
    final height = i == buildings.length ? 0 : buildings[i]; // sentinel flushes the stack
    while (stack.isNotEmpty && buildings[stack.last] >= height) {
      final h = buildings[stack.removeLast()];
      final left = stack.isEmpty ? -1 : stack.last; // first bar lower than h on the left
      final width = i - left - 1;
      if (h * width > best) best = h * width;
    }
    stack.add(i);
  }
  return best;
}
```

<!-- CODE:END -->

### Walkthrough

- The loop runs to `i == buildings.length`, where `height = 0` is the sentinel.
- The `while` pops every bar at least as tall as the current one and computes its rectangle.
- `left` is the index below the popped one in the stack (or -1).

## Step 5: Dry run (every pop, verified by running the algorithm)

| i (right limit) | popped height | left limit | width | area |
|---|---|---|---|---|
| 2 | 3 | 0 | 1 | 3 |
| 3 | 3 | 0 | 2 | 6 |
| 5 | 4 | 3 | 1 | 4 |
| 5 | 2 | 0 | 4 | 8 |
| 5 | 1 | -1 | 5 | 5 |
| 7 | 5 | 5 | 1 | 5 |
| 8 | 3 | 5 | 2 | 6 |
| 9 (sentinel) | 2 | 5 | 3 | 6 |
| 9 (sentinel) | 1 | -1 | 9 | **9** |

Maximum: 9. (Popping on `>=` means equal bars are finalized early with a narrower width, but the last of a run of equal bars still gets the full width, so the maximum is correct.)

## Complexity

- **Time: O(n)**: each index is pushed and popped exactly once.
- **Space: O(n)**.

## Common mistakes

- Using the popped bar's own index as the left limit (the left limit is the element **below** it in the stack).
- Forgetting the sentinel (bars left on the stack are never evaluated).

## Follow-ups

1. **Largest Rectangle in Histogram (LeetCode #84):** identical; a top-tier hard problem at Google and Amazon.
2. **Maximal Rectangle (#85):** a binary matrix. For each row, compute a histogram of consecutive 1s above each cell and run this algorithm per row: O(rows * cols).
3. **Divide and conquer alternative:** the minimum bar splits the range; O(n log n) average.

## What to remember

The best rectangle is limited by its shortest bar. For every bar, the previous and next smaller bars (found with a monotonic stack) give its maximal width.
