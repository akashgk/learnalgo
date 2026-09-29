// Airport Connections: minimum number of new one-way routes from the starting airport's
// network so every airport becomes reachable.
// Collapse strongly connected components (Kosaraju); the answer is the number of components
// with no incoming edges, excluding the start's component. O(a + r) time and space.

int airportConnections(List<String> airports, List<List<String>> routes, String startingAirport) {
  final id = {for (var i = 0; i < airports.length; i++) airports[i]: i};
  final n = airports.length;
  final adj = List.generate(n, (_) => <int>[]);
  final radj = List.generate(n, (_) => <int>[]);
  for (final [from, to] in routes) {
    adj[id[from]!].add(id[to]!);
    radj[id[to]!].add(id[from]!);
  }

  // Pass 1: order vertices by DFS finish time.
  final visited = List<bool>.filled(n, false);
  final order = <int>[];
  void dfs1(int u) {
    visited[u] = true;
    for (final v in adj[u]) {
      if (!visited[v]) dfs1(v);
    }
    order.add(u);
  }

  for (var u = 0; u < n; u++) {
    if (!visited[u]) dfs1(u);
  }

  // Pass 2: DFS on the reversed graph in reverse finish order; each tree is one SCC.
  final comp = List<int>.filled(n, -1);
  var compCount = 0;
  void dfs2(int u, int c) {
    comp[u] = c;
    for (final v in radj[u]) {
      if (comp[v] == -1) dfs2(v, c);
    }
  }

  for (final u in order.reversed) {
    if (comp[u] == -1) dfs2(u, compCount++);
  }

  final hasIncoming = List<bool>.filled(compCount, false);
  for (var u = 0; u < n; u++) {
    for (final v in adj[u]) {
      if (comp[u] != comp[v]) hasIncoming[comp[v]] = true;
    }
  }
  final startComp = comp[id[startingAirport]!];
  var answer = 0;
  for (var c = 0; c < compCount; c++) {
    if (!hasIncoming[c] && c != startComp) answer++;
  }
  return answer;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final airports = [
    'BGI',
    'CDG',
    'DEL',
    'DOH',
    'DSM',
    'EWR',
    'EYW',
    'HND',
    'ICN',
    'JFK',
    'LGA',
    'LHR',
    'ORD',
    'SAN',
    'SFO',
    'SIN',
    'TLV',
    'BUD',
  ];
  final routes = [
    ['DSM', 'ORD'],
    ['ORD', 'BGI'],
    ['BGI', 'LGA'],
    ['SIN', 'CDG'],
    ['CDG', 'SIN'],
    ['CDG', 'BUD'],
    ['DEL', 'DOH'],
    ['DEL', 'CDG'],
    ['TLV', 'DEL'],
    ['EWR', 'HND'],
    ['HND', 'ICN'],
    ['HND', 'JFK'],
    ['ICN', 'JFK'],
    ['JFK', 'LGA'],
    ['EYW', 'LHR'],
    ['LHR', 'SFO'],
    ['SFO', 'SAN'],
    ['SFO', 'DSM'],
    ['SAN', 'EYW'],
  ];
  check(airportConnections(airports, routes, 'LGA'), 3); // e.g. LGA->TLV, LGA->SFO, LGA->EWR
  check(
    airportConnections(
      ['A', 'B'],
      [
        ['A', 'B'],
      ],
      'A',
    ),
    0,
  );
  check(
    airportConnections(
      ['A', 'B', 'C'],
      [
        ['B', 'C'],
        ['C', 'B'],
      ],
      'A',
    ),
    1,
  );
}
