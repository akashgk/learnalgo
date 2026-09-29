// Top K Frequent Elements.
// Count with a hash map, then bucket sort by frequency (a frequency is at most n). O(n) time, O(n) space.

List<int> topKFrequent(List<int> nums, int k) {
  final count = <int, int>{};
  for (final x in nums) {
    count[x] = (count[x] ?? 0) + 1;
  }
  // buckets[f] holds every value that occurs exactly f times.
  final buckets = List.generate(nums.length + 1, (_) => <int>[]);
  count.forEach((value, f) => buckets[f].add(value));
  final result = <int>[];
  for (var f = nums.length; f >= 1 && result.length < k; f--) {
    for (final v in buckets[f]) {
      if (result.length == k) break;
      result.add(v);
    }
  }
  return result;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(topKFrequent([1, 1, 1, 2, 2, 3], 2), [1, 2]);
  check(topKFrequent([1], 1), [1]);
  check(topKFrequent([4, 4, 5, 5, 5, 6, 6, 6, 6], 1), [6]);
  check(topKFrequent([4, 4, 5, 5, 5, 6, 6, 6, 6], 3), [6, 5, 4]);
  check(topKFrequent([-1, -1, 2], 1), [-1]);
}
