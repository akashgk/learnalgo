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

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(jobScheduling([1, 2, 3, 3], [3, 4, 5, 6], [50, 10, 40, 70]), 120); // jobs 1 and 4
  check(jobScheduling([1, 2, 3, 4, 6], [3, 5, 10, 6, 9], [20, 20, 100, 70, 60]), 150); // 1, 4, 5
  check(jobScheduling([1, 1, 1], [2, 3, 4], [5, 6, 4]), 6);
  check(jobScheduling([1], [2], [9]), 9);
}
