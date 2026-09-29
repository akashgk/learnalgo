# Maximize Expression

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** Chained running maxima (a small state machine)

## The problem

Given an array of integers, return the maximum value of

```
array[a] - array[b] + array[c] - array[d]      with indices  a < b < c < d
```

If the array has fewer than 4 elements, return 0.

```
[3, 6, 1, -3, 2, 7]  ->  4       (6 - (-3) + 2 - 7)
```

## Step 1: Brute force

Four nested loops: **O(n^4)**.

## Step 2: Build the expression one term at a time

Think of choosing `a`, then `b`, then `c`, then `d`, left to right. For each prefix of the array, keep the best value of each **partial** expression:

| stage | best over indices up to i of | meaning |
|---|---|---|
| A[i] | `array[a]` | best first term |
| AB[i] | `array[a] - array[b]` | best first two terms |
| ABC[i] | `array[a] - array[b] + array[c]` | best first three terms |
| ABCD[i] | the full expression | the answer at the end |

Each stage extends the previous stage from **strictly earlier** indices:

```
A[i]    = max(A[i-1],    array[i])
AB[i]   = max(AB[i-1],   A[i-1]   - array[i])
ABC[i]  = max(ABC[i-1],  AB[i-1]  + array[i])
ABCD[i] = max(ABCD[i-1], ABC[i-1] - array[i])
```

Using stage `k - 1` at index `i - 1` is what enforces `a < b < c < d`.

## Step 3: The code

<!-- CODE:START -->

Full source: [`maximize_expression.dart`](maximize_expression.dart) (run it with `dart run`).

```dart
// Maximize Expression: max of a - b + c - d with indices a < b < c < d (0 if fewer than 4).
// Four running-max passes; each builds on the previous term. O(n) time, O(n) space.

int maximizeExpression(List<int> array) {
  if (array.length < 4) return 0;
  const negInf = -(1 << 62);
  final n = array.length;
  final a = List<int>.filled(n, negInf); // best A up to i
  final ab = List<int>.filled(n, negInf); // best A - B up to i
  final abc = List<int>.filled(n, negInf); // best A - B + C up to i
  final abcd = List<int>.filled(n, negInf); // best A - B + C - D up to i
  int max(int x, int y) => x > y ? x : y;
  for (var i = 0; i < n; i++) {
    final v = array[i];
    a[i] = max(i > 0 ? a[i - 1] : negInf, v);
    if (i >= 1) ab[i] = max(i > 1 ? ab[i - 1] : negInf, a[i - 1] - v);
    if (i >= 2) abc[i] = max(i > 2 ? abc[i - 1] : negInf, ab[i - 1] + v);
    if (i >= 3) abcd[i] = max(i > 3 ? abcd[i - 1] : negInf, abc[i - 1] - v);
  }
  return abcd[n - 1];
}
```

<!-- CODE:END -->

### Walkthrough

- `negInf` marks "not yet possible" (for example AB at index 0: there is no `a < b = 0`).
- Each stage is filled only from the index where it becomes possible (`i >= 1` for AB, and so on).
- The answer is `abcd[n - 1]`.

## Step 4: Dry run

| i | value | A | AB | ABC | ABCD |
|---|---|---|---|---|---|
| 0 | 3 | 3 | | | |
| 1 | 6 | 6 | 3 - 6 = -3 | | |
| 2 | 1 | 6 | max(-3, 6 - 1) = 5 | -3 + 1 = -2 | |
| 3 | -3 | 6 | max(5, 6 + 3) = 9 | max(-2, 5 - 3) = 2 | -2 + 3 = 1 |
| 4 | 2 | 6 | max(9, 6 - 2) = 9 | max(2, 9 + 2) = 11 | max(1, 2 - 2) = 1 |
| 5 | 7 | 7 | max(9, 6 - 7) = 9 | max(11, 9 + 7) = 16 | max(1, 11 - 7) = **4** |

Answer: 4.

## Complexity

- **Time: O(n)**.
- **Space: O(n)** with four arrays; **O(1)** with four variables (update them from the last stage to the first within each iteration, so each uses the previous index's values).

## Common mistakes

- Using stage `k - 1` at the **same** index (allows `a == b`).
- Initializing stages with 0 instead of negative infinity (0 might beat real, negative expression values).

## Follow-ups

1. **Best Time to Buy and Sell Stock III (LeetCode #123):** at most two transactions. Its states `buy1, sell1, buy2, sell2` track the best `-p1`, `-p1 + p2`, `-p1 + p2 - p3`, `-p1 + p2 - p3 + p4` over increasing days: the same chained-maxima structure with the opposite sign pattern.
2. **Maximum Product of Three Numbers**, **Maximum Score from Multiplication Operations:** other "pick k indices in order" problems.

## What to remember

For "pick indices in increasing order to maximize a fixed-shape expression", keep the best partial expression for each stage and extend stage by stage from earlier indices.
