// Waterfall Streams: grid of 0 (empty) / 1 (block). Water is poured at `source` in the top row.
// It falls straight down; on hitting a block it splits in half, each half moving sideways along
// its current row until it can fall again. A half that hits a block or the grid edge while moving
// sideways is lost. Return the percentage of water reaching each bottom-row column.
// O(w^2 * h) time, O(w) space.

List<double> waterfallStreams(List<List<double>> array, int source) {
  final width = array[0].length;
  var water = List<double>.filled(width, 0)..[source] = 1.0; // water in the current row
  for (var r = 1; r < array.length; r++) {
    final above = array[r - 1], row = array[r];
    final next = List<double>.filled(width, 0);
    for (var c = 0; c < width; c++) {
      final amount = water[c];
      if (amount == 0) continue;
      if (row[c] != 1) {
        next[c] += amount; // falls straight down
        continue;
      }
      final half = amount / 2;
      // Move right along the row above until there is an opening below.
      for (var k = c + 1; k < width; k++) {
        if (above[k] == 1) break; // blocked sideways: this half is lost
        if (row[k] != 1) {
          next[k] += half;
          break;
        }
      }
      for (var k = c - 1; k >= 0; k--) {
        if (above[k] == 1) break;
        if (row[k] != 1) {
          next[k] += half;
          break;
        }
      }
    }
    water = next;
  }
  return [for (final w in water) w * 100];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final grid = [
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    [1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    [0.0, 0.0, 1.0, 1.0, 1.0, 0.0, 0.0],
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    [1.0, 1.0, 1.0, 0.0, 0.0, 1.0, 0.0],
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0],
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
  ];
  check(waterfallStreams(grid, 3), [0.0, 0.0, 0.0, 25.0, 25.0, 0.0, 0.0]);
  check(
    waterfallStreams([
      [0.0, 0.0],
      [0.0, 0.0],
    ], 1),
    [0.0, 100.0],
  );
  check(
    waterfallStreams([
      [0.0, 0.0, 0.0],
      [0.0, 1.0, 0.0],
      [0.0, 0.0, 0.0],
    ], 1),
    [50.0, 0.0, 50.0],
  );
}
