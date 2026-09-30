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

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final tm = TimeMap();
  tm.set('foo', 'bar', 1);
  check(tm.get('foo', 1), 'bar');
  check(tm.get('foo', 3), 'bar'); // latest at or before 3 is time 1
  tm.set('foo', 'bar2', 4);
  check(tm.get('foo', 4), 'bar2');
  check(tm.get('foo', 5), 'bar2');
  check(tm.get('foo', 3), 'bar');
  check(tm.get('foo', 0), ''); // before the first set
  check(tm.get('missing', 10), '');
}
