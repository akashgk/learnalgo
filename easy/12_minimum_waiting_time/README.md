# Minimum Waiting Time

**Difficulty:** Easy | **Category:** Greedy | **Pattern:** Sort then greedy (shortest job first)

## The problem

You have a list of positive integers: the durations of queries to run. Queries run one at a time, in any order you choose. A query's **waiting time** is how long it waits before it starts (the sum of the durations of all queries run before it). Return the minimum possible total waiting time.

```
queries = [3, 2, 1, 2, 6]  ->  17
best order: 1, 2, 2, 3, 6   waits: 0, 1, 3, 5, 8   total 17
```

### Clarifying questions

- Can I reorder or mutate the input? (Order is free. Mutating the list is allowed in the original problem; this solution copies it.)
- Are durations positive? (Yes.)

## Step 1: Work an example by hand

Try two orders for `[3, 2, 1, 2, 6]`:

- **Given order** 3, 2, 1, 2, 6: waits 0, 3, 5, 6, 8 = **22**.
- **Longest first** 6, 3, 2, 2, 1: waits 0, 6, 9, 11, 13 = **39**.
- **Shortest first** 1, 2, 2, 3, 6: waits 0, 1, 3, 5, 8 = **17**.

Shortest first looks best. But a hunch is not an answer; we need to understand why.

## Step 2: Brute force

Try all n! orders and compute each total. O(n! * n). Useless beyond n = 10, but it tells us the problem is "choose an ordering".

## Step 3: Count contributions instead of simulating

Look at who waits for whom. A query at position `i` (0-based) delays **every query after it**. There are `n - 1 - i` of those. So its duration is counted `n - 1 - i` times in the total:

```
total = sum over positions i of  duration[i] * (n - 1 - i)
```

For `1, 2, 2, 3, 6`: `1*4 + 2*3 + 2*2 + 3*1 + 6*0 = 4 + 6 + 4 + 3 + 0 = 17`.

Now the question is clear: we multiply durations by the weights `n-1, n-2, ..., 1, 0`. To minimize the sum, **give the largest weights to the smallest durations**: sort ascending.

### The proof: exchange argument

Suppose an order has a longer query `a` immediately before a shorter query `b` (`a > b`). Swap them:

- `b` now starts `a` time units earlier: total decreases by `a`.
- `a` now starts `b` time units later: total increases by `b`.
- Net change: `b - a < 0`. The total strictly decreases. Nobody else is affected.

So any order with an adjacent "long before short" pair can be improved. The only order with no such pair is sorted ascending, so it is optimal. This **exchange argument** is the standard way to prove a greedy rule. Learn to state it in two sentences.

## Step 4: The code

<!-- CODE:START -->

Full source: [`minimum_waiting_time.dart`](minimum_waiting_time.dart) (run it with `dart run`).

```dart
// Minimum Waiting Time
// Greedy: run shortest queries first. Each query's duration is waited on by every query after it.
// O(n log n) time, O(1) extra space (sorting a copy here).

int minimumWaitingTime(List<int> queries) {
  final sorted = [...queries]..sort();
  var total = 0;
  for (var i = 0; i < sorted.length; i++) {
    final queriesLeft = sorted.length - 1 - i;
    total += sorted[i] * queriesLeft;
  }
  return total;
}
```

<!-- CODE:END -->

### Walkthrough

- `[...queries]..sort()` copies and sorts ascending (shortest job first).
- `final queriesLeft = sorted.length - 1 - i;` is the number of queries that wait on query `i`.
- `total += sorted[i] * queriesLeft;` adds its contribution. No simulation, no running clock.

## Step 5: Dry run

Sorted: `[1, 2, 2, 3, 6]`, n = 5:

| i | duration | queriesLeft | contribution | total |
|---|---|---|---|---|
| 0 | 1 | 4 | 4 | 4 |
| 1 | 2 | 3 | 6 | 10 |
| 2 | 2 | 2 | 4 | 14 |
| 3 | 3 | 1 | 3 | 17 |
| 4 | 6 | 0 | 0 | 17 |

## Complexity

- **Time: O(n log n)** for the sort; the loop is O(n).
- **Space: O(1)** extra with in-place sorting (O(n) here because of the copy).

## Common mistakes

- Including the query's own duration in its waiting time. Waiting time ends when the query **starts**.
- Simulating with a running clock and getting off-by-one errors. Counting contributions avoids them.

## Follow-ups

1. **Minimize the average completion time** (wait + own duration): same ordering (Shortest Processing Time rule from scheduling theory).
2. **Weighted waiting time** (each query has a priority weight): sort by `duration / weight` (Smith's rule). The exchange argument proves it the same way.
3. **Multiple servers running in parallel:** assign in shortest-first order round robin.

## What to remember

For greedy problems, (1) rewrite the cost as a sum of contributions, (2) guess the ordering, (3) prove it with an exchange argument on an adjacent pair.
