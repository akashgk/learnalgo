// Colliding Asteroids: positive moves right, negative moves left. When they meet, the smaller
// (by absolute size) explodes; equal sizes both explode. Stack of survivors.
// O(n) time, O(n) space.

List<int> collidingAsteroids(List<int> asteroids) {
  final stack = <int>[];
  for (final a in asteroids) {
    var alive = true;
    // Collision only when the incoming moves left and the top moves right.
    while (alive && a < 0 && stack.isNotEmpty && stack.last > 0) {
      final top = stack.last;
      if (top < -a) {
        stack.removeLast(); // top explodes, keep checking
      } else if (top == -a) {
        stack.removeLast(); // both explode
        alive = false;
      } else {
        alive = false; // incoming explodes
      }
    }
    if (alive) stack.add(a);
  }
  return stack;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(collidingAsteroids([-3, 5, -8, 6, 7, -4, -7]), [-3, -8, 6]);
  check(collidingAsteroids([5, -5]), []);
  check(collidingAsteroids([-1, 1]), [-1, 1]); // moving apart, never collide
  check(collidingAsteroids([10, 2, -5]), [10]);
}
