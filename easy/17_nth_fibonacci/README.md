# Nth Fibonacci

**Difficulty:** Easy | **Category:** Recursion | **Pattern:** Recursion -> memoization -> bottom-up DP -> constant space

## The problem

The Fibonacci sequence is defined by: each number is the sum of the previous two. In this problem it is **1-indexed** with F(1) = 0 and F(2) = 1. Return F(n).

```
n:    1  2  3  4  5  6  7   8
F(n): 0  1  1  2  3  5  8  13
```

## Why this problem matters

Fibonacci is the smallest problem that shows the **four-stage progression** you will use for every dynamic programming problem in this repo:

1. write the plain recursion,
2. notice repeated subproblems and cache them (memoization, top-down DP),
3. fill a table in order instead (tabulation, bottom-up DP),
4. keep only the table entries you still need (space optimization).

## Stage 1: Plain recursion

Translate the definition literally:

```dart
int fib(int n) => n == 1 ? 0 : n == 2 ? 1 : fib(n - 1) + fib(n - 2);
```

Draw the call tree for `fib(6)`:

```
                    fib(6)
               /             \
          fib(5)             fib(4)
         /      \           /     \
     fib(4)    fib(3)    fib(3)   fib(2)
     /   \     /   \     /   \
 fib(3) fib(2) ...  ...  ...  ...
```

`fib(4)` is computed twice, `fib(3)` three times, and it gets worse exponentially: each call spawns two more. The number of calls grows like 1.618^n (the golden ratio). **Time O(2^n)** is the usual loose bound; space is O(n) for the deepest chain of calls.

**Duplicated work** is the bottleneck. The same `fib(k)` is solved over and over.

## Stage 2: Memoization (top-down DP)

Cache each answer the first time you compute it. The next call for the same `k` is an O(1) lookup.

```dart
int fibMemo(int n, Map<int, int> memo) =>
    memo[n] ??= fibMemo(n - 1, memo) + fibMemo(n - 2, memo);   // memo starts as {1: 0, 2: 1}
```

Now each `k` from 1 to n is computed once: **O(n) time, O(n) space** (the map plus the recursion stack).

## Stage 3: Tabulation (bottom-up DP)

Memoization computes subproblems in whatever order the recursion reaches them. Since we know `fib(k)` only needs smaller values, just compute them **in increasing order**:

```
table[1] = 0, table[2] = 1
for k in 3..n: table[k] = table[k-1] + table[k-2]
```

Still O(n) time and O(n) space, but no recursion, so no stack overflow risk for large n.

## Stage 4: Constant space

`table[k]` only reads the two previous entries. Everything older is dead weight. Keep two variables and slide them forward: **O(n) time, O(1) space.**

## The code

<!-- CODE:START -->

Full source: [`nth_fibonacci.dart`](nth_fibonacci.dart) (run it with `dart run`).

```dart
// Nth Fibonacci (1-indexed: F(1) = 0, F(2) = 1).
// Iterative with two variables: O(n) time, O(1) space.

int getNthFib(int n) {
  if (n == 1) return 0;
  var (prev, curr) = (0, 1);
  for (var i = 3; i <= n; i++) {
    (prev, curr) = (curr, prev + curr);
  }
  return curr;
}

/// Memoized recursion, shown for comparison: O(n) time, O(n) space.
int getNthFibMemo(int n, [Map<int, int>? memo]) {
  memo ??= {1: 0, 2: 1};
  return memo[n] ??= getNthFibMemo(n - 1, memo) + getNthFibMemo(n - 2, memo);
}
```

<!-- CODE:END -->

### Walkthrough of `getNthFib`

- `if (n == 1) return 0;` handles the first base case. The loop below starts from F(2).
- `var (prev, curr) = (0, 1);` starts with F(1) and F(2) as a Dart record.
- Each iteration computes the next term: `(prev, curr) = (curr, prev + curr);`. The right-hand side is evaluated completely before assigning, so no temporary variable is needed.
- After the loop for `i = 3..n`, `curr` holds F(n).

### Walkthrough of `getNthFibMemo`

- `memo ??= {1: 0, 2: 1};` creates the cache with the base cases on the first call only.
- `memo[n] ??= ...` returns the cached value if present; otherwise computes it, stores it, and returns it.

## Dry run of `getNthFib(6)`

| i | prev | curr (= F(i)) |
|---|---|---|
| start | 0 | 1 (F(2)) |
| 3 | 1 | 1 |
| 4 | 1 | 2 |
| 5 | 2 | 3 |
| 6 | 3 | 5 |

Return 5.

## Complexity summary

| Approach | Time | Space |
|---|---|---|
| Plain recursion | O(2^n) (more precisely about O(1.618^n)) | O(n) stack |
| Memoization | O(n) | O(n) |
| Tabulation | O(n) | O(n) |
| Two variables | O(n) | O(1) |
| Matrix exponentiation | O(log n) | O(1) |

The O(log n) method raises the matrix `[[1, 1], [1, 0]]` to a power using repeated squaring. You rarely need to code it, but mentioning it shows depth.

## Common mistakes

- Off-by-one on the indexing: this problem's F(1) is 0, many other sources use F(0) = 0 and F(1) = 1. Always confirm the definition.
- Forgetting that memoization still recurses n levels deep, which can overflow the stack for very large n.
- Overflow: in this problem's 1-indexed sequence, the 94th term (12,200,160,415,121,876,738) is the first to exceed signed 64-bit. Dart native `int` wraps silently past that point; use `BigInt` if large n is possible.

## Follow-ups

1. **Climbing Stairs (LeetCode #70):** ways to climb n stairs taking 1 or 2 steps. It is Fibonacci in disguise; see Staircase Traversal (medium 54) for the general version.
2. **Tribonacci / k-bonacci:** keep the last k values (a sliding window sum).
3. **Why not recursion with memoization everywhere?** Bottom-up avoids recursion limits and makes the space optimization obvious. Top-down is easier to write when the subproblem order is not obvious.

## What to remember

Recursion with repeated subproblems -> cache them. Then compute in dependency order. Then keep only what the next step needs. Say these three steps out loud in every DP interview.
