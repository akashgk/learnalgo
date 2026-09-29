# Generate Div Tags

**Difficulty:** Hard | **Category:** Recursion | **Pattern:** Backtracking with validity counters (balanced parentheses)

## The problem

Given a positive integer n, return every string made of exactly n `<div>` tags and n `</div>` tags that is **properly matched and nested**. Order does not matter.

```
n = 2  ->  ["<div><div></div></div>", "<div></div><div></div>"]
n = 3  ->  5 strings
```

## Step 1: Simplify

Replace `<div>` with `(` and `</div>` with `)`. The question becomes: generate all balanced parentheses strings with n pairs (LeetCode #22).

## Step 2: Brute force

Generate all `2^(2n)` sequences of opens and closes, keep the balanced ones. Most sequences are invalid, so most of the work is wasted.

## Step 3: Only build valid prefixes

Build the string left to right. At each step there are at most two choices, and each has a simple validity rule:

- **Add an opening tag** if any opening tags remain.
- **Add a closing tag** only if it closes something that is currently open, which means **more closing tags remain than opening tags** (`closesLeft > opensLeft`).

Every prefix built this way can be completed to a valid string, and every complete string is valid. No wasted branches.

```
build(opensLeft, closesLeft):
    if both are 0: record the string
    if opensLeft > 0:             add "<div>",  build(opensLeft - 1, closesLeft), remove it
    if closesLeft > opensLeft:    add "</div>", build(opensLeft, closesLeft - 1), remove it
```

## Step 4: The code

<!-- CODE:START -->

Full source: [`generate_div_tags.dart`](generate_div_tags.dart) (run it with `dart run`).

```dart
// Generate Div Tags: all valid (properly nested) strings of n "<div>" and n "</div>" tags.
// Backtracking with counts of remaining opens and closes. O(C(n) * n) time and space,
// where C(n) is the nth Catalan number.

List<String> generateDivTags(int numberOfTags) {
  final result = <String>[];
  final current = <String>[];

  void build(int opensLeft, int closesLeft) {
    if (opensLeft == 0 && closesLeft == 0) {
      result.add(current.join());
      return;
    }
    if (opensLeft > 0) {
      current.add('<div>');
      build(opensLeft - 1, closesLeft);
      current.removeLast();
    }
    if (closesLeft > opensLeft) {
      // can only close a tag that is currently open
      current.add('</div>');
      build(opensLeft, closesLeft - 1);
      current.removeLast();
    }
  }

  build(numberOfTags, numberOfTags);
  return result;
}
```

<!-- CODE:END -->

### Walkthrough

- `current` is a list of tags (append and remove at the end are O(1); joining happens only at the leaves).
- The two `if` blocks are the two choices, each followed by an undo (`removeLast`).

## Step 5: Dry run (n = 2)

| path (opensLeft, closesLeft) | tags so far | result |
|---|---|---|
| (2,2) -> open -> (1,2) -> open -> (0,2) -> close -> close | `<div><div></div></div>` | recorded |
| (2,2) -> open -> (1,2) -> close -> (1,1) -> open -> (0,1) -> close | `<div></div><div></div>` | recorded |

At `(1, 1)` a close is not allowed (`closesLeft` is not greater than `opensLeft`), which prevents `<div></div></div>...`.

## Complexity

The number of valid strings is the **n-th Catalan number** `C(n) = (2n)! / ((n + 1)! n!)`: 1, 2, 5, 14, 42, ... It grows like `4^n / (n^1.5 * sqrt(pi))`.

- **Time: O(C(n) * n)**: each result has length 2n.
- **Space: O(C(n) * n)** for the output; O(n) recursion depth.

## Common mistakes

- Allowing a close whenever `closesLeft > 0` (produces invalid strings).
- Building strings by concatenation in every call (extra copying).

## Follow-ups

1. **Generate Parentheses (LeetCode #22).**
2. **Valid Parenthesis String with wildcards (#678).**
3. **Catalan numbers** also count binary tree shapes (Number Of Binary Tree Topologies, very hard 29) and monotonic lattice paths that stay below the diagonal.

## What to remember

Generate only valid prefixes by enforcing the validity rule at every step. Balanced strings with n pairs are counted by the Catalan numbers.
