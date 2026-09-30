// Reconstruct Itinerary: use every ticket [from, to] exactly once, starting at "JFK"; if several
// itineraries work, return the lexicographically smallest. An Eulerian path problem.
// Hierholzer's algorithm, always taking the smallest remaining destination, emitting airports in
// post-order and reversing. O(E log E) time (sorting), O(E) space.

List<String> findItinerary(List<List<String>> tickets) {
  // For each airport, destinations sorted DESCENDING so removeLast() yields the smallest.
  final graph = <String, List<String>>{};
  for (final t in tickets) {
    graph.putIfAbsent(t[0], () => []).add(t[1]);
  }
  for (final list in graph.values) {
    list.sort((a, b) => b.compareTo(a));
  }
  final route = <String>[];
  final stack = ['JFK'];
  while (stack.isNotEmpty) {
    final dests = graph[stack.last];
    if (dests != null && dests.isNotEmpty) {
      stack.add(dests.removeLast()); // follow the smallest unused ticket
    } else {
      route.add(stack.removeLast()); // dead end: this airport is final among what remains
    }
  }
  return route.reversed.toList();
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    findItinerary([
      ['MUC', 'LHR'],
      ['JFK', 'MUC'],
      ['SFO', 'SJC'],
      ['LHR', 'SFO'],
    ]),
    ['JFK', 'MUC', 'LHR', 'SFO', 'SJC'],
  );
  check(
    findItinerary([
      ['JFK', 'SFO'],
      ['JFK', 'ATL'],
      ['SFO', 'ATL'],
      ['ATL', 'JFK'],
      ['ATL', 'SFO'],
    ]),
    ['JFK', 'ATL', 'JFK', 'SFO', 'ATL', 'SFO'],
  );
  // Greedy "smallest first" dead-ends at KUL; Hierholzer still uses every ticket.
  check(
    findItinerary([
      ['JFK', 'KUL'],
      ['JFK', 'NRT'],
      ['NRT', 'JFK'],
    ]),
    ['JFK', 'NRT', 'JFK', 'KUL'],
  );
}
