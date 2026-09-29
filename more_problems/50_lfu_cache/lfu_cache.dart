// LFU Cache: get/put in O(1). On overflow evict the least frequently used key;
// ties broken by least recently used.
// key -> node map, plus freq -> doubly linked list (LRU order) map, plus the current minimum frequency.

class _Node {
  _Node(this.key, this.value);
  final int key;
  int value;
  int freq = 1;
  _Node? prev, next;
}

/// Doubly linked list with sentinels: most recently used at the front.
class _DList {
  _DList() {
    head.next = tail;
    tail.prev = head;
  }
  final head = _Node(0, 0), tail = _Node(0, 0);
  int size = 0;

  void addFront(_Node n) {
    n.next = head.next;
    n.prev = head;
    head.next!.prev = n;
    head.next = n;
    size++;
  }

  void remove(_Node n) {
    n.prev!.next = n.next;
    n.next!.prev = n.prev;
    size--;
  }

  _Node removeLast() {
    final n = tail.prev!;
    remove(n);
    return n;
  }
}

class LFUCache {
  LFUCache(this.capacity);
  final int capacity;
  final _nodes = <int, _Node>{};
  final _lists = <int, _DList>{};
  var _minFreq = 0;

  int get(int key) {
    final node = _nodes[key];
    if (node == null) return -1;
    _touch(node);
    return node.value;
  }

  void put(int key, int value) {
    if (capacity == 0) return;
    final existing = _nodes[key];
    if (existing != null) {
      existing.value = value;
      _touch(existing);
      return;
    }
    if (_nodes.length == capacity) {
      // Least frequent list, least recently used end.
      final victim = _lists[_minFreq]!.removeLast();
      _nodes.remove(victim.key);
    }
    final node = _Node(key, value);
    _nodes[key] = node;
    _lists.putIfAbsent(1, _DList.new).addFront(node);
    _minFreq = 1; // a brand-new key always has the lowest possible frequency
  }

  /// Moves [node] from its frequency list to the next one.
  void _touch(_Node node) {
    final list = _lists[node.freq]!;
    list.remove(node);
    if (list.size == 0 && node.freq == _minFreq) _minFreq++;
    node.freq++;
    _lists.putIfAbsent(node.freq, _DList.new).addFront(node);
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final c = LFUCache(2);
  c.put(1, 1); // freq(1) = 1
  c.put(2, 2); // freq(2) = 1
  check(c.get(1), 1); // freq(1) = 2
  c.put(3, 3); // evicts 2 (freq 1)
  check(c.get(2), -1);
  check(c.get(3), 3); // freq(3) = 2
  c.put(4, 4); // 1 and 3 both freq 2: evict the least recently used, which is 1
  check(c.get(1), -1);
  check(c.get(3), 3);
  check(c.get(4), 4);

  final z = LFUCache(0);
  z.put(0, 0);
  check(z.get(0), -1);

  final u = LFUCache(2);
  u.put(1, 1);
  u.put(1, 10); // update counts as a use: freq(1) = 2
  u.put(2, 2);
  u.put(3, 3); // evicts 2 (freq 1), not 1
  check(u.get(1), 10);
  check(u.get(2), -1);
}
