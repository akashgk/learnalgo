# Rotate Image

**Difficulty:** Medium | **Category:** Arrays (matrix) | **Pattern:** Transpose + reflect / layer rotation | **Source:** LeetCode 48; Striver A2Z, NeetCode 150

## The problem

Rotate an `n x n` matrix by 90 degrees **clockwise**, **in place** (do not allocate another matrix).

```
1 2 3        7 4 1
4 5 6   ->   8 5 2
7 8 9        9 6 3
```

### Clarifying questions to ask

| Question | Why it matters |
|---|---|
| Always square? | Yes. A non-square matrix cannot be rotated in place (the shape changes). |
| Clockwise or counterclockwise? | Changes which reflection you do after transposing. |
| In place required? | With a copy it is a one-liner; the interview is about doing it in O(1) space. |

## Step 1: Work an example by hand

Where does each cell go? The first **row** `1 2 3` becomes the last **column** read top to bottom. In general:

```
new[j][n - 1 - i] = old[i][j]
```

Check: `old[0][0] = 1` goes to `new[0][2]`. Correct, the top-right corner holds 1.

## Step 2: Brute force (extra matrix)

```dart
final out = List.generate(n, (_) => List.filled(n, 0));
for (i...) for (j...) out[j][n - 1 - i] = m[i][j];
```

O(n^2) time, O(n^2) space. Correct, but the problem forbids the extra matrix. We cannot just assign in place either, because `m[j][n-1-i] = m[i][j]` overwrites a value we still need.

## Step 3: Optimize to O(1) space

### Idea A: decompose the rotation into two easy in-place operations

A 90-degree clockwise rotation equals:

1. **Transpose** (reflect across the main diagonal): `m[i][j] <-> m[j][i]`.
2. **Reverse each row** (reflect left-right).

Why: the transpose sends `(i, j)` to `(j, i)`. Reversing the row sends `(j, i)` to `(j, n - 1 - i)`. Combined: `(i, j) -> (j, n - 1 - i)`, exactly the formula from Step 1.

Both operations are **swaps of pairs**, and swaps are naturally in place.

```
1 2 3   transpose   1 4 7   reverse rows   7 4 1
4 5 6   -------->   2 5 8   ----------->   8 5 2
7 8 9               3 6 9                  9 6 3
```

### Idea B: rotate four cells at a time

The formula applied four times returns to the start: every cell belongs to a **cycle of 4** (top -> right -> bottom -> left -> top). Process the matrix layer by layer (outer ring, then the next ring), and for each position in the top edge of a ring, rotate its 4-cycle with one temporary variable.

Idea A is easier to get right on a whiteboard. Idea B touches each cell once instead of twice. Know both; lead with A.

## Step 4: The code

<!-- CODE:START -->

Full source: [`rotate_matrix.dart`](rotate_matrix.dart) (run it with `dart run`).

```dart
// Rotate Image: rotate an n x n matrix 90 degrees clockwise, in place.
// Transpose, then reverse each row. O(n^2) time, O(1) extra space.

void rotate(List<List<int>> m) {
  final n = m.length;
  // Transpose: swap across the main diagonal (only the upper triangle, or we undo our own swaps).
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      final t = m[i][j];
      m[i][j] = m[j][i];
      m[j][i] = t;
    }
  }
  // Mirror left-right.
  for (final row in m) {
    for (var lo = 0, hi = n - 1; lo < hi; lo++, hi--) {
      final t = row[lo];
      row[lo] = row[hi];
      row[hi] = t;
    }
  }
}

/// Alternative: rotate four cells at a time, layer by layer. Same complexity, one pass.
void rotateLayers(List<List<int>> m) {
  final n = m.length;
  for (var layer = 0; layer < n ~/ 2; layer++) {
    final first = layer, last = n - 1 - layer;
    for (var k = 0; k < last - first; k++) {
      final top = m[first][first + k];
      m[first][first + k] = m[last - k][first]; // left -> top
      m[last - k][first] = m[last][last - k]; // bottom -> left
      m[last][last - k] = m[first + k][last]; // right -> bottom
      m[first + k][last] = top; // top -> right
    }
  }
}
```

<!-- CODE:END -->

### Walkthrough of `rotate`

- The transpose loop starts `j` at `i + 1`. Iterating over the **whole** matrix would swap every pair twice and undo the transpose.
- The reversal loop uses two pointers per row, swapping inward.

### Walkthrough of `rotateLayers`

- `layer` runs over `n ~/ 2` rings. The center of an odd matrix never moves.
- For ring `layer`, `first = layer` and `last = n - 1 - layer` are its bounds, and `k` walks along the top edge (excluding the last corner, which is the first element of the right edge's cycle).
- The four assignments move left -> top, bottom -> left, right -> bottom, saved top -> right. Writing them in this order (counterclockwise) means each read happens before that cell is overwritten.

## Step 5: Dry run

4 x 4 example with `rotateLayers`, outer ring (`first = 0`, `last = 3`), `k = 0`, the four corners:

| Cell | Before | After |
|---|---|---|
| top-left `[0][0]` | 5 | 15 (from bottom-left) |
| bottom-left `[3][0]` | 15 | 16 (from bottom-right) |
| bottom-right `[3][3]` | 16 | 11 (from top-right) |
| top-right `[0][3]` | 11 | 5 (saved top) |

`k = 1` and `k = 2` do the same for the other edge cells, then the inner 2 x 2 ring is one more 4-cycle.

## Complexity

- Time: **O(n^2)**. Every cell is moved a constant number of times.
- Space: **O(1)** extra.

## Edge cases

- `n = 1`: both loops do nothing.
- `n = 2`: one ring, one 4-cycle.
- Odd `n`: the center cell stays put in both methods.

## Common mistakes

- Transposing over the full matrix (double swap = no-op).
- Reversing **columns** instead of rows after the transpose: that gives a counterclockwise rotation.
- Off-by-one in the layer loop: iterating `k` up to `last - first` inclusive rotates the corner twice.

## Follow-ups you should be ready for

1. **Counterclockwise.** Transpose, then reverse each **column** (or reverse rows first, then transpose).
2. **180 degrees.** Reverse the order of the rows, then reverse each row.
3. **Non-square matrix.** Must allocate a new `cols x rows` matrix.
4. **Rotate by k * 90 degrees.** Use `k % 4`.

## What to remember

A hard in-place transformation can often be written as a composition of simple in-place ones. Rotation = transpose + reflect.
