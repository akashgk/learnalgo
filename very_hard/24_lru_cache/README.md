# LRU Cache

**Difficulty:** Very Hard | **Category:** Linked Lists | **Pattern:** Hash map + doubly linked list

## Problem
Implement a Least Recently Used cache with a maximum size:
- `insertKeyValuePair(key, value)`: insert or update; if the cache is full, evict the least recently used entry first.
- `getValueFromKey(key)`: return the value (or null) and mark the key as most recently used.
- `getMostRecentKey()`: return the most recently used key.
All operations in O(1).

## Building up the logic
1. A hash map alone gives O(1) lookup but no recency order.
2. A list ordered by recency gives the LRU element at one end, but moving an accessed element to the front is O(n) in an array.
3. A **doubly linked list** can unlink any node in O(1) if you have a pointer to it. The hash map provides that pointer: `key -> node`.
4. Operations:
   - get: map lookup, unlink the node, re-insert at the front.
   - insert: if present, update and move to front; else evict the tail node if full (remove it from the map too, which is why nodes store their key), then add a new node at the front.
5. **Sentinel head and tail** nodes remove every null check in `unlink`/`addToFront`.

## Complexity
- All operations: O(1).
- Space: O(capacity).

## Interview notes
- LeetCode #146, one of the most frequently asked design questions at every FAANG company. Expect follow-ups: thread safety (lock or striped locks), TTL expiry, LFU cache (#460, frequency buckets of linked lists).
- Language shortcuts (Java `LinkedHashMap` with access order, Python `OrderedDict.move_to_end`, Dart's default `LinkedHashMap` with remove + re-insert) are worth mentioning, but interviewers usually want the hand-built version.
