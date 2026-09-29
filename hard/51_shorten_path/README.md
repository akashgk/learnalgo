# Shorten Path

**Difficulty:** Hard | **Category:** Stacks | **Pattern:** Stack of path segments

## Problem
Given a Unix-style path (absolute if it starts with `/`, relative otherwise), return the shortest equivalent path. Handle `.` (current directory), `..` (parent), and repeated slashes. Relative paths may start with `..` segments that cannot be resolved.

## Building up the logic
1. Split on `/`. Empty tokens (from `//` or the leading `/`) and `.` do nothing.
2. A normal name is "go into this directory": push.
3. `..` is "go back up": pop the last directory. That undo behavior is why a stack fits.
4. Edge cases (where most of the difficulty is):
   - absolute path at root: `..` above `/` stays at `/` (ignore it);
   - relative path: `..` with nothing to cancel must be **kept** (`foo/../..` -> `..`), and consecutive unresolved `..` stack up;
   - an empty relative result is `.`; an empty absolute result is `/`.
5. Rejoin with `/`, prefixing `/` for absolute paths.

## Complexity
- Time: O(n).
- Space: O(n).

## Interview notes
- LeetCode #71 (Simplify Path) covers only absolute paths. Asking "absolute or relative?" before coding is the kind of clarification interviewers reward.
