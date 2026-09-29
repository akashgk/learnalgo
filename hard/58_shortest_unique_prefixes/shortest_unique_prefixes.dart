// Shortest Unique Prefixes: for each string, the shortest prefix no other string shares.
// (Assumes no string is a prefix of another.) Trie with pass-through counts.
// O(n * m) time and space.

class _TrieNode {
  final children = <String, _TrieNode>{};
  int count = 0;
}

List<String> shortestUniquePrefixes(List<String> strings) {
  final root = _TrieNode();
  for (final s in strings) {
    var node = root;
    for (var i = 0; i < s.length; i++) {
      node = node.children.putIfAbsent(s[i], _TrieNode.new);
      node.count++;
    }
  }
  return [for (final s in strings) _uniquePrefix(root, s)];
}

String _uniquePrefix(_TrieNode root, String s) {
  var node = root;
  for (var i = 0; i < s.length; i++) {
    node = node.children[s[i]]!;
    if (node.count == 1) return s.substring(0, i + 1); // only this string passes here
  }
  return s;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(shortestUniquePrefixes(['algoexpert', 'algorithm', 'foo', 'frontend']), ['algoe', 'algor', 'fo', 'fr']);
  check(shortestUniquePrefixes(['zebra', 'dog', 'duck', 'dove']), ['z', 'dog', 'du', 'dov']);
  check(shortestUniquePrefixes(['abc']), ['a']);
}
