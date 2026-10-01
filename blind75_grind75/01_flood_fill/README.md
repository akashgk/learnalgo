# Flood Fill

**Difficulty:** Easy | **Category:** Graphs (grid) | **Pattern:** DFS on a grid, recolor as visited | **Source:** LeetCode 733; Grind 75

## The problem

Given an image (grid of colors), a start pixel `(sr, sc)` and a new `color`, recolor the start pixel and every pixel connected to it **4-directionally** through pixels of the **same original color**. This is the paint-bucket tool.

```
1 1 1        2 2 2
1 1 0   ->   2 2 0      start (1, 1), color 2
1 0 1        2 0 1      (the bottom-right 1 touches the region only diagonally)
```

## Step 1: It is a graph traversal

Pixels are nodes; edges connect 4-adjacent pixels with the original color. The region is the connected component containing the start. DFS or BFS from the start visits exactly that component.

## Step 2: The visited set comes for free

Recoloring a pixel changes it away from the original color, so the "same original color" check already excludes visited pixels. No separate visited grid is needed.

**The one trap:** if the new color **equals** the original color, recoloring changes nothing, so every pixel still looks unvisited and the DFS recurses forever. Return immediately in that case.

## Step 3: The code

<!-- CODE:START -->

Full source: [`flood_fill.dart`](flood_fill.dart) (run it with `dart run`).

```dart
// Flood Fill: starting at (sr, sc), recolor the connected region (4-directional) of cells that share
// the starting cell's color. DFS from the start. O(rows * cols) time, O(rows * cols) worst-case
// recursion depth.

List<List<int>> floodFill(List<List<int>> image, int sr, int sc, int color) {
  final original = image[sr][sc];
  // Already the target color: nothing changes, and recursing would loop forever (no cell looks new).
  if (original == color) return image;
  final rows = image.length, cols = image[0].length;
  void fill(int r, int c) {
    if (r < 0 || c < 0 || r >= rows || c >= cols || image[r][c] != original) return;
    image[r][c] = color; // recoloring doubles as the visited mark
    fill(r + 1, c);
    fill(r - 1, c);
    fill(r, c + 1);
    fill(r, c - 1);
  }

  fill(sr, sc);
  return image;
}
```

<!-- CODE:END -->

### Walkthrough

- `original` is read before anything is modified.
- `fill` stops at the border, or at a pixel of a different color (which includes already-recolored pixels).
- The image is modified in place and returned, as LeetCode expects.

## Step 4: Dry run

Start (1, 1), original 1, color 2. DFS order (down, up, right, left):

| visit | action |
|---|---|
| (1, 1) | recolor, go down to (2, 1): value 0, stop |
| up (0, 1) | recolor; from there: up out of bounds, right (0, 2) recolor, left (0, 0) recolor |
| (0, 0) | recolor; down (1, 0) recolor; from (1, 0): down (2, 0) recolor |
| back at (1, 1): right (1, 2) | 0: stop |

Pixel (2, 2) is never reached: its only 1-valued link to the region would be diagonal.

## Complexity

- Time: **O(rows * cols)** in the worst case (the whole image is one region).
- Space: **O(rows * cols)** recursion depth in the worst case (a snake-shaped region); BFS with a queue has the same bound.

## Edge cases

- New color equals the original: return the image unchanged.
- One pixel.

## Common mistakes

- Missing the same-color early return (infinite recursion).
- Including diagonal neighbors.
- Comparing neighbors with the **new** color instead of the original one.

## Follow-ups you should be ready for

1. **Number of Islands / River Sizes.** Run the same fill from every unvisited land cell; see AlgoExpert medium 38.
2. **Very large images.** Use iterative BFS (or a scanline fill) to avoid stack overflow.
3. **Surrounded Regions.** Fill from the border first; see AlgoExpert medium 40.

## What to remember

Flood fill is DFS on a grid. Recoloring marks visited, which is safe only when the new color differs from the old one.
