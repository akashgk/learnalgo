// Alien Dictionary: given words sorted in an unknown alphabet, return one valid letter order
// ("" if the input is contradictory). Compare adjacent words to get edges, then topological sort
// (Kahn's algorithm). O(C) time where C = total characters, O(1) extra space for 26 letters.

import 'dart:collection';

String alienOrder(List<String> words) {
  final graph = <String, Set<String>>{};
  final indegree = <String, int>{};
  for (final w in words) {
    for (final ch in w.split('')) {
      graph.putIfAbsent(ch, () => {});
      indegree.putIfAbsent(ch, () => 0);
    }
  }
  for (var i = 0; i + 1 < words.length; i++) {
    final a = words[i], b = words[i + 1];
    final len = a.length < b.length ? a.length : b.length;
    var j = 0;
    while (j < len && a[j] == b[j]) {
      j++;
    }
    if (j == len) {
      // One word is a prefix of the other: the longer one must come second.
      if (a.length > b.length) return '';
      continue;
    }
    // Only the first difference gives information: a[j] comes before b[j].
    if (graph[a[j]]!.add(b[j])) indegree[b[j]] = indegree[b[j]]! + 1;
  }
  final queue = Queue<String>.of([
    for (final e in indegree.entries)
      if (e.value == 0) e.key,
  ]);
  final order = StringBuffer();
  while (queue.isNotEmpty) {
    final ch = queue.removeFirst();
    order.write(ch);
    for (final next in graph[ch]!) {
      indegree[next] = indegree[next]! - 1;
      if (indegree[next] == 0) queue.add(next);
    }
  }
  // Letters left over are on a cycle: the ordering is contradictory.
  return order.length == indegree.length ? order.toString() : '';
}

/// Checks that [order] is consistent with [words] (any valid order is accepted).
bool isValidOrder(List<String> words, String order) {
  final rank = {for (var i = 0; i < order.length; i++) order[i]: i};
  for (var i = 0; i + 1 < words.length; i++) {
    final a = words[i], b = words[i + 1];
    var j = 0;
    while (j < a.length && j < b.length && a[j] == b[j]) {
      j++;
    }
    if (j == a.length || j == b.length) {
      if (a.length > b.length) return false;
    } else if (rank[a[j]]! > rank[b[j]]!) {
      return false;
    }
  }
  return true;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(alienOrder(['wrt', 'wrf', 'er', 'ett', 'rftt']), 'wertf');
  check(alienOrder(['z', 'x']), 'zx');
  check(alienOrder(['z', 'x', 'z']), ''); // z < x and x < z: cycle
  check(alienOrder(['abc', 'ab']), ''); // prefix after the longer word
  final words = ['ba', 'bc', 'ac', 'cab'];
  final order = alienOrder(words);
  check(order.length, 3);
  check(isValidOrder(words, order), true);
}
