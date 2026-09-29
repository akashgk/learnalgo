# Number Of Ways To Make Change

**Difficulty:** Medium | **Category:** Dynamic Programming | **Pattern:** Unbounded knapsack (counting combinations)

## The problem

Given a target amount `n` and a list of distinct positive coin denominations (unlimited supply of each), return the number of ways to make exactly `n`. The order of coins does not matter: `1 + 5` and `5 + 1` are the same way. There is exactly one way to make 0 (use no coins).

```
n = 6,  coins = [1, 5]          ->  2    (1+1+1+1+1+1, 1+5)
n = 10, coins = [1, 5, 10, 25]  ->  4    (ten 1s; five 1s + 5; 5 + 5; 10)
```

## Step 1: Work an example by hand

List the ways to make 10 with `[1, 5, 10, 25]`, organized by **how many of each coin** you use:

- using only 1s: 1 way;
- using 5s (and 1s): one 5 + five 1s, two 5s: 2 ways;
- using a 10: 1 way.

Total 4. Notice we listed each **combination** once by deciding coin types one at a time: "how many 1s, how many 5s, how many 10s". That ordering is what prevents counting `1 + 5` and `5 + 1` separately, and it is exactly how the DP will avoid double counting.

## Step 2: Brute force

Recursively, for each coin type, try using it 0, 1, 2, ... times, then move to the next coin type. Exponential without caching.

## Step 3: The DP

**Subproblem:** `ways[a]` = number of ways to make amount `a` using the coin types processed so far.

Process one coin type `c` at a time. With `c` now available, any way to make `a` either:

- uses no `c`: already counted in `ways[a]` from earlier coin types;
- uses at least one `c`: remove one `c`, and what remains is a way to make `a - c` (which may use more `c`s).

So: `ways[a] += ways[a - c]` for `a` from `c` up to `n`.

Iterating `a` **upward** is what allows multiple copies of `c`: when we read `ways[a - c]`, it has already been updated for coin `c` in this same pass.

Base case: `ways[0] = 1`.

### The loop order is the whole question

| Outer loop | Inner loop | Counts | Example for n = 6, coins [1, 5] |
|---|---|---|---|
| coins | amounts | **combinations** (this problem) | 2 |
| amounts | coins | **permutations** (order matters) | 3 (1+5, 5+1, six 1s) |

With coins in the outer loop, every combination is built in a fixed coin order (all 1s first, then 5s, ...), so it is counted once. With amounts outside, the last coin can be any type at every step, so different orders are counted separately (that is LeetCode #377, Combination Sum IV). Interviewers love asking why.

## Step 4: The code

<!-- CODE:START -->

Full source: [`number_of_ways_to_make_change.dart`](number_of_ways_to_make_change.dart) (run it with `dart run`).

```dart
// Number Of Ways To Make Change (unbounded coins, order does not matter).
// ways[a] += ways[a - coin], iterating coins in the OUTER loop to count combinations.
// O(n * d) time, O(n) space.

int numberOfWaysToMakeChange(int n, List<int> denoms) {
  final ways = List<int>.filled(n + 1, 0)..[0] = 1;
  for (final coin in denoms) {
    for (var amount = coin; amount <= n; amount++) {
      ways[amount] += ways[amount - coin];
    }
  }
  return ways[n];
}
```

<!-- CODE:END -->

### Walkthrough

- `List<int>.filled(n + 1, 0)..[0] = 1` creates the table with the base case.
- `for (final coin in denoms)` is the outer loop over coin types.
- `for (var amount = coin; amount <= n; amount++)` starts at `coin` (smaller amounts cannot use it).
- `ways[amount] += ways[amount - coin];` is the recurrence.

## Step 5: Dry run

n = 6, coins `[1, 5]`:

| after coin | ways[0..6] |
|---|---|
| (start) | 1 0 0 0 0 0 0 |
| 1 | 1 1 1 1 1 1 1 |
| 5 | 1 1 1 1 1 **2** **2** |

For coin 5: `ways[5] += ways[0]` (1 + 1 = 2), `ways[6] += ways[1]` (1 + 1 = 2). Answer: 2.

## Complexity

- **Time: O(n * d)**, d = number of denominations.
- **Space: O(n)**.

## Common mistakes

- Swapping the loops (counts permutations).
- Forgetting `ways[0] = 1`: everything stays 0.
- Iterating amounts **downward**: that allows each coin at most once (that is 0/1 knapsack counting, a different problem).

## Follow-ups

1. **Coin Change II (LeetCode #518):** identical.
2. **Min Number Of Coins For Change (medium 30):** the minimization version.
3. **Each coin usable once:** iterate amounts downward.
4. **Large counts:** answers overflow quickly; ask whether to return the result modulo 10^9 + 7.

## What to remember

Counting combinations: loop over item types outside, amounts inside, amounts ascending for unlimited supply. Swap the loops and you count permutations instead.
