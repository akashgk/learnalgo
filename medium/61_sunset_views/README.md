# Sunset Views

**Difficulty:** Medium | **Category:** Stacks | **Pattern:** Running maximum from one side (or monotonic stack)

## The problem

Buildings stand in a row; `buildings[i]` is the height of building `i` (index 0 is the westmost). All buildings face the same direction, `"EAST"` or `"WEST"`, where the sun sets. A building can see the sunset if it is **strictly taller** than every building between it and the sun in the direction it faces. Return the indices of those buildings, sorted ascending.

```
buildings = [3, 5, 4, 4, 3, 1, 3, 2]
"EAST"  ->  [1, 3, 6, 7]
"WEST"  ->  [0, 1]
```

## Step 1: Work an example by hand

Facing east, the sun is to the right. Building 7 (height 2) sees it: nothing is in the way. Building 6 (height 3) is taller than everything to its right (2): sees it. Building 5 (height 1) is blocked by building 6. Building 4 (3) is not strictly taller than building 6 (3): blocked. Building 3 (4) is taller than everything to its right: sees it. And so on.

Notice that you only compared each building with **the tallest building between it and the sun**.

## Step 2: Brute force

For each building, check all buildings between it and the sun: O(n^2).

## Step 3: Scan from the sun's side with a running maximum

Walk from the sun toward the other end (for east: right to left), keeping the tallest height seen so far. A building sees the sunset iff it is taller than that running maximum. Then update the maximum.

For "EAST" the scan runs right to left, so the collected indices are in descending order; reverse them at the end.

## Step 4: The monotonic stack view (know it too)

Alternatively, scan **away from** the sun (for east: left to right) with a stack of candidate buildings. For each new building, pop every candidate that is **not taller** than it (the new building now blocks them), then push it. At the end, the stack holds exactly the buildings that see the sunset, in ascending index order.

Same O(n). This version is useful when buildings arrive as a stream from the far side, and it is the same technique as Next Greater Element and Largest Rectangle Under Skyline.

## Step 5: The code

<!-- CODE:START -->

Full source: [`sunset_views.dart`](sunset_views.dart) (run it with `dart run`).

```dart
// Sunset Views: buildings facing EAST or WEST can see the sunset if strictly taller than
// every building between them and the sun. Scan from the sun side keeping the running max.
// O(n) time, O(n) output. Returns indices in ascending order.

List<int> sunsetViews(List<int> buildings, String direction) {
  final result = <int>[];
  final facingEast = direction == 'EAST';
  final indices = facingEast
      ? List<int>.generate(buildings.length, (i) => buildings.length - 1 - i) // sun on the right
      : List<int>.generate(buildings.length, (i) => i);
  var tallest = 0;
  for (final i in indices) {
    if (buildings[i] > tallest) {
      result.add(i);
      tallest = buildings[i];
    }
  }
  return facingEast ? result.reversed.toList() : result;
}
```

<!-- CODE:END -->

### Walkthrough

- `indices` lists the scan order: descending for east, ascending for west.
- `var tallest = 0;` works because heights are positive.
- A building is added when strictly taller than `tallest`.
- For east, `result.reversed.toList()` returns ascending indices.

## Step 6: Dry run (EAST)

| index | height | tallest before | sees sunset? | tallest after |
|---|---|---|---|---|
| 7 | 2 | 0 | yes | 2 |
| 6 | 3 | 2 | yes | 3 |
| 5 | 1 | 3 | no | 3 |
| 4 | 3 | 3 | no (not strictly taller) | 3 |
| 3 | 4 | 3 | yes | 4 |
| 2 | 4 | 4 | no | 4 |
| 1 | 5 | 4 | yes | 5 |
| 0 | 3 | 5 | no | 5 |

Collected `[7, 6, 3, 1]`, reversed: `[1, 3, 6, 7]`.

## Complexity

- **Time: O(n)**.
- **Space: O(n)** for the output; O(1) extra for the running-maximum version.

## Common mistakes

- Using `>=` (equal heights block the view).
- Scanning from the wrong side for the running-maximum version.

## Follow-ups

1. **Buildings With an Ocean View (LeetCode #1762):** identical (ocean to the east).
2. **Next Greater Element (medium 64):** for each building, the first taller building to its right.
3. **Number of Visible People in a Queue (#1944):** monotonic stack counting.

## What to remember

"Taller than everything between me and X" = compare with a running maximum scanned from X's side.
