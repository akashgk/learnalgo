# Colliding Asteroids

**Difficulty:** Medium | **Category:** Stacks | **Pattern:** Stack simulation

## The problem

Asteroids are listed in order of position in a row. Each value's **sign** is its direction (positive: moving right, negative: moving left) and its **absolute value** is its size. When two asteroids meet, the smaller one explodes; if they are the same size, both explode. Asteroids moving in the same direction never meet. Return the asteroids remaining after all collisions, in order.

```
[-3, 5, -8, 6, 7, -4, -7]  ->  [-3, -8, 6]
[5, -5]                    ->  []
[-1, 1]                    ->  [-1, 1]     (moving apart)
```

## Step 1: When do two asteroids collide?

Only a **right-mover followed later by a left-mover** collide: they move toward each other. A left-mover followed by a right-mover drift apart. Two asteroids moving the same way keep their distance.

## Step 2: Work an example by hand

Process left to right, keeping the survivors so far:

- -3: moving left, nothing to its left moving right: survives. Survivors `[-3]`.
- 5: moving right: nothing to hit yet. `[-3, 5]`.
- -8: moving left; the last survivor 5 moves right: collision. 5 < 8: 5 explodes. Next survivor -3 moves left: no collision. -8 survives. `[-3, -8]`.
- 6, 7: moving right. `[-3, -8, 6, 7]`.
- -4: hits 7; 4 < 7: -4 explodes.
- -7: hits 7; equal: both explode. Next survivor 6... -7 is gone, so stop. `[-3, -8, 6]`.

A new left-mover fights the **most recent** survivors first: last in, first out. A stack.

## Step 3: The algorithm

For each asteroid `a`:

- While `a` is alive, moving left, and the stack top is moving right, they collide:
  - top smaller than |a|: pop the top (it explodes); `a` continues to the next top;
  - equal: pop the top; `a` also explodes;
  - top bigger: `a` explodes.
- If `a` survived, push it.

## Step 4: The code

<!-- CODE:START -->

Full source: [`colliding_asteroids.dart`](colliding_asteroids.dart) (run it with `dart run`).

```dart
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
```

<!-- CODE:END -->

### Walkthrough

- `var alive = true;` tracks whether the incoming asteroid survived its fights.
- The `while` condition encodes the physics: incoming moves left (`a < 0`) and the top moves right (`stack.last > 0`).
- Three outcomes: top explodes (loop continues), both explode, incoming explodes.
- `if (alive) stack.add(a);`

## Complexity

- **Time: O(n)**: each asteroid is pushed once and popped at most once.
- **Space: O(n)**.

## Common mistakes

- Treating a left-mover followed by a right-mover as a collision.
- Comparing signed values instead of sizes (`top < -a` compares sizes because `a` is negative).
- Stopping after the first fight when the incoming asteroid survives it.

## Follow-ups

1. **Asteroid Collision (LeetCode #735):** identical.
2. **Car Fleet (#853):** a related "who catches whom" simulation using sorting and a stack.

## What to remember

When new items interact with the most recent survivors first, simulate with a stack. Encode the interaction condition precisely in the loop.
