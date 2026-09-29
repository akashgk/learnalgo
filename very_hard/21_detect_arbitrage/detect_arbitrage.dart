// Detect Arbitrage: exchangeRates[i][j] = units of currency j per unit of i.
// An arbitrage is a cycle with product of rates > 1, i.e. a negative cycle with weights -log(rate).
// Bellman-Ford. O(n^3) time (complete graph), O(n) space.

import 'dart:math';

bool detectArbitrage(List<List<double>> exchangeRates) {
  final n = exchangeRates.length;
  final w = [
    for (final row in exchangeRates) [for (final r in row) -log(r)],
  ];
  final dist = List<double>.filled(n, double.infinity)..[0] = 0;
  bool relaxAll() {
    var changed = false;
    for (var u = 0; u < n; u++) {
      for (var v = 0; v < n; v++) {
        if (dist[u] + w[u][v] < dist[v] - 1e-12) {
          dist[v] = dist[u] + w[u][v];
          changed = true;
        }
      }
    }
    return changed;
  }

  for (var i = 0; i < n - 1; i++) {
    if (!relaxAll()) return false; // converged early: no negative cycle
  }
  return relaxAll(); // still improving after n - 1 rounds => negative cycle
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    detectArbitrage([
      [1.0, 0.8631, 0.5903],
      [1.1586, 1.0, 0.6849],
      [1.6939, 1.46, 1.0],
    ]),
    true,
  );
  check(
    detectArbitrage([
      [1.0, 2.0],
      [0.5, 1.0],
    ]),
    false,
  );
}
