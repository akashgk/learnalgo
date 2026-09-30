# Time Based Key-Value Store

**Difficulty:** Medium | **Category:** Binary Search | **Pattern:** Per-key sorted history + "last <= x" binary search | **Source:** LeetCode 981; NeetCode 150

## The problem

Design `TimeMap`:

- `set(key, value, timestamp)` stores a value for the key at that time.
- `get(key, timestamp)` returns the value set with the **largest timestamp <= the given one**, or `""` if there is none.

LeetCode guarantees that the timestamps of `set` calls are **strictly increasing**.

```
set("foo", "bar", 1)
get("foo", 1) -> "bar"
get("foo", 3) -> "bar"     (latest value at or before time 3)
set("foo", "bar2", 4)
get("foo", 4) -> "bar2"
get("foo", 3) -> "bar"
```

## Step 1: Structure

A hash map from key to that key's **history**: a list of `(timestamp, value)`. Because timestamps only increase, appending keeps each history **sorted by timestamp** for free. `set` is O(1).

## Step 2: Answering get

`get(key, t)` wants the **last** entry whose timestamp is `<= t`. A linear scan is O(n) per query. The history is sorted, so binary search it.

The "last element satisfying a condition" pattern:

```
found = -1
while lo <= hi:
  mid = ...
  if list[mid].time <= t:  found = mid; lo = mid + 1   // a candidate; look right for a later one
  else:                    hi = mid - 1
```

The predicate "time <= t" is true...true false...false over the list, and we want the last true.

## Step 3: The code

<!-- CODE:START -->

Full source: [`time_based_key_value_store.dart`](time_based_key_value_store.dart) (run it with `dart run`).

```dart
// Time Based Key-Value Store: set(key, value, timestamp) and get(key, timestamp), where get returns
// the value with the largest timestamp <= the given one ("" if none).
// Timestamps for set calls are strictly increasing, so each key's history is appended in sorted
// order; get binary searches it. set O(1), get O(log n).

class TimeMap {
  final _history = <String, List<(int, String)>>{}; // key -> [(timestamp, value)] sorted by timestamp

  void set(String key, String value, int timestamp) {
    _history.putIfAbsent(key, () => []).add((timestamp, value));
  }

  String get(String key, int timestamp) {
    final list = _history[key];
    if (list == null) return '';
    // Find the last entry with time <= timestamp.
    var lo = 0, hi = list.length - 1, found = -1;
    while (lo <= hi) {
      final mid = lo + (hi - lo) ~/ 2;
      if (list[mid].$1 <= timestamp) {
        found = mid; // candidate; a later one may also qualify
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return found == -1 ? '' : list[found].$2;
  }
}
```

<!-- CODE:END -->

### Walkthrough

- `_history` maps each key to a list of Dart records `(int, String)`.
- `putIfAbsent(key, () => [])` creates the history on first use.
- `found` remembers the best candidate so far; `-1` means every timestamp is greater than `t`.

## Step 4: Dry run

History of `"foo"`: `[(1, bar), (4, bar2)]`. `get("foo", 3)`:

| lo | hi | mid | time | <= 3? | found |
|---|---|---|---|---|---|
| 0 | 1 | 0 | 1 | yes | 0, lo = 1 |
| 1 | 1 | 1 | 4 | no | 0, hi = 0 |

Return `"bar"`.

## Complexity

- `set`: **O(1)** amortized.
- `get`: **O(log h)**, h = number of sets for that key.
- Space: **O(total sets)**.

## Edge cases

- Unknown key: `""`.
- Query earlier than the first set: `""`.
- Query exactly at a set timestamp: that value.

## Common mistakes

- Binary searching for an exact timestamp.
- Returning `list[lo]` after the loop without checking bounds (off by one).
- Not relying on the increasing-timestamp guarantee, and sorting on every `set`.

## Follow-ups you should be ready for

1. **Timestamps not increasing.** Use a sorted map per key (`SplayTreeMap.lastKeyBefore` style lookups: `lastKeyBefore(t + 1)`), O(log h) set and get.
2. **Snapshot Array (LeetCode 1146).** The same "history per index + binary search" design.
3. **Memory limits.** Compress histories, or drop entries older than a retention window.

## What to remember

Append-only histories are sorted by construction. "Latest value at or before t" is a "last true" binary search.
