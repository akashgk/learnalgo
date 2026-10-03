# Maps and Navigation: Low-Level Design

## 1. Scope for the LLD round

- **Tile coordinates:** latitude/longitude -> Web Mercator tile `(x, y)` at a zoom level.
- **Road graph:** intersections with coordinates; directed road segments with length, speed limit and a live **congestion factor**; one-way streets.
- **Shortest-time routing** with **Dijkstra** and **A\*** (heuristic: straight-line distance at the network's top speed, which never overestimates), sharing one implementation; both return the path, travel time and the number of nodes expanded.
- **Traffic** changes edge weights and therefore routes; **ETA** is the sum of segment times.
- **Rerouting** from the current position when the driver leaves the route.

Out of scope: contraction hierarchies, map matching, geocoding (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `tileFor` | Web Mercator tile math. |
| `Node`, `Edge` | Intersection with coordinates (km); directed segment with time cost. |
| `RoadGraph` | Nodes, adjacency lists, `addRoad`, `setCongestion`, top speed. |
| `MinHeap` | Binary heap of (priority, node) for the search frontier. |
| `Route` | Path, seconds, expanded-node count. |
| `findRoute` | Dijkstra (no heuristic) or A* (admissible heuristic). |
| `NavigationSession` | Current route; on an off-route position, reroutes. |

```text
RoadGraph: nodes{id -> (x, y)}, adj{id -> [Edge(to, km, kmh, congestion)]}
findRoute(graph, s, t, useAStar) -> MinHeap by g + h -> Route(path, seconds, expanded)
NavigationSession(route) --position not on route--> findRoute(position, destination)
```

## 3. Design decisions and why

- **Edge cost = travel time,** not distance: the fastest route is what drivers want, and traffic changes time, not length.
- **One search function, pluggable heuristic:** Dijkstra is A* with h = 0. This makes the comparison honest and the code smaller.
- **Admissible heuristic** (straight-line distance at the maximum speed in the graph): never overestimates, so A* still returns optimal routes.
- **Lazy deletion in the heap** (skip stale entries) instead of decrease-key: simpler, same asymptotics in practice.
- **Congestion as a multiplier on edge time:** traffic feeds update one number per segment; no graph rebuild.

## 4. The code

```dart
import 'dart:math';

(int, int) tileFor(double lat, double lng, int zoom) {
  final n = 1 << zoom;
  final x = ((lng + 180) / 360 * n).floor();
  final latRad = lat * pi / 180;
  final y = ((1 - log(tan(latRad) + 1 / cos(latRad)) / pi) / 2 * n).floor();
  return (x, y);
}

class Node {
  const Node(this.id, this.x, this.y);
  final int id;
  final double x; // km
  final double y; // km
}

class Edge {
  Edge(this.to, this.km, this.kmh);
  final int to;
  final double km;
  final double kmh;
  double congestion = 1.0; // 2.0 = takes twice as long
  double get seconds => km / kmh * 3600 * congestion;
}

class RoadGraph {
  final nodes = <int, Node>{};
  final adj = <int, List<Edge>>{};
  var topSpeedKmh = 1.0;

  void addNode(int id, double x, double y) => nodes[id] = Node(id, x, y);

  void addRoad(int a, int b, double kmh, {bool oneWay = false}) {
    final km = _km(a, b);
    adj.putIfAbsent(a, () => []).add(Edge(b, km, kmh));
    if (!oneWay) adj.putIfAbsent(b, () => []).add(Edge(a, km, kmh));
    topSpeedKmh = max(topSpeedKmh, kmh);
  }

  double _km(int a, int b) {
    final p = nodes[a]!, q = nodes[b]!;
    return sqrt(pow(p.x - q.x, 2) + pow(p.y - q.y, 2));
  }

  void setCongestion(int a, int b, double factor) {
    for (final e in adj[a] ?? const <Edge>[]) {
      if (e.to == b) e.congestion = factor;
    }
  }

  /// Lower bound on travel time from [a] to [b]: straight line at the top speed.
  double lowerBoundSeconds(int a, int b) => _km(a, b) / topSpeedKmh * 3600;
}

class MinHeap {
  final _items = <(double, int)>[];
  bool get isEmpty => _items.isEmpty;

  void _swap(int a, int b) {
    final t = _items[a];
    _items[a] = _items[b];
    _items[b] = t;
  }

  void push(double priority, int node) {
    _items.add((priority, node));
    var i = _items.length - 1;
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (_items[parent].$1 <= _items[i].$1) break;
      _swap(parent, i);
      i = parent;
    }
  }

  (double, int) pop() {
    final top = _items.first;
    final last = _items.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = last;
      var i = 0;
      while (true) {
        final l = 2 * i + 1, r = l + 1;
        var m = i;
        if (l < _items.length && _items[l].$1 < _items[m].$1) m = l;
        if (r < _items.length && _items[r].$1 < _items[m].$1) m = r;
        if (m == i) break;
        _swap(m, i);
        i = m;
      }
    }
    return top;
  }
}

class Route {
  const Route(this.path, this.seconds, this.expanded);
  final List<int> path;
  final double seconds;
  final int expanded;
}

Route? findRoute(RoadGraph g, int source, int target, {bool useAStar = true}) {
  double h(int n) => useAStar ? g.lowerBoundSeconds(n, target) : 0;
  final best = <int, double>{source: 0};
  final parent = <int, int>{};
  final done = <int>{};
  final heap = MinHeap()..push(h(source), source);
  var expanded = 0;
  while (!heap.isEmpty) {
    final (_, u) = heap.pop();
    if (!done.add(u)) continue; // stale heap entry
    expanded++;
    if (u == target) {
      final path = [target];
      while (path.first != source) {
        path.insert(0, parent[path.first]!);
      }
      return Route(path, best[target]!, expanded);
    }
    for (final e in g.adj[u] ?? const <Edge>[]) {
      final cost = best[u]! + e.seconds;
      if (cost < (best[e.to] ?? double.infinity)) {
        best[e.to] = cost;
        parent[e.to] = u;
        heap.push(cost + h(e.to), e.to);
      }
    }
  }
  return null;
}

class NavigationSession {
  NavigationSession(this.graph, this.destination, int start) : route = findRoute(graph, start, destination)!;
  final RoadGraph graph;
  final int destination;
  Route route;
  var reroutes = 0;

  /// Called with map-matched positions; reroutes when the driver is not on the planned path.
  void onPosition(int node) {
    if (route.path.contains(node)) return;
    route = findRoute(graph, node, destination)!;
    reroutes++;
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void main() {
  // Tiles.
  check([tileFor(37.7749, -122.4194, 10), tileFor(37.7749, -122.4194, 0)], [(163, 395), (0, 0)]);

  // A small network: direct streets A-B-C vs a faster highway detour A-D-C.
  final g = RoadGraph()
    ..addNode(0, 0, 0) // A
    ..addNode(1, 1, 0) // B
    ..addNode(2, 2, 0) // C
    ..addNode(3, 1, 1.118); // D (1.5 km from A and from C)
  g
    ..addRoad(0, 1, 30)
    ..addRoad(1, 2, 30)
    ..addRoad(0, 3, 90)
    ..addRoad(3, 2, 90);
  final fast = findRoute(g, 0, 2)!;
  check(
    [fast.path, fast.seconds.round()],
    [
      [0, 3, 2],
      120,
    ],
  ); // 2 x 1.5 km at 90 km/h
  g.setCongestion(0, 3, 4); // accident on the highway ramp
  final jammed = findRoute(g, 0, 2)!;
  check(
    [jammed.path, jammed.seconds.round()],
    [
      [0, 1, 2],
      240,
    ],
  ); // 2 x 1 km at 30 km/h beats 240 + 60

  // One-way streets are respected.
  final oneWay = RoadGraph()
    ..addNode(0, 0, 0)
    ..addNode(1, 1, 0);
  oneWay.addRoad(0, 1, 50, oneWay: true);
  check(
    [findRoute(oneWay, 0, 1)?.path, findRoute(oneWay, 1, 0)],
    [
      [0, 1],
      null,
    ],
  );

  // A 40 x 40 city grid (0.5 km blocks): streets 30 km/h, every 5th street an avenue at 60 km/h.
  const n = 40;
  final city = RoadGraph();
  int id(int r, int c) => r * n + c;
  for (var r = 0; r < n; r++) {
    for (var c = 0; c < n; c++) {
      city.addNode(id(r, c), c * 0.5, r * 0.5);
    }
  }
  for (var r = 0; r < n; r++) {
    for (var c = 0; c < n; c++) {
      if (c + 1 < n) city.addRoad(id(r, c), id(r, c + 1), r % 5 == 0 ? 60 : 30);
      if (r + 1 < n) city.addRoad(id(r, c), id(r + 1, c), c % 5 == 0 ? 60 : 30);
    }
  }
  final rng = Random(2);
  var dijkstraExpanded = 0, aStarExpanded = 0;
  for (var q = 0; q < 50; q++) {
    final s = rng.nextInt(n * n), t = rng.nextInt(n * n);
    final d = findRoute(city, s, t, useAStar: false)!, a = findRoute(city, s, t)!;
    if ((d.seconds - a.seconds).abs() > 1e-6) throw StateError('A* returned a worse route');
    dijkstraExpanded += d.expanded;
    aStarExpanded += a.expanded;
  }
  check(aStarExpanded * 10 < dijkstraExpanded * 7, true); // same answers, at least 30% fewer expansions
  print('ok: Dijkstra expanded $dijkstraExpanded nodes, A* $aStarExpanded');

  // Navigation: the driver misses a turn and ends up off the route; the session reroutes.
  final session = NavigationSession(city, id(39, 39), id(0, 0));
  final planned = session.route;
  session.onPosition(planned.path[3]); // on the route: nothing happens
  final offRoute = [for (var k = 0; k < n * n; k++) k].firstWhere((k) => !planned.path.contains(k) && k != id(0, 0));
  session.onPosition(offRoute);
  check([session.reroutes, session.route.path.first, session.route.path.last], [1, offRoute, id(39, 39)]);
}
```

## 5. Walkthrough

- San Francisco at zoom 10 is tile (163, 395); at zoom 0 the whole world is tile (0, 0).
- A to C directly is 2 km at 30 km/h (240 s); the highway detour is 3 km at 90 km/h (120 s), so the router takes the highway. With a 4x congestion factor on the ramp (240 s for that segment alone), the direct streets win.
- A one-way street can be driven in one direction only; the reverse query has no route.
- On a 40 x 40 grid with faster avenues every five streets, Dijkstra and A* return routes of identical duration for 50 random trips, but A* expands substantially fewer nodes because it is pulled toward the destination.
- The navigation session ignores positions on its path and reroutes once the driver appears at a node off the planned route.

## 6. Concurrency

- The routing graph is read-only during queries; traffic updates replace congestion values atomically (a new weights array swapped in every minute), so queries see a consistent snapshot.
- Each query keeps its own `best`, `parent` and heap: thousands of queries run in parallel on one in-memory graph.
- Navigation sessions are independent; position updates for one session are processed in order (partition by session ID).

## 7. Extensibility

| Change | Where |
|---|---|
| Contraction hierarchies | Preprocess shortcuts; bidirectional upward search replaces `findRoute`. |
| Turn costs and restrictions | Edge-based graph (nodes = segments, edges = allowed turns). |
| Avoid tolls / highways | Filter or penalize edges by attributes during search. |
| Time-dependent ETA | Edge time as a function of the arrival time at that edge (historical speeds). |
| Alternative routes | Penalize edges of the first route and search again. |

## 8. Common mistakes in LLD rounds

- Using distance instead of time as the cost.
- An inadmissible heuristic (overestimating), which makes A* return worse routes.
- Recomputing everything on each traffic update instead of updating weights.
- Forgetting one-way streets.

See [HLD.md](HLD.md) for tiles, traffic pipelines and continental-scale routing.
