// Cheapest Flights Within K Stops: cheapest price from src to dst using at most k stops
// (at most k + 1 flights), or -1. Bellman-Ford limited to k + 1 rounds, relaxing from a
// snapshot of the previous round so a round never chains two flights. O(k * E) time, O(n) space.

int findCheapestPrice(int n, List<List<int>> flights, int src, int dst, int k) {
  const inf = 1 << 60;
  var cost = List<int>.filled(n, inf);
  cost[src] = 0;
  for (var round = 0; round <= k; round++) {
    // After round r, cost[v] = cheapest price using at most r + 1 flights.
    final next = [...cost];
    for (final f in flights) {
      final (from, to, price) = (f[0], f[1], f[2]);
      if (cost[from] != inf && cost[from] + price < next[to]) next[to] = cost[from] + price;
    }
    cost = next;
  }
  return cost[dst] == inf ? -1 : cost[dst];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final flights = [
    [0, 1, 100],
    [1, 2, 100],
    [2, 0, 100],
    [1, 3, 600],
    [2, 3, 200],
  ];
  check(findCheapestPrice(4, flights, 0, 3, 1), 700); // 0 -> 1 -> 3; 0 -> 1 -> 2 -> 3 needs 2 stops
  check(findCheapestPrice(4, flights, 0, 3, 2), 400);
  final tri = [
    [0, 1, 100],
    [1, 2, 100],
    [0, 2, 500],
  ];
  check(findCheapestPrice(3, tri, 0, 2, 1), 200);
  check(findCheapestPrice(3, tri, 0, 2, 0), 500);
  check(
    findCheapestPrice(
      3,
      [
        [0, 1, 1],
      ],
      0,
      2,
      5,
    ),
    -1,
  );
}
