// Burst Balloons: bursting balloon i earns left * nums[i] * right, where left/right are its current
// neighbors (1 beyond the ends). Maximize total coins.
// Interval DP on the LAST balloon burst in each open interval. O(n^3) time, O(n^2) space.

int maxCoins(List<int> nums) {
  final a = [1, ...nums, 1]; // padding: the boundaries act as balloons worth 1 that are never burst
  final n = a.length;
  // dp[l][r] = best coins from bursting every balloon strictly between l and r.
  final dp = List.generate(n, (_) => List<int>.filled(n, 0));
  for (var len = 2; len < n; len++) {
    for (var l = 0; l + len < n; l++) {
      final r = l + len;
      for (var k = l + 1; k < r; k++) {
        // k is burst last in (l, r): at that moment its neighbors are exactly l and r.
        final coins = dp[l][k] + a[l] * a[k] * a[r] + dp[k][r];
        if (coins > dp[l][r]) dp[l][r] = coins;
      }
    }
  }
  return dp[0][n - 1];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(maxCoins([3, 1, 5, 8]), 167);
  check(maxCoins([1, 5]), 10);
  check(maxCoins([7]), 7);
  check(maxCoins([]), 0);
}
