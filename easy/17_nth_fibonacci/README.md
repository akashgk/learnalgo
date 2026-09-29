# Nth Fibonacci

**Difficulty:** Easy | **Category:** Recursion | **Pattern:** Recursion -> memoization -> bottom-up DP

## Problem
Return the nth Fibonacci number, where the sequence is 1-indexed: F(1) = 0, F(2) = 1, and F(n) = F(n-1) + F(n-2).

## Building up the logic
This problem exists to teach the standard progression you will apply to every DP problem:
1. **Naive recursion** straight from the definition. Time O(2^n) (more precisely O(phi^n)) because the call tree recomputes the same subproblems repeatedly. Draw the call tree for n = 6 and point at the repeated F(3) calls.
2. **Memoization (top-down DP):** cache each F(k) the first time you compute it. Every subproblem is solved once: O(n) time, O(n) space (cache + stack).
3. **Tabulation (bottom-up DP):** compute F(3), F(4), ... in order. Still O(n) space if you keep the whole table.
4. **Space optimization:** each value depends only on the previous two, so keep two variables. O(n) time, O(1) space.

## Complexity
| Approach | Time | Space |
|---|---|---|
| Naive recursion | O(2^n) | O(n) stack |
| Memoization | O(n) | O(n) |
| Iterative, two variables | O(n) | O(1) |
| Matrix exponentiation | O(log n) | O(1) |

## Interview notes
- Mention matrix exponentiation (`[[1,1],[1,0]]^n`) as the O(log n) follow-up. You rarely need to code it, but knowing it signals depth.
- Overflow: in this problem's 1-indexed sequence, the 94th term (12,200,160,415,121,876,738) is the first to exceed signed 64-bit. Dart native `int` is 64-bit and wraps silently; use `BigInt` for large n.
- Dart note: `(prev, curr) = (curr, prev + curr)` is a record swap, no temporary variable needed.
