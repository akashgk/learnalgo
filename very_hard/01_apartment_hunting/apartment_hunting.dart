// Apartment Hunting: choose the block minimizing the farthest distance to any required
// building. For each requirement, nearest distance per block via left and right sweeps.
// O(b * r) time, O(b * r) space.

int apartmentHunting(List<Map<String, bool>> blocks, List<String> reqs) {
  final b = blocks.length;
  // nearest[r][i] = distance from block i to the nearest block with requirement r
  final nearest = <List<int>>[];
  const inf = 1 << 40;
  for (final req in reqs) {
    final dist = List<int>.filled(b, inf);
    var last = -1;
    for (var i = 0; i < b; i++) {
      if (blocks[i][req] ?? false) last = i;
      if (last != -1) dist[i] = i - last;
    }
    last = -1;
    for (var i = b - 1; i >= 0; i--) {
      if (blocks[i][req] ?? false) last = i;
      if (last != -1 && last - i < dist[i]) dist[i] = last - i;
    }
    nearest.add(dist);
  }
  var bestIdx = 0, bestWorst = inf;
  for (var i = 0; i < b; i++) {
    var worst = 0;
    for (final dist in nearest) {
      if (dist[i] > worst) worst = dist[i];
    }
    if (worst < bestWorst) {
      bestWorst = worst;
      bestIdx = i;
    }
  }
  return bestIdx;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final blocks = [
    {'gym': false, 'school': true, 'store': false},
    {'gym': true, 'school': false, 'store': false},
    {'gym': true, 'school': true, 'store': false},
    {'gym': false, 'school': true, 'store': false},
    {'gym': false, 'school': true, 'store': true},
  ];
  check(apartmentHunting(blocks, ['gym', 'school', 'store']), 3);
  check(apartmentHunting([{'foo': true}], ['foo']), 0);
}
