// Pacific Atlantic Water Flow: water flows from a cell to a neighbor with height <= its own.
// The Pacific touches the top and left edges, the Atlantic the bottom and right edges.
// Return the cells from which water can reach both oceans.
// Reverse the flow: DFS uphill (to neighbors >= current) from each ocean's border cells; answer is
// the intersection of the two reachable sets. O(rows * cols) time and space.

List<List<int>> pacificAtlantic(List<List<int>> heights) {
  final rows = heights.length, cols = heights[0].length;
  final pacific = List.generate(rows, (_) => List<bool>.filled(cols, false));
  final atlantic = List.generate(rows, (_) => List<bool>.filled(cols, false));

  void climb(int r, int c, List<List<bool>> reached) {
    if (reached[r][c]) return;
    reached[r][c] = true;
    for (final (dr, dc) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final nr = r + dr, nc = c + dc;
      if (nr < 0 || nc < 0 || nr >= rows || nc >= cols) continue;
      // Water could flow from (nr, nc) down to (r, c) only if (nr, nc) is at least as high.
      if (heights[nr][nc] >= heights[r][c]) climb(nr, nc, reached);
    }
  }

  for (var c = 0; c < cols; c++) {
    climb(0, c, pacific); // top edge
    climb(rows - 1, c, atlantic); // bottom edge
  }
  for (var r = 0; r < rows; r++) {
    climb(r, 0, pacific); // left edge
    climb(r, cols - 1, atlantic); // right edge
  }
  return [
    for (var r = 0; r < rows; r++)
      for (var c = 0; c < cols; c++)
        if (pacific[r][c] && atlantic[r][c]) [r, c],
  ];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    pacificAtlantic([
      [1, 2, 2, 3, 5],
      [3, 2, 3, 4, 4],
      [2, 4, 5, 3, 1],
      [6, 7, 1, 4, 5],
      [5, 1, 1, 2, 4],
    ]),
    [
      [0, 4],
      [1, 3],
      [1, 4],
      [2, 2],
      [3, 0],
      [3, 1],
      [4, 0],
    ],
  );
  check(
    pacificAtlantic([
      [1],
    ]),
    [
      [0, 0],
    ],
  );
  check(
    pacificAtlantic([
      [2, 1],
      [1, 2],
    ]),
    [
      [0, 0],
      [0, 1],
      [1, 0],
      [1, 1],
    ],
  );
}
