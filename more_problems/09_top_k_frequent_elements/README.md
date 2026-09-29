# Top K Frequent Elements

**Difficulty:** Medium | **Category:** Hashing / Heaps | **Pattern:** Bucket sort by frequency | **Source:** LeetCode 347; NeetCode 150, Blind 75

## The problem

Return the `k` most frequent values in an array. The answer is unique in LeetCode's version; return it in any order.

```
[1, 1, 1, 2, 2, 3], k = 2   ->  [1, 2]
[1], k = 1                  ->  [1]
```

The goal: better than O(n log n).

### Clarifying questions to ask

| Question | Why it matters |
|---|---|
| Ties at the k-th place? | Decide how to break them, or confirm the answer is unique. |
| Output order? | Sorted by frequency or any order. |
| Stream or array? | A stream suggests a heap of size k. |

## Step 1: Count

Any solution first counts frequencies with a hash map: O(n). The question is how to pick the k largest counts.

## Step 2: Option A, sort

Sort the distinct values by count, take the first k. O(d log d) where d is the number of distinct values (up to n). Fine, but the problem asks for better.

## Step 3: Option B, min-heap of size k

Push each (count, value); if the heap exceeds size k, pop the smallest. The heap always holds the k best so far. O(d log k). This is the right answer when data arrives as a stream or k is tiny.

## Step 4: Option C, bucket sort (O(n))

**Observation: a frequency is an integer between 1 and n.** Values with a small bounded range can be sorted by **bucketing** instead of comparing. Make `n + 1` buckets, where `buckets[f]` lists every value that occurs exactly `f` times. Then walk from `f = n` down to 1 collecting values until you have k.

Total work: counting O(n), filling buckets O(d), scanning buckets O(n). **O(n)** time.

This is the general lesson: when the keys you sort by are small integers, counting/bucket sort beats comparison sorting.

## Step 5: The code

<!-- CODE:START -->

Full source: [`top_k_frequent_elements.dart`](top_k_frequent_elements.dart) (run it with `dart run`).

```dart
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
```

<!-- CODE:END -->

### Walkthrough

- `count` maps value to frequency.
- `buckets` has `n + 1` lists (index 0 unused), created with `List.generate` so each bucket is a **separate** list. (`List.filled(n + 1, <int>[])` would share one list across all buckets, a classic Dart bug.)
- The outer loop goes from the highest possible frequency downward and stops once `k` values are collected. The inner `break` handles a bucket with more values than we still need.

## Step 6: Dry run

`[1, 1, 1, 2, 2, 3]`, k = 2. Counts: 1 -> 3, 2 -> 2, 3 -> 1.

| f | buckets[f] | result |
|---|---|---|
| 6, 5, 4 | [] | [] |
| 3 | [1] | [1] |
| 2 | [2] | [1, 2] (stop) |

## Complexity

| Approach | Time | Space |
|---|---|---|
| Sort by count | O(n + d log d) | O(d) |
| Min-heap of size k | O(n + d log k) | O(d + k) |
| Bucket sort | **O(n)** | O(n) |
| Quickselect on counts | O(n) average, O(n^2) worst | O(d) |

## Edge cases

- `k` equals the number of distinct values: return all of them.
- Negative values: the map keys can be anything; only frequencies index the buckets.

## Common mistakes

- `List.filled(n + 1, <int>[])`: every bucket is the same list object.
- Using a **max**-heap of all d elements and popping k times: O(d + k log d), fine, but the size-k min-heap is the one interviewers want to see for streams.
- Forgetting that the highest frequency can be n (size the bucket array `n + 1`).

## Follow-ups you should be ready for

1. **Top K Frequent Words (LeetCode 692).** Ties broken alphabetically: a heap with a custom comparator.
2. **Streaming data, approximate.** Count-Min Sketch plus a heap (heavy hitters).
3. **Kth largest element (LeetCode 215).** Quickselect, or a size-k heap; see AlgoExpert hard 46 Quickselect.

## What to remember

Frequencies are bounded by n. When the sort key is a small integer, bucket by it for O(n). Mention the size-k heap as the streaming alternative.
