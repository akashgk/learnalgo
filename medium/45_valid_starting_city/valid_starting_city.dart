// Valid Starting City (circular route, gas station variant).
// Track fuel surplus with no initial fuel; the valid start is the city just after the
// point where the running surplus is lowest. O(n) time, O(1) space.

int validStartingCity(List<int> distances, List<int> fuel, int mpg) {
  var surplus = 0, minSurplus = 0, start = 0;
  for (var city = 1; city < distances.length; city++) {
    // Arrive at `city` after leaving city - 1.
    surplus += fuel[city - 1] * mpg - distances[city - 1];
    if (surplus < minSurplus) {
      minSurplus = surplus;
      start = city;
    }
  }
  return start;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(validStartingCity([5, 25, 15, 10, 15], [1, 2, 1, 0, 3], 10), 4);
  check(validStartingCity([10, 20, 10, 15, 5, 15, 25], [0, 2, 1, 0, 0, 1, 1], 20), 1);
  check(validStartingCity([30, 25, 5, 100, 40], [3, 2, 1, 0, 4], 20), 4);
}
