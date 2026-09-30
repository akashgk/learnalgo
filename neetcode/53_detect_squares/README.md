# Detect Squares

**Difficulty:** Medium | **Category:** Math & Geometry | **Pattern:** Enumerate the diagonal corner, look up the other two | **Source:** LeetCode 2013; NeetCode 150

## The problem

Design a structure that stores points (duplicates allowed) and supports:

- `add(point)`
- `count(point)`: the number of ways to choose **three stored points** that form an **axis-aligned square with positive area** together with the query point.

```
add([3, 10]), add([11, 2]), add([3, 2])
count([11, 10]) -> 1
count([14, 8])  -> 0
add([11, 2])                  (a second copy)
count([11, 10]) -> 2          (either copy of [11, 2] can be used)
```

## Step 1: Fix the diagonal

An axis-aligned square is determined by **two opposite corners**. With the query point `(x, y)` as one corner, choose the **diagonally opposite** corner `(px, py)` from the stored points. It must satisfy:

- `|px - x| == |py - y|` (equal side lengths),
- `px != x` (positive area).

Then the other two corners are forced: `(x, py)` and `(px, y)`.

## Step 2: Count with multiplicities

Store a count per distinct point. For each distinct stored point that qualifies as a diagonal:

```
ways += count[(px, py)] * count[(x, py)] * count[(px, y)]
```

Each choice of copies is a different triple, which is why the counts multiply.

## Step 3: Complexity choice

Iterating over all distinct stored points costs O(P) per query. An alternative iterates over the points sharing the query's x-coordinate (to pick the side length), then checks both directions: faster when points are spread out. The version here is simpler and is the common interview answer.

## Step 4: The code

<!-- CODE:START -->

Full source: [`detect_squares.dart`](detect_squares.dart) (run it with `dart run`).

```dart
// Detect Squares: add(point) stores points (duplicates allowed); count(point) returns how many ways
// to choose three stored points forming an axis-aligned square of positive area with the query.
// For each stored point that could be the DIAGONAL opposite corner, the other two corners are
// fixed: multiply their counts. add O(1), count O(number of distinct points).

class DetectSquares {
  final _count = <(int, int), int>{};

  void add(List<int> point) {
    final p = (point[0], point[1]);
    _count[p] = (_count[p] ?? 0) + 1;
  }

  int count(List<int> point) {
    final x = point[0], y = point[1];
    var total = 0;
    _count.forEach((p, c) {
      final (px, py) = p;
      // A diagonal corner must differ in both coordinates by the same nonzero amount.
      if ((px - x).abs() != (py - y).abs() || px == x) return;
      total += c * (_count[(x, py)] ?? 0) * (_count[(px, y)] ?? 0);
    });
    return total;
  }
}
```

<!-- CODE:END -->

### Walkthrough

- Points are stored as Dart records `(int, int)` in a map, so equal coordinates share one key.
- `(px - x).abs() != (py - y).abs() || px == x` rejects non-diagonal points and zero-area squares.
- Missing corners count as 0 through `?? 0`.

## Step 5: Dry run

Stored: (3, 10), (11, 2), (3, 2). Query (11, 10):

| candidate diagonal | equal sides? | other corners | product |
|---|---|---|---|
| (3, 10) | dx 8, dy 0: no | | |
| (11, 2) | px == x: no | | |
| (3, 2) | dx 8, dy 8: yes | (11, 2): 1, (3, 10): 1 | 1 * 1 * 1 = 1 |

Answer **1**. After adding a second (11, 2), the product becomes 1 * 2 * 1 = **2**.

## Complexity

- `add`: **O(1)**.
- `count`: **O(P)**, P = number of distinct stored points.
- Space: **O(P)**.

## Edge cases

- The query point itself is not stored: it is not counted (only stored points are chosen).
- Duplicates: handled by multiplying counts.

## Common mistakes

- Counting zero-area "squares" when the diagonal equals the query point.
- Forgetting duplicates (using a set instead of counts).
- Counting each square more than once by also treating side corners as diagonals.

## Follow-ups you should be ready for

1. **Non-axis-aligned squares.** For each stored point as a neighbor corner, rotate the side vector 90 degrees to get the others.
2. **Count all squares in a static set of points.** AlgoExpert hard 8 Count Squares.
3. **Rectangles.** AlgoExpert very_hard 4 Minimum Area Rectangle.

## What to remember

For axis-aligned squares, one diagonal corner determines the rest. Enumerate the diagonal and multiply the counts of the forced corners.
