# Container With Most Water

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Two pointers (discard the provably useless end) | **Source:** LeetCode 11; NeetCode 150, Blind 75

## The problem

`height[i]` is a vertical line at position `i`. Choose two lines that, together with the x-axis, form a container holding the most water. The water level is limited by the **shorter** line: area = `min(height[i], height[j]) * (j - i)`.

```
[1, 8, 6, 2, 5, 4, 8, 3, 7]  ->  49    (lines at 1 and 8: min(8, 7) * 7)
[1, 1]                       ->  1
```

Do not confuse with Trapping Rain Water (AlgoExpert hard 18 Water Area), where all bars hold water together.

## Step 1: Brute force

Every pair: O(n^2) time, O(1) space.

## Step 2: Find what to throw away

Start with the widest container: `lo = 0`, `hi = n - 1`. Suppose `height[lo] < height[hi]`. Consider **any other container that uses `lo`**: it pairs `lo` with some `j < hi`. Its width `j - lo` is smaller, and its water level is at most `height[lo]` (the level never rises above either line, and `lo` is one of them). So its area is at most `height[lo] * (j - lo)`, which cannot exceed the current area, exactly `height[lo] * (hi - lo)`. (Lines beyond `hi` were already discarded by earlier steps.)

So the current container is the **best container that uses `lo`**. We have already recorded it; `lo` can be discarded forever. Move `lo` right.

Symmetric argument when `height[hi]` is shorter. When they are equal, discarding either one is safe (the same argument works for both).

Each step discards one line with a proof that it cannot be part of a better answer. After n - 1 steps, every line has been either discarded or checked in its best pairing.

**Why moving the taller line is useless:** width shrinks by one, and the height is still capped by the same shorter line. The area can only go down.

## Step 3: The code

<!-- CODE:START -->

Full source: [`container_with_most_water.dart`](container_with_most_water.dart) (run it with `dart run`).

```dart
// Container With Most Water: pick two lines that, with the x-axis, hold the most water.
// Two pointers from both ends; always move the shorter line inward. O(n) time, O(1) space.

int maxArea(List<int> height) {
  var lo = 0, hi = height.length - 1, best = 0;
  while (lo < hi) {
    final h = height[lo] < height[hi] ? height[lo] : height[hi];
    final area = h * (hi - lo);
    if (area > best) best = area;
    // The shorter line cannot do better with any closer partner, so discard it.
    if (height[lo] < height[hi]) {
      lo++;
    } else {
      hi--;
    }
  }
  return best;
}
```

<!-- CODE:END -->

### Walkthrough

- `h` is the shorter line, `area = h * (hi - lo)`.
- The branch moves the shorter side inward. On ties (`else` branch) it moves `hi`; either is correct.

## Step 4: Dry run

`[1, 8, 6, 2, 5, 4, 8, 3, 7]`:

| lo | hi | heights | area | best | move |
|---|---|---|---|---|---|
| 0 | 8 | 1, 7 | 8 | 8 | lo (1 is shorter) |
| 1 | 8 | 8, 7 | 49 | **49** | hi |
| 1 | 7 | 8, 3 | 18 | 49 | hi |
| 1 | 6 | 8, 8 | 40 | 49 | hi (tie) |
| 1 | 5 | 8, 4 | 16 | 49 | hi |
| 1 | 4 | 8, 5 | 15 | 49 | hi |
| 1 | 3 | 8, 2 | 4 | 49 | hi |
| 1 | 2 | 8, 6 | 6 | 49 | hi |

## Complexity

- Time: **O(n)**. Each step moves one pointer inward.
- Space: **O(1)**.

## Edge cases

- Fewer than two lines: the loop never runs, area 0.
- All equal heights: the widest pair wins, found on the first step.

## Common mistakes

- Moving the **taller** pointer.
- Computing `max(height[lo], height[hi])` as the water height.
- Mixing this problem up with Trapping Rain Water.

## Follow-ups you should be ready for

1. **Prove correctness.** The "discard the shorter end" argument above is what interviewers want. Practice saying it in two sentences.
2. **Trapping Rain Water.** Also two pointers, but each position's water depends on the max to its left and right.
3. **Return the indices.** Record `lo, hi` when `best` improves.

## What to remember

Two pointers are justified by proving that one end cannot be part of any better answer. Here, the shorter line has already achieved its best possible container.
