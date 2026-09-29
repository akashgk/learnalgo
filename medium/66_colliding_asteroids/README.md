# Colliding Asteroids

**Difficulty:** Medium | **Category:** Stacks | **Pattern:** Stack simulation

## Problem
Asteroids are given in order of position. The sign is direction (positive: right, negative: left) and the absolute value is size. When two meet, the smaller one explodes; if equal, both explode. Asteroids moving in the same direction never meet. Return the asteroids that remain.

## Building up the logic
1. A collision only happens between a right-mover that is **earlier** and a left-mover that is **later**. A left-mover followed by a right-mover drift apart.
2. Scan left to right with a stack of survivors so far. A new right-mover cannot hit anything yet: push it.
3. A new left-mover fights the stack top while the top is a right-mover:
   - top smaller: top explodes, continue fighting the next top;
   - equal: both explode, stop;
   - top bigger: the new one explodes, stop.
4. If it survives all fights, push it.

## Complexity
- Time: O(n): each asteroid is pushed and popped at most once.
- Space: O(n).

## Interview notes
- LeetCode #735 (Asteroid Collision). The loop condition (`a < 0 && top > 0`) encodes the physics; say it explicitly.
