# LFU Cache

**Difficulty:** Hard | **Category:** Design | **Pattern:** Hash maps + per-frequency doubly linked lists + min-frequency pointer | **Source:** LeetCode 460; Striver A2Z

## The problem

Design a cache with a fixed capacity supporting, both in **O(1)** average time:

- `get(key)`: return the value, or -1 if absent. Counts as a use.
- `put(key, value)`: insert or update. Updating counts as a use. When inserting into a full cache, first evict the **least frequently used** key; if several keys tie on frequency, evict the **least recently used** among them.

```
cache = LFUCache(2)
put(1, 1); put(2, 2)        freq: 1 -> 1, 2 -> 1
get(1) = 1                  freq: 1 -> 2
put(3, 3)                   evict 2 (freq 1); insert 3 (freq 1)
get(2) = -1
get(3) = 3                  freq: 3 -> 2
put(4, 4)                   1 and 3 both have freq 2; 1 was used longer ago: evict 1
get(1) = -1, get(3) = 3, get(4) = 4
```

## Step 1: Start from LRU

An LRU cache (AlgoExpert very_hard 24 LRU Cache) uses a hash map `key -> node` and **one** doubly linked list in recency order. Moving a node to the front and removing the tail are O(1).

LFU adds a second ordering: by frequency first, then by recency. A single list ordered by frequency would need O(n) to move a node past all others with the same frequency.

## Step 2: One LRU list per frequency

Group keys by frequency: `lists[f]` is a doubly linked list of the keys used exactly `f` times, most recently used at the front. Then:

- **Use a key** (get or update): remove its node from `lists[f]` (O(1) with a doubly linked list), increment `f`, add it to the front of `lists[f + 1]`.
- **Evict:** remove the **tail** of `lists[minFreq]`: lowest frequency, and least recently used within it.

What remains is knowing `minFreq` in O(1) without scanning.

## Step 3: Maintaining minFreq in O(1)

Two observations make this easy:

1. **A new key always has frequency 1**, the smallest possible. So after an insertion, `minFreq = 1`.
2. **When a key is used**, it moves from `f` to `f + 1`. `minFreq` can only change if the key was in `lists[minFreq]` and that list is now **empty**; then the new minimum is exactly `minFreq + 1` (the key we just moved is there).

No other operation changes `minFreq`. Eviction happens only right before an insertion, which resets `minFreq` to 1 anyway.

## Step 4: The code

<!-- CODE:START -->

Full source: [`lfu_cache.dart`](lfu_cache.dart) (run it with `dart run`).

```dart
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
```

<!-- CODE:END -->

### Walkthrough

- `_Node` stores key, value, frequency, and list links. The key is needed during eviction to delete it from `_nodes`.
- `_DList` uses **sentinel** head and tail nodes, so insert and remove never check for null neighbors.
- `get` returns -1 if absent; otherwise `_touch` then return.
- `put` with an existing key updates the value and touches it.
- `put` with a new key: evict from `_lists[_minFreq]` if full, insert with frequency 1, set `_minFreq = 1`.
- `capacity == 0` is handled up front: nothing is ever stored.

## Step 5: Dry run

The example above, showing each list with most recent first:

| operation | lists after | minFreq |
|---|---|---|
| put(1,1) | f1: [1] | 1 |
| put(2,2) | f1: [2, 1] | 1 |
| get(1) | f1: [2], f2: [1] | 1 |
| put(3,3) | evict tail of f1 = 2; f1: [3], f2: [1] | 1 |
| get(2) | -1 | 1 |
| get(3) | f1: [], f2: [3, 1] | f1 emptied and was min: 2 |
| put(4,4) | evict tail of f2 = 1; f1: [4], f2: [3] | 1 |

## Complexity

- Time: **O(1)** average for `get` and `put` (hash map operations plus constant pointer updates).
- Space: **O(capacity)** nodes, plus at most one list object per distinct frequency seen (empty lists can be deleted to keep this bounded).

## Edge cases

- Capacity 0: every `get` returns -1.
- Updating an existing key when full: no eviction (the key is already present).
- Many keys with the same frequency: LRU order within the list decides.

## Common mistakes

- Evicting before checking whether the key already exists (evicts needlessly on an update).
- Forgetting that an update counts as a use.
- Recomputing `minFreq` by scanning all frequencies (O(number of frequencies)).
- Evicting the head instead of the tail of the min-frequency list.

## Follow-ups you should be ready for

1. **LRU Cache (LeetCode 146).** One list; the building block here.
2. **Thread safety.** A single lock around each operation is the simple answer; lock striping or concurrent structures for more throughput.
3. **Frequency aging.** Real systems decay frequencies over time so that once-popular keys can be evicted (for example, TinyLFU in Caffeine).

## What to remember

LFU = LRU lists bucketed by frequency. The two facts that keep `minFreq` O(1): a new key has frequency 1, and a use can only raise the minimum by one, when it empties the minimum bucket.
