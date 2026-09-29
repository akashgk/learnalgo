// LRU Cache: hash map (key -> node) + doubly linked list ordered by recency.
// insertKeyValuePair, getValueFromKey, getMostRecentKey all O(1). O(capacity) space.

class _Node {
  _Node(this.key, this.value);
  final String key;
  int value;
  _Node? prev;
  _Node? next;
}

class LRUCache {
  LRUCache(int maxSize) : maxSize = maxSize < 1 ? 1 : maxSize {
    _head.next = _tail;
    _tail.prev = _head;
  }

  final int maxSize;
  final _map = <String, _Node>{};
  // Sentinels: _head.next is the most recent, _tail.prev the least recent.
  final _head = _Node('', 0);
  final _tail = _Node('', 0);

  void insertKeyValuePair(String key, int value) {
    final existing = _map[key];
    if (existing != null) {
      existing.value = value;
      _moveToFront(existing);
      return;
    }
    if (_map.length == maxSize) {
      final lru = _tail.prev!;
      _unlink(lru);
      _map.remove(lru.key);
    }
    final node = _Node(key, value);
    _map[key] = node;
    _addToFront(node);
  }

  int? getValueFromKey(String key) {
    final node = _map[key];
    if (node == null) return null;
    _moveToFront(node);
    return node.value;
  }

  String? getMostRecentKey() => _map.isEmpty ? null : _head.next!.key;

  void _moveToFront(_Node node) {
    _unlink(node);
    _addToFront(node);
  }

  void _unlink(_Node node) {
    node.prev!.next = node.next;
    node.next!.prev = node.prev;
  }

  void _addToFront(_Node node) {
    node
      ..prev = _head
      ..next = _head.next;
    _head.next!.prev = node;
    _head.next = node;
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final cache = LRUCache(3)
    ..insertKeyValuePair('b', 2)
    ..insertKeyValuePair('a', 1)
    ..insertKeyValuePair('c', 3);
  check(cache.getMostRecentKey(), 'c');
  check(cache.getValueFromKey('a'), 1);
  check(cache.getMostRecentKey(), 'a');
  cache.insertKeyValuePair('d', 4); // evicts 'b' (least recently used)
  check(cache.getValueFromKey('b'), null);
  cache.insertKeyValuePair('a', 5); // update existing
  check(cache.getValueFromKey('a'), 5);
  check(cache.getMostRecentKey(), 'a');
}
