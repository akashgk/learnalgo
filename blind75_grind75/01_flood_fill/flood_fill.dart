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

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    floodFill(
      [
        [1, 1, 1],
        [1, 1, 0],
        [1, 0, 1],
      ],
      1,
      1,
      2,
    ),
    [
      [2, 2, 2],
      [2, 2, 0],
      [2, 0, 1],
    ],
  ); // the bottom-right 1 is only diagonally connected: untouched
  check(
    floodFill(
      [
        [0, 0, 0],
        [0, 0, 0],
      ],
      0,
      0,
      0,
    ),
    [
      [0, 0, 0],
      [0, 0, 0],
    ],
  ); // same color: no change
  check(
    floodFill(
      [
        [5],
      ],
      0,
      0,
      7,
    ),
    [
      [7],
    ],
  );
}
