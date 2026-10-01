# Basic Calculator

**Difficulty:** Hard | **Category:** Stacks | **Pattern:** Running sum + sign, stack saves the outer context at `(` | **Source:** LeetCode 224; Grind 75

## The problem

Evaluate a valid expression containing non-negative integers, `+`, `-`, parentheses and spaces. `-` can also be **unary** (`"-(2 + 3)"`, `"1 - (-2)"`). No `*` or `/`. Do not use `eval`.

```
"1 + 1"                ->  2
"(1+(4+5+2)-3)+(6+8)"  ->  23
"-(2 + 3)"             ->  -5
```

## Step 1: Without parentheses

With only `+` and `-`, the value is a sum of signed numbers: `1 - 2 + 3 = (+1) + (-2) + (+3)`. Scan left to right with:

- `result`: the sum so far,
- `sign`: the sign for the next number (+1 or -1), set by the most recent operator.

When a number is read, `result += sign * number`. A unary minus at the start works the same way: it just sets `sign = -1`.

## Step 2: Parentheses

A parenthesized group is a sub-expression with its own running sum, and the group as a whole is multiplied by the sign in front of it. When `(` opens:

- **save** the outer `result` and the `sign` in front of the parenthesis on a stack;
- start a fresh `result = 0`, `sign = 1` for the inside.

When `)` closes:

- the inner `result` is the group's value;
- restore: `result = savedResult + savedSign * innerResult`.

Nested parentheses push more saved contexts; the stack unwinds them in order.

## Step 3: Alternative

Treat every number's sign as the product of all enclosing signs: keep a stack of "current sign multipliers" and push `sign * top` at each `(`. Same complexity; the save/restore version is easier to explain.

## Step 4: The code

<!-- CODE:START -->

Full source: [`basic_calculator.dart`](basic_calculator.dart) (run it with `dart run`).

```dart
// Basic Calculator (LeetCode 224): evaluate an expression with non-negative integers, '+', '-',
// parentheses, unary minus (e.g. "-(2 + 3)"), and spaces. No multiplication or division.
// One pass with a running result, the current sign, and a stack that saves (result, sign) when a
// parenthesis opens. O(n) time, O(n) space for nested parentheses.

int calculate(String s) {
  var result = 0; // value of the current parenthesis level so far
  var sign = 1; // sign to apply to the next number at this level
  final stack = <int>[]; // saved [result, sign] pairs, flattened
  var i = 0;
  while (i < s.length) {
    final ch = s[i];
    if (ch == ' ') {
      i++;
    } else if (_isDigit(ch)) {
      var number = 0;
      while (i < s.length && _isDigit(s[i])) {
        number = number * 10 + s.codeUnitAt(i) - 48;
        i++;
      }
      result += sign * number;
    } else if (ch == '+' || ch == '-') {
      sign = ch == '+' ? 1 : -1;
      i++;
    } else if (ch == '(') {
      // Save the outer level; the inner expression starts from scratch.
      stack
        ..add(result)
        ..add(sign);
      result = 0;
      sign = 1;
      i++;
    } else {
      // ')': inner value times the sign that preceded '(', added to the saved outer result.
      final outerSign = stack.removeLast(), outerResult = stack.removeLast();
      result = outerResult + outerSign * result;
      i++;
    }
  }
  return result;
}

bool _isDigit(String ch) => ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;
```

<!-- CODE:END -->

### Walkthrough

- Multi-digit numbers are read in an inner loop.
- The stack stores pairs flattened: push `result`, then `sign`; pop `sign` first, then `result`.
- After `)`, the `sign` variable is left as is; the next operator will overwrite it before the next number is read.

## Step 5: Dry run

`"(1+(4+5+2)-3)+(6+8)"`:

| token | action | result | sign | stack |
|---|---|---|---|---|
| ( | save (0, +) | 0 | + | [0, +] |
| 1 | add | 1 | + | |
| + ( | save (1, +) | 0 | + | [0, +, 1, +] |
| 4 + 5 + 2 | add | 11 | + | |
| ) | 1 + (+1) * 11 | 12 | | [0, +] |
| - 3 | add -3 | 9 | - | |
| ) | 0 + (+1) * 9 | 9 | | [] |
| + ( | save (9, +) | 0 | + | [9, +] |
| 6 + 8 | add | 14 | | |
| ) | 9 + 14 | **23** | | [] |

## Complexity

- Time: **O(n)**.
- Space: **O(n)** for deeply nested parentheses.

## Edge cases

- Leading unary minus: `"-(2+3)"`.
- Unary minus inside parentheses: `"1-(     -2)"`.
- Large values up to 2^31 - 1.

## Common mistakes

- Reading only single-digit numbers.
- Forgetting to reset `result` and `sign` after `(`.
- Restoring in the wrong order from the flattened stack.

## Follow-ups you should be ready for

1. **Basic Calculator II (LeetCode 227).** `*` and `/` without parentheses: apply them immediately to the last pushed term, push `+`/`-` terms, sum at the end.
2. **Basic Calculator III (LeetCode 772).** Everything: recursion on parentheses plus the II approach, or the shunting-yard algorithm.
3. **Evaluate Reverse Polish Notation.** Already postfix: one stack; AlgoExpert medium 65.

## What to remember

`+`/`-` expressions are a running sum of signed numbers. A parenthesis saves (outer sum, sign before it) and starts a fresh sum; closing combines them.
