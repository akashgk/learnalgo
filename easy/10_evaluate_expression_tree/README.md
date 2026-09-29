# Evaluate Expression Tree

**Difficulty:** Easy | **Category:** Binary Trees | **Pattern:** Post-order (bottom-up) recursion

## The problem

A binary expression tree stores non-negative integers at the leaves and operators at the internal nodes. Operators are encoded as negative numbers:

| value | operator |
|---|---|
| -1 | addition `+` |
| -2 | subtraction `-` |
| -3 | division `/`, rounded toward zero |
| -4 | multiplication `*` |

Every operator node has exactly two children. Return the value of the expression.

```
              -4 (*)
           /         \
        -1 (+)       -4 (*)
       /     \       /    \
    -2 (-)  -3 (/)  2      3
    /  \    /  \
   2    3  8    3

= ((2 - 3) + (8 / 3)) * (2 * 3)
= (-1 + 2) * 6
= 6
```

### Clarifying questions

- Division by zero? (Assume it does not happen.)
- How does division round? (Toward zero: `-7 / 2 = -3`, not -4. This matters in some languages.)

## Step 1: Work an example by hand

To compute the root (`*`) you need the values of both of its children first. To compute the `+` node you need `2 - 3` and `8 / 3` first. You always evaluate **children before parents**.

That order has a name: **post-order** traversal (left, right, then the node). It is the natural order whenever a node's answer is computed from its children's answers.

## Step 2: Recursive definition

```
evaluate(node):
    if node is a leaf (value >= 0): return node.value
    l = evaluate(node.left)
    r = evaluate(node.right)
    return apply(node.value, l, r)
```

That is the whole algorithm. The base case is the leaf; the recursive case combines two sub-results.

## Step 3: The code

<!-- CODE:START -->

Full source: [`evaluate_expression_tree.dart`](evaluate_expression_tree.dart) (run it with `dart run`).

```dart
// Evaluate Expression Tree
// Leaves are non-negative operands; internal nodes are operators:
// -1 add, -2 subtract, -3 divide (truncate toward zero), -4 multiply.
// Postorder evaluation. O(n) time, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

int evaluateExpressionTree(BinaryTree tree) {
  if (tree.value >= 0) return tree.value;
  final l = evaluateExpressionTree(tree.left!);
  final r = evaluateExpressionTree(tree.right!);
  return switch (tree.value) {
    -1 => l + r,
    -2 => l - r,
    -3 => l ~/ r, // ~/ truncates toward zero, as required
    -4 => l * r,
    _ => throw ArgumentError('unknown operator ${tree.value}'),
  };
}
```

<!-- CODE:END -->

### Walkthrough

- `if (tree.value >= 0) return tree.value;` is the base case. Non-negative values are leaves.
- `evaluate...(tree.left!)` uses `!` because an operator node always has two children. If the input could be malformed, you would validate instead.
- `return switch (tree.value) { ... }` is a Dart 3 switch expression: each operator code maps to a result, and `_ => throw ...` handles unknown codes. The compiler forces you to think about the default case.
- `l ~/ r` is Dart's integer division, which truncates toward zero, exactly what the problem requires. (Python's `//` floors instead: `-7 // 2 == -4`. That is a classic cross-language trap.)

## Step 4: Dry run

Evaluation order (post-order):

| node | left value | right value | result |
|---|---|---|---|
| leaf 2 | | | 2 |
| leaf 3 | | | 3 |
| -2 (-) | 2 | 3 | -1 |
| leaf 8 | | | 8 |
| leaf 3 | | | 3 |
| -3 (/) | 8 | 3 | 2 |
| -1 (+) | -1 | 2 | 1 |
| leaf 2, leaf 3 | | | 2, 3 |
| -4 (*) right | 2 | 3 | 6 |
| -4 (*) root | 1 | 6 | **6** |

## Complexity

- **Time: O(n)**: each node is evaluated once.
- **Space: O(h)** for the recursion stack.

## Edge cases

- A single leaf: its value.
- Division producing a negative result: `(0 - 7) / 2 = -3` with truncation toward zero (tested in the code).

## Common mistakes

- Evaluating the operator before the children (pre-order thinking).
- Using floating-point division and rounding afterward: `-3.5` rounds to `-4` with `round()` or `floor()`, not `-3`.
- Swapping operand order for `-` and `/`. The **left** child is the first operand.

## Follow-ups

1. **Reverse Polish Notation (medium 65):** the same expression written in post-order as a token list, evaluated with a stack instead of recursion.
2. **Build the tree from an infix string** (`"(2-3)+8/3"`): use the shunting-yard algorithm or recursive descent parsing. Common at Google.
3. **Print the expression with minimal parentheses:** in-order traversal plus operator precedence rules.

## What to remember

If a node's answer depends on its children's answers, compute the children first: post-order, bottom-up recursion.
