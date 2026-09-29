# Line Through Points

**Difficulty:** Very Hard | **Category:** Arrays | **Pattern:** Anchor point + hash map of exact slopes

## The problem

Given distinct 2D integer points, return the **maximum number of points that lie on one straight line**.

```
[[1, 1], [2, 2], [3, 3], [0, 4], [-2, 6], [4, 0], [2, 1]]  ->  4
```

Check: `(0, 4)`, `(-2, 6)`, `(4, 0)`, `(2, 2)` all satisfy `x + y = 4`: 4 points. `(1,1), (2,2), (3,3)` is another line with 3.

## Step 1: Brute force

Every pair of points defines a line; count the points on it: O(n^2) pairs times O(n): **O(n^3)**.

## Step 2: Fix an anchor

Fix one point A. Every line through A is identified by its **slope**. Two other points are on the same line through A iff they have the **same slope** from A. So for anchor A, group the other points by slope in a hash map; the biggest group plus A itself is the best line through A.

Doing this for every anchor gives the global answer: **O(n^2)** (times the cost of computing a slope key).

Only points **after** the anchor need to be considered: a line containing an earlier point was already counted when that earlier point was the anchor.

## Step 3: Represent slopes exactly

Using `dy / dx` as a floating-point number is dangerous:

- vertical lines divide by zero;
- rounding can make equal slopes compare unequal (or unequal slopes equal) in hashing.

Instead, store the slope as a **reduced fraction** `(dy, dx)`:

1. divide both by `gcd(|dy|, |dx|)`;
2. fix the sign so equal slopes get the same key: make `dx` positive, or if `dx == 0`, make `dy` positive. (`(1, 2)` and `(-1, -2)` are the same slope.)

Vertical lines become `(1, 0)` and horizontal lines `(0, 1)`: no special cases.

## Step 4: The code

<!-- CODE:START -->

Full source: [`line_through_points.dart`](line_through_points.dart) (run it with `dart run`).

```dart
// Line Through Points: maximum number of points on one straight line.
// For each anchor point, bucket the others by reduced slope (dy, dx) with gcd normalization.
// O(n^2) time (times log for gcd), O(n) space.

int lineThroughPoints(List<List<int>> points) {
  if (points.length < 3) return points.length;
  var best = 1;
  for (var i = 0; i < points.length; i++) {
    final slopes = <(int, int), int>{};
    for (var j = i + 1; j < points.length; j++) {
      var dx = points[j][0] - points[i][0], dy = points[j][1] - points[i][1];
      final g = _gcd(dx.abs(), dy.abs());
      dx ~/= g;
      dy ~/= g;
      // Canonical sign: dx > 0, or dx == 0 and dy > 0, so (1, 2) and (-1, -2) match.
      if (dx < 0 || (dx == 0 && dy < 0)) {
        dx = -dx;
        dy = -dy;
      }
      final count = slopes.update((dy, dx), (c) => c + 1, ifAbsent: () => 1);
      if (count + 1 > best) best = count + 1; // + the anchor point
    }
  }
  return best;
}

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);
```

<!-- CODE:END -->

### Walkthrough

- Fewer than 3 points: they are all on one line.
- For each anchor `i`, `slopes` maps a normalized `(dy, dx)` record to the number of later points with that slope.
- `_gcd` is Euclid's algorithm.
- `count + 1` includes the anchor.

## Step 5: Dry run (anchor (0, 4))

| other point | (dx, dy) | reduced, normalized key (dy, dx) |
|---|---|---|
| (-2, 6) | (-2, 2) | (-1, 1) after sign fix |
| (4, 0) | (4, -4) | (-1, 1) |
| (2, 1) | (2, -3) | (-3, 2) |

Points before (0, 4) in the list, such as (2, 2), are not revisited from this anchor; the line `x + y = 4` is fully counted when the anchor is the earliest of its points, (2, 2): its later points (0, 4), (-2, 6), (4, 0) all share the key (-1, 1), giving 3 + 1 = **4**.

## Complexity

- **Time: O(n^2 log V)**, where the log factor is the gcd on coordinates up to V.
- **Space: O(n)** for the per-anchor map.

## Common mistakes

- Floating-point slopes.
- Not normalizing the sign of `(dy, dx)`.
- Forgetting vertical lines.

## Follow-ups

1. **Max Points on a Line (LeetCode #149):** identical. If duplicate points are allowed, count duplicates of the anchor separately and add them to every group.
2. **Check whether all points are collinear:** one anchor is enough.

## What to remember

Fix an anchor and group other points by exact slope. Represent slopes as reduced fractions with a canonical sign, never as floats.
