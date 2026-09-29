// Optimal Assembly Line: split stepDurations into numStations contiguous groups minimizing the
// maximum group sum. Binary search on the answer with a greedy feasibility check.
// O(n log S) time (S = sum of durations), O(1) space.

int optimalAssemblyLine(List<int> stepDurations, int numStations) {
  var lo = stepDurations.reduce((a, b) => a > b ? a : b); // a station must fit the biggest step
  var hi = stepDurations.reduce((a, b) => a + b); // one station does everything

  bool feasible(int maxTime) {
    var stations = 1, current = 0;
    for (final d in stepDurations) {
      if (current + d > maxTime) {
        stations++;
        current = 0;
      }
      current += d;
    }
    return stations <= numStations;
  }

  while (lo < hi) {
    final mid = lo + (hi - lo) ~/ 2;
    if (feasible(mid)) {
      hi = mid; // mid works; try smaller
    } else {
      lo = mid + 1;
    }
  }
  return lo;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(optimalAssemblyLine([15, 15, 30, 30, 45], 3), 60); // [15,15,30] [30] [45]
  check(optimalAssemblyLine([7, 2, 5, 10, 8], 2), 18);
  check(optimalAssemblyLine([1, 2, 3], 5), 3);
}
