// Laptop Rentals: min laptops so every [start, end) interval gets one (a laptop freed at t can
// be reused by a rental starting at t). Sweep over sorted starts and ends.
// O(n log n) time, O(n) space.

int laptopRentals(List<List<int>> times) {
  final starts = [for (final t in times) t[0]]..sort();
  final ends = [for (final t in times) t[1]]..sort();
  var inUse = 0, best = 0, e = 0;
  for (final s in starts) {
    while (e < ends.length && ends[e] <= s) {
      e++; // a laptop was returned before or exactly when this rental starts
      inUse--;
    }
    inUse++;
    if (inUse > best) best = inUse;
  }
  return best;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(laptopRentals([[0, 2], [1, 4], [4, 6], [0, 4], [7, 8], [9, 11], [3, 10]]), 3);
  check(laptopRentals([]), 0);
  check(laptopRentals([[0, 5], [5, 10]]), 1);
  check(laptopRentals([[0, 5], [1, 2], [1, 3]]), 3);
}
