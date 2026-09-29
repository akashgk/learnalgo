# Reverse Polish Notation

**Difficulty:** Medium | **Category:** Stacks | **Pattern:** Stack-based expression evaluation

## The problem

Evaluate an arithmetic expression written in **Reverse Polish Notation** (postfix): operators come **after** their operands. Tokens are integers or one of `+ - * /`. Division truncates toward zero. The expression is valid.

```
["50", "3", "17", "+", "2", "-", "/"]   =   50 / ((3 + 17) - 2)   =   2
["2", "1", "+", "3", "*"]              =   (2 + 1) * 3           =   9
```

## Step 1: Why postfix is easy for machines

In infix (`(3 + 17) - 2`) you need parentheses and precedence rules. In postfix, there is no ambiguity: an operator always applies to the **two most recent values**. No parentheses, no precedence. That is why stack-based calculators and virtual machines (the JVM, Python's bytecode, WebAssembly) use it.

## Step 2: The algorithm

"The two most recent values" = the top two elements of a stack.

- Number: push it.
- Operator: pop the **right** operand, then pop the **left** operand, compute `left op right`, push the result.
- At the end, the stack holds exactly one value: the answer.

## Step 3: The code

<!-- CODE:START -->

Full source: [`reverse_polish_notation.dart`](reverse_polish_notation.dart) (run it with `dart run`).

```dart
// Reverse Polish Notation evaluation. Stack of operands; operators pop two.
// Division truncates toward zero. O(n) time, O(n) space.

int reversePolishNotation(List<String> tokens) {
  final stack = <int>[];
  for (final token in tokens) {
    if (const {'+', '-', '*', '/'}.contains(token)) {
      final right = stack.removeLast(), left = stack.removeLast(); // order matters
      stack.add(switch (token) {
        '+' => left + right,
        '-' => left - right,
        '*' => left * right,
        _ => left ~/ right,
      });
    } else {
      stack.add(int.parse(token));
    }
  }
  return stack.single;
}
```

<!-- CODE:END -->

### Walkthrough

- `const {'+', '-', '*', '/'}.contains(token)` checks for an operator by **exact** match. Checking only the first character would misread negative numbers like `"-7"` as a minus operator.
- `final right = stack.removeLast(), left = stack.removeLast();` pops in the correct order: the right operand is on top.
- The `switch` expression computes the result; `~/` truncates toward zero.
- `stack.single` returns the only element (and throws if the expression was malformed, which is a useful sanity check).

## Step 4: Dry run

`["50", "3", "17", "+", "2", "-", "/"]`:

| token | stack after |
|---|---|
| 50 | 50 |
| 3 | 50, 3 |
| 17 | 50, 3, 17 |
| + | 50, 20 |
| 2 | 50, 20, 2 |
| - | 50, 18 |
| / | 2 (50 ~/ 18) |

## Complexity

- **Time: O(n)**.
- **Space: O(n)** for the stack.

## Common mistakes

- Popping operands in the wrong order (`right - left` instead of `left - right`): matters for `-` and `/`.
- Using floor division for negative results (`-7 / 2` must be -3, not -4).
- Treating `"-7"` as an operator.

## Follow-ups

1. **Evaluate Reverse Polish Notation (LeetCode #150):** identical.
2. **Infix to postfix:** Dijkstra's shunting-yard algorithm (an operator stack plus precedence rules).
3. **Basic Calculator I/II (#224, #227):** evaluate infix directly with one or two stacks. Common at Google and Meta.
4. **Evaluate Expression Tree (easy 10):** RPN is the post-order traversal of the expression tree.

## What to remember

In postfix, an operator applies to the top two stack values; pop right first, then left.
