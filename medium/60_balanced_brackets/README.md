# Balanced Brackets

**Difficulty:** Medium | **Category:** Stacks | **Pattern:** Stack matching

## The problem

Given a string, return whether its brackets are **balanced**: every opening bracket `(`, `[`, `{` is closed by the matching type, in the correct order, and no closing bracket appears without a matching opener. Other characters are ignored.

```
"([])(){}(())()()"  ->  true
"(a[b]c)"           ->  true
"([)]"              ->  false   (square bracket closed by a round one)
"(("                ->  false   (never closed)
")"                 ->  false   (nothing to close)
```

## Step 1: Why counting fails

Counting openers and closers per type catches `"(("` and `")"`, but not `"([)]"`: one of each, yet the order is wrong. The `]` must close the **most recently opened** bracket, which is `(`. Order matters.

## Step 2: The stack

"The most recently opened bracket must be closed first" is **last in, first out**: a stack.

- Opening bracket: push it.
- Closing bracket: the stack must be non-empty and its top must be the matching opener; pop it. Otherwise, unbalanced.
- Other characters: ignore.
- At the end: the stack must be empty (no unclosed openers).

## Step 3: The code

<!-- CODE:START -->

Full source: [`balanced_brackets.dart`](balanced_brackets.dart) (run it with `dart run`).

```dart
// Balanced Brackets: (), [], {} properly nested; other characters are ignored.
// Stack of expected closers. O(n) time, O(n) space.

bool balancedBrackets(String string) {
  const pairs = {')': '(', ']': '[', '}': '{'};
  const openers = {'(', '[', '{'};
  final stack = <String>[];
  for (final ch in string.split('')) {
    if (openers.contains(ch)) {
      stack.add(ch);
    } else if (pairs.containsKey(ch)) {
      if (stack.isEmpty || stack.removeLast() != pairs[ch]) return false;
    }
  }
  return stack.isEmpty; // unmatched openers left over means unbalanced
}
```

<!-- CODE:END -->

### Walkthrough

- `pairs` maps each closer to its opener, so matching is one lookup.
- `stack.removeLast() != pairs[ch]` pops and compares in one expression. If the stack is empty, `stack.isEmpty ||` short-circuits first, avoiding an error.
- `return stack.isEmpty;` rejects leftover openers.

## Step 4: Dry run on `"([)]"`

| char | action | stack after |
|---|---|---|
| ( | push | ( |
| [ | push | ( [ |
| ) | top is `[`, needs `(`: mismatch | return false |

## Complexity

- **Time: O(n)**.
- **Space: O(n)** for the stack (all openers in the worst case).

## Common mistakes

- Forgetting the final `isEmpty` check (`"(("` would pass).
- Popping from an empty stack on an early closer.
- Only one bracket type? Then a counter is enough (O(1) space); with several types you need the stack.

## Follow-ups

1. **Valid Parentheses (LeetCode #20):** identical.
2. **Minimum Add to Make Parentheses Valid (#921):** count unmatched openers and closers.
3. **Longest Valid Parentheses (#32):** see Longest Balanced Substring (very hard 36).
4. **Generate all balanced strings:** Generate Div Tags (hard 42).
5. **Validate HTML/XML tags:** the same stack, with tag names instead of characters.

## What to remember

Nested structure = stack. Push openers; a closer must match the top.
