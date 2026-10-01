# Maximum Profit in Job Scheduling

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** Weighted interval scheduling (sort by end + binary search) | **Source:** LeetCode 1235; Grind 75

## The problem

Each job has `startTime`, `endTime` and `profit`. Choose jobs with no overlap (a job ending at `t` and one starting at `t` are compatible) to maximize the total profit.

```
start  = [1, 2, 3, 3]
end    = [3, 4, 5, 6]
profit = [50, 10, 40, 70]   ->  120   (jobs [1,3] and [3,6])
```

## Step 1: Why greedy fails

Without weights, "earliest end first" is optimal (more_problems 45 Non-overlapping Intervals). With weights it is not: a short job that ends early may block one very profitable job. We must compare "take this job" against "skip it" in general: **DP**.

## Step 2: The DP

Sort jobs by **end time**. Let `dp[i]` be the best profit using only the first `i` jobs (in end order). For job `i - 1`:

- **skip it:** `dp[i - 1]`;
- **take it:** its profit plus the best profit among jobs that **end by its start time**. Since jobs are sorted by end, those form a prefix: the first `k` jobs, where `k` is the number of jobs ending at or before this job's start. Gain: `dp[k] + profit`.

```
dp[i] = max(dp[i - 1], dp[k] + profit[i - 1])
```

Why is `dp[k]` the right thing to add? Every job in the first `k` ends by the start of the current job, so any compatible set among them stays compatible with it. Jobs after position `k` (in end order) end after the current job starts, so they overlap it.

## Step 3: Finding k fast

End times are sorted, so `k` is "how many ends are `<= start`": a binary search, O(log n). Total O(n log n).

## Step 4: The code

<!-- CODE:START -->

Full source: [`maximum_profit_in_job_scheduling.dart`](maximum_profit_in_job_scheduling.dart) (run it with `dart run`).

```dart
// Maximum Profit in Job Scheduling (weighted interval scheduling): jobs [start, end, profit];
// choose non-overlapping jobs (a job ending at t is compatible with one starting at t) to maximize
// total profit. Sort by end time; dp[i] = best using the first i jobs = max(skip job i-1, take it +
// dp[last compatible]). The compatible prefix is found by binary search. O(n log n) time, O(n) space.

int jobScheduling(List<int> startTime, List<int> endTime, List<int> profit) {
  final n = startTime.length;
  final jobs = [for (var i = 0; i < n; i++) (startTime[i], endTime[i], profit[i])]
    ..sort((a, b) => a.$2.compareTo(b.$2));
  final dp = List<int>.filled(n + 1, 0); // dp[i]: best profit using jobs[0..i)
  for (var i = 1; i <= n; i++) {
    final (start, _, gain) = jobs[i - 1];
    // k = number of jobs (in end order) that end at or before this job's start.
    final k = _countEndingBy(jobs, i - 1, start);
    final take = dp[k] + gain;
    dp[i] = take > dp[i - 1] ? take : dp[i - 1];
  }
  return dp[n];
}

/// Number of jobs among jobs[0..limit) whose end time is <= t (ends are sorted).
int _countEndingBy(List<(int, int, int)> jobs, int limit, int t) {
  var lo = 0, hi = limit; // first index in [0, limit) with end > t
  while (lo < hi) {
    final mid = lo + (hi - lo) ~/ 2;
    if (jobs[mid].$2 <= t) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo;
}
```

<!-- CODE:END -->

### Walkthrough

- `jobs` are records `(start, end, profit)` sorted by end.
- `_countEndingBy` searches only the jobs before the current one (`limit = i - 1`). Jobs after it in end order end no earlier than it does, which is after its start, so they could never be counted anyway; the limit just keeps the search tidy.
- `dp` has `n + 1` entries; `dp[0] = 0`.

## Step 5: Dry run

`start [1,2,3,4,6]`, `end [3,5,10,6,9]`, `profit [20,20,100,70,60]`. Sorted by end:

| i | job (start, end, profit) | k (jobs ending <= start) | take = dp[k] + profit | skip = dp[i-1] | dp[i] |
|---|---|---|---|---|---|
| 1 | (1, 3, 20) | 0 | 20 | 0 | 20 |
| 2 | (2, 5, 20) | 0 | 20 | 20 | 20 |
| 3 | (4, 6, 70) | 1 | 20 + 70 = 90 | 20 | 90 |
| 4 | (6, 9, 60) | 3 | 90 + 60 = 150 | 90 | 150 |
| 5 | (3, 10, 100) | 1 | 20 + 100 = 120 | 150 | **150** |

Best: jobs (1, 3), (4, 6), (6, 9) for 150.

## Complexity

- Time: **O(n log n)**: sorting plus a binary search per job.
- Space: **O(n)**.

## Edge cases

- One job: its profit.
- All jobs overlapping: the single most profitable job.
- Touching jobs (end == next start): compatible, handled by `<=`.

## Common mistakes

- Sorting by start time with this recurrence (the "compatible prefix" argument needs end order).
- Using `<` instead of `<=` for compatibility.
- Linear search for k (O(n^2)).

## Follow-ups you should be ready for

1. **Return the chosen jobs.** Backtrack through `dp`: if `dp[i] != dp[i - 1]`, job `i - 1` was taken; jump to its `k`.
2. **Unweighted version.** Greedy by end time; more_problems 45.
3. **Maximum Earnings From Taxi (LeetCode 2008), Two Best Non-Overlapping Events (LeetCode 2054).** The same DP with small changes.

## What to remember

Weighted interval scheduling: sort by end, `dp[i] = max(skip, profit + dp[last compatible prefix])`, and find that prefix with binary search.
