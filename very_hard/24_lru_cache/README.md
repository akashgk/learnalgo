# LRU Cache

**Difficulty:** Very Hard | **Category:** Linked Lists | **Pattern:** Hash map + doubly linked list

## The problem

Implement a **Least Recently Used (LRU) cache** with a maximum size and three operations, all in **O(1)**:

- `insertKeyValuePair(key, value)`: insert a new pair, or update the value of an existing key. If inserting a new key into a full cache, first **evict** the least recently used key.
- `getValueFromKey(key)`: return the value (or null if absent) and mark the key as **most recently used**.
- `getMostRecentKey()`: return the most recently used key.

```
cache = LRUCache(3)
insert b=2, insert a=1, insert c=3     most recent: c
get a -> 1                             most recent: a      (order now: a, c, b)
insert d=4                             cache full: evict b (least recent)
get b -> null
```

## Step 1: What each operation needs

- Find a key's value quickly: **hash map** (O(1) lookup).
- Know the recency order, find the least recent quickly, and **move** any key to the "most recent" position quickly.

An array ordered by recency can find the least recent at one end, but moving an element from the middle to the front is O(n).

## Step 2: The classic combination

A **doubly linked list** ordered by recency (most recent at the front, least recent at the back):

- move a node to the front: unlink it (O(1), because it knows its neighbors) and insert it after the head;
- evict: remove the node at the back.

A **hash map** `key -> node` gives O(1) access to any node, so we can unlink it without searching.

Nodes store their **key** as well as the value, so that when evicting the back node we can also delete its key from the map.

## Step 3: Sentinel nodes

Keep two permanent dummy nodes, `head` and `tail`. Real nodes always sit between them, so every real node has a non-null `prev` and `next`. Unlinking and inserting then need **no null checks** and no special cases for the first or last element.

## Step 4: Operations

```
get(key):
    node = map[key]; if missing: return null
    move node to front; return node.value

insert(key, value):
    if key in map: update value; move to front; return
    if map is full: lru = tail.prev; unlink it; remove lru.key from map
    create node; map[key] = node; add after head

mostRecent(): head.next.key
```

## Step 5: The code

<!-- CODE:START -->

Full source: [`lru_cache.dart`](lru_cache.dart) (run it with `dart run`).

```dart
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
```

<!-- CODE:END -->

### Walkthrough

- `_Node` holds `key`, `value`, `prev`, `next`.
- The constructor links the two sentinels to each other (an empty list).
- `_unlink` and `_addToFront` are the two O(1) pointer operations; `_moveToFront` combines them.
- `insertKeyValuePair` handles "update existing" first, then eviction, then insertion.

## Step 6: Dry run

| operation | list (front = most recent) | map keys |
|---|---|---|
| insert b | b | {b} |
| insert a | a, b | {a, b} |
| insert c | c, a, b | {a, b, c} |
| get a | a, c, b | |
| insert d (full: evict b) | d, a, c | {a, c, d} |
| get b | null | |
| insert a = 5 (update) | a, d, c | |

## Complexity

- **Every operation: O(1)** (average, because of hashing).
- **Space: O(capacity)**.

## Common mistakes

- Forgetting to remove the evicted key from the map (the map grows forever and later lookups return dead nodes).
- Not moving a key to the front on `get` (or on update).
- Singly linked list: unlinking a node then needs its predecessor, which requires a search.

## Follow-ups

1. **LRU Cache (LeetCode #146):** one of the most frequently asked design questions at every FAANG company.
2. **LFU Cache (#460):** evict the least **frequently** used; keep a map from frequency to a doubly linked list of keys and track the minimum frequency.
3. **Thread safety:** a lock around each operation, or lock striping for concurrency.
4. **Language shortcuts:** Java `LinkedHashMap` (access order + `removeEldestEntry`), Python `OrderedDict.move_to_end`, Dart's insertion-ordered `LinkedHashMap` (remove and re-insert to move a key to the end). Mention them, but expect to build it by hand in an interview.

## What to remember

O(1) lookup + O(1) reordering = hash map pointing into a doubly linked list. Sentinels remove the edge cases; store keys in nodes for eviction.
