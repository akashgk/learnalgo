# Shorten Path

**Difficulty:** Hard | **Category:** Stacks | **Pattern:** Stack of path segments

## The problem

Given a Unix-style file path, return the **shortest equivalent** path. The path is **absolute** if it starts with `/`, otherwise **relative**. Handle:

- `.` (the current directory: does nothing),
- `..` (the parent directory),
- repeated slashes (`//` is the same as `/`).

Relative paths may start with `..` segments that cannot be resolved; those must be kept.

```
"/foo/../test/../test/../foo//bar/./baz"  ->  "/foo/bar/baz"
"foo/../.."                               ->  ".."
"/../.."                                  ->  "/"
"../../foo/bar/.."                        ->  "../../foo"
```

## Step 1: Work an example by hand

Read `/foo/../test/../test/../foo//bar/./baz` segment by segment, keeping track of the current directory:

| segment | meaning | current path |
|---|---|---|
| foo | go into foo | /foo |
| .. | go up | / |
| test | into test | /test |
| .. | up | / |
| test, .. | into, up | / |
| foo | into foo | /foo |
| (empty) | from `//`, ignore | /foo |
| bar | into bar | /foo/bar |
| . | stay | /foo/bar |
| baz | into baz | /foo/bar/baz |

"Go into" pushes a name; "go up" removes the **most recent** name. That is a **stack**.

## Step 2: The rules

Split on `/` and process each token:

- empty or `.`: ignore;
- a name: push;
- `..`:
  - if the stack's top is a real name: pop it;
  - if the stack is empty or its top is also `..`:
    - **absolute** path: ignore (you cannot go above the root `/`);
    - **relative** path: push `..` (it cannot be resolved, so it must stay).

Finally, join with `/`, prefix `/` for absolute paths, and use `.` for an empty relative result.

## Step 3: The code

<!-- CODE:START -->

Full source: [`shorten_path.dart`](shorten_path.dart) (run it with `dart run`).

```dart
// Shorten Path: simplify a Unix path (handles '.', '..', repeated '/', absolute vs relative).
// Stack of directory tokens. O(n) time and space.

String shortenPath(String path) {
  final isAbsolute = path.startsWith('/');
  final stack = <String>[];
  for (final token in path.split('/')) {
    if (token.isEmpty || token == '.') continue;
    if (token == '..') {
      if (stack.isEmpty || stack.last == '..') {
        // Relative paths keep leading '..'; absolute paths cannot go above root.
        if (!isAbsolute) stack.add('..');
      } else {
        stack.removeLast();
      }
    } else {
      stack.add(token);
    }
  }
  final joined = stack.join('/');
  return isAbsolute ? '/$joined' : (joined.isEmpty ? '.' : joined);
}
```

<!-- CODE:END -->

### Walkthrough

- `isAbsolute` is decided once from the first character.
- `path.split('/')` produces empty tokens for leading, trailing, and repeated slashes; they are skipped.
- The `..` branch implements the rules from Step 2.
- The return line handles the absolute prefix and the empty relative case.

## Step 4: Dry run: `"foo/../.."` (relative)

| token | stack before | action | stack after |
|---|---|---|---|
| foo | [] | push | [foo] |
| .. | [foo] | pop | [] |
| .. | [] | relative: push `..` | [..] |

Result: `".."`.

## Complexity

- **Time: O(n)**.
- **Space: O(n)**.

## Common mistakes

- Treating relative paths like absolute ones (dropping unresolvable `..`).
- Allowing `..` to go above the root of an absolute path.
- Returning an empty string instead of `/` or `.`.

## Follow-ups

1. **Simplify Path (LeetCode #71):** absolute paths only.
2. **Symbolic links:** a real filesystem cannot simplify `a/../b` without knowing whether `a` is a symlink. Mentioning this shows real-world awareness.

## What to remember

Directory navigation is a stack: names push, `..` pops. Handle the edge cases (absolute root, relative leading `..`, empty result) explicitly.
