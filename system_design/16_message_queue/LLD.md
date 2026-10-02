# Distributed Message Queue: Low-Level Design

## 1. Scope for the LLD round

- A **partition log** made of fixed-size **segments**; append returns an offset; reads from any retained offset; **retention** deletes whole old segments.
- A **topic** of several partitions with a **partitioner**: same key -> same partition (ordered per key); no key -> round robin.
- **Consumer groups**: a coordinator assigns partitions to members (range assignment) and **rebalances** on join and leave; consumers commit offsets after processing (**at-least-once**), so a crash before commit causes redelivery.
- **Replication** of one partition: leader and followers, **in-sync replicas**, a **high watermark** that limits what consumers see, `acks = leader` vs `acks = all`, and leader failover.
- **Idempotent producer**: (producer ID, sequence number) deduplicates retries.

Out of scope: networking, disk files, the controller quorum, transactions (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Record` | Offset, key, value. |
| `Segment` | A base offset and its records (one file in a real broker). |
| `PartitionLog` | Segments; `append`, `read`, `enforceRetention`; log start and end offsets. |
| `Topic` | Partitions and the partitioner. |
| `GroupCoordinator` | Members, assignment, committed offsets per partition. |
| `ReplicatedPartition` | Logs per broker, leader, ISR, high watermark, idempotent producer state. |
| `Acks` (enum) | `leader` or `all`. |

```text
Topic --has many--> PartitionLog --has many--> Segment --has many--> Record
GroupCoordinator --assigns partitions of--> Topic to members; stores committed offsets
ReplicatedPartition --has--> PartitionLog per broker (leader + followers), ISR set, high watermark
```

## 3. Design decisions and why

- **Offsets are positions, not IDs.** A consumer's progress is one integer per partition, which makes commits cheap and replay trivial.
- **Segments make retention O(1):** delete the oldest segment file instead of rewriting the log. The active (newest) segment is never deleted.
- **Finding the segment for an offset** is a binary search over base offsets (real brokers also keep a sparse index inside each segment).
- **Range assignment** is deterministic (sorted members, contiguous partition ranges), so every member computes the same answer.
- **Commit after processing** gives at-least-once; the test shows the duplicate that a crash causes, which is why consumers should be idempotent.
- **High watermark = minimum log end offset across the ISR.** Consumers never read past it, so a message that only the old leader had (and that is lost on failover) was never visible to anyone.
- **Producer sequence numbers** turn producer retries into no-ops and detect gaps.

## 4. The code

```dart
// ---------- Log ----------

class Record {
  const Record(this.offset, this.key, this.value);
  final int offset;
  final String? key;
  final String value;
  @override
  String toString() => '$offset:$value';
}

class Segment {
  Segment(this.baseOffset);
  final int baseOffset;
  final records = <Record>[];
  int get nextOffset => baseOffset + records.length;
}

class OffsetOutOfRangeException implements Exception {
  OffsetOutOfRangeException(this.offset);
  final int offset;
}

class PartitionLog {
  PartitionLog({this.segmentSize = 3});
  final int segmentSize;
  final segments = <Segment>[Segment(0)];

  int get logStartOffset => segments.first.baseOffset;
  int get logEndOffset => segments.last.nextOffset;

  int append(String? key, String value) {
    if (segments.last.records.length == segmentSize) segments.add(Segment(logEndOffset)); // roll a new segment
    final r = Record(logEndOffset, key, value);
    segments.last.records.add(r);
    return r.offset;
  }

  /// Up to [max] records from [offset], never at or beyond [upTo] (defaults to the log end).
  List<Record> read(int offset, int max, {int? upTo}) {
    final end = upTo ?? logEndOffset;
    if (offset < logStartOffset || offset > logEndOffset) throw OffsetOutOfRangeException(offset);
    // Binary search for the last segment whose base offset <= offset.
    var lo = 0, hi = segments.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (segments[mid].baseOffset <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    final out = <Record>[];
    for (var s = lo; s < segments.length && out.length < max; s++) {
      for (final r in segments[s].records) {
        if (r.offset >= offset && r.offset < end && out.length < max) out.add(r);
      }
    }
    return out;
  }

  /// Keep at most [maxSegments] segments; whole old segments are dropped. Returns how many were deleted.
  int enforceRetention(int maxSegments) {
    var deleted = 0;
    while (segments.length > maxSegments && segments.length > 1) {
      segments.removeAt(0);
      deleted++;
    }
    return deleted;
  }

  /// Drop everything at or after [offset] (a follower aligning with a new leader).
  void truncateTo(int offset) {
    for (final s in segments) {
      s.records.removeWhere((r) => r.offset >= offset);
    }
    while (segments.length > 1 && segments.last.records.isEmpty) {
      segments.removeLast();
    }
  }
}

// ---------- Topic and partitioner ----------

int stableHash(String s) {
  var h = 0x811C9DC5;
  for (final c in s.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

class Topic {
  Topic(this.name, int partitions) : partitions = List.generate(partitions, (_) => PartitionLog(segmentSize: 100));
  final String name;
  final List<PartitionLog> partitions;
  var _roundRobin = 0;

  int partitionFor(String? key) =>
      key == null ? _roundRobin++ % partitions.length : stableHash(key) % partitions.length;

  (int, int) produce(String? key, String value) {
    final p = partitionFor(key);
    return (p, partitions[p].append(key, value));
  }
}

// ---------- Consumer groups ----------

class GroupCoordinator {
  GroupCoordinator(this.topic);
  final Topic topic;
  final members = <String>[];
  var assignment = <String, List<int>>{};
  final committed = <int, int>{}; // partition -> next offset to read
  var generation = 0;

  void join(String member) {
    members.add(member);
    _rebalance();
  }

  void leave(String member) {
    members.remove(member);
    _rebalance();
  }

  /// Range assignment: sorted members get contiguous blocks; the first members get one extra if uneven.
  void _rebalance() {
    generation++;
    final sorted = [...members]..sort();
    final n = topic.partitions.length;
    assignment = {};
    var next = 0;
    for (var i = 0; i < sorted.length; i++) {
      final count = n ~/ sorted.length + (i < n % sorted.length ? 1 : 0);
      assignment[sorted[i]] = [for (var p = next; p < next + count; p++) p];
      next += count;
    }
  }

  void commit(int partition, int nextOffset) => committed[partition] = nextOffset;

  /// Fetch for a member: records from the committed position of each assigned partition.
  List<(int, Record)> poll(String member, {int max = 10}) => [
    for (final p in assignment[member] ?? const <int>[])
      for (final r in topic.partitions[p].read(committed[p] ?? 0, max)) (p, r),
  ];
}

// ---------- Replication ----------

enum Acks { leader, all }

class OutOfOrderSequenceException implements Exception {}

class ReplicatedPartition {
  ReplicatedPartition(List<String> brokers)
    : leader = brokers.first,
      isr = {...brokers},
      logs = {for (final b in brokers) b: PartitionLog()};

  String leader;
  final Set<String> isr;
  final Map<String, PartitionLog> logs;
  var highWatermark = 0;
  final _lastSeq = <String, int>{};
  final _offsetOfSeq = <(String, int), int>{};

  /// Idempotent produce: a retried (producerId, seq) returns the original offset without appending.
  int produce(String producerId, int seq, String value, {Acks acks = Acks.all}) {
    final existing = _offsetOfSeq[(producerId, seq)];
    if (existing != null) return existing;
    if (seq != (_lastSeq[producerId] ?? -1) + 1) throw OutOfOrderSequenceException();
    final offset = logs[leader]!.append(null, value);
    _lastSeq[producerId] = seq;
    _offsetOfSeq[(producerId, seq)] = offset;
    if (acks == Acks.all) {
      for (final f in isr.where((b) => b != leader)) {
        followerFetch(f); // the ack waits until every in-sync replica has the record
      }
    }
    return offset;
  }

  void followerFetch(String follower) {
    final log = logs[follower]!;
    for (final r in logs[leader]!.read(log.logEndOffset, 1 << 30)) {
      log.append(r.key, r.value);
    }
    _updateHighWatermark();
  }

  void _updateHighWatermark() {
    highWatermark = isr.map((b) => logs[b]!.logEndOffset).reduce((a, b) => a < b ? a : b);
  }

  /// Consumers only see committed (fully replicated) records.
  List<Record> consume(int offset, int max) => logs[leader]!.read(offset, max, upTo: highWatermark);

  void leaderFails() {
    isr.remove(leader);
    leader = isr.first; // elected from the ISR only (clean election)
    for (final b in isr) {
      logs[b]!.truncateTo(highWatermark); // records above the HW were never acknowledged to acks=all producers
    }
    _updateHighWatermark();
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void expectThrows<T extends Object>(void Function() f) {
  try {
    f();
  } on T {
    print('ok: threw $T');
    return;
  }
  throw StateError('expected $T');
}

void main() {
  // Segments, reads and retention.
  final log = PartitionLog(segmentSize: 3);
  for (var i = 0; i < 7; i++) {
    log.append(null, 'm$i');
  }
  check(log.segments.map((s) => s.baseOffset), '(0, 3, 6)');
  check(log.read(4, 10), '[4:m4, 5:m5, 6:m6]');
  check(log.read(1, 2), '[1:m1, 2:m2]');
  check(log.enforceRetention(2), 1);
  check([log.logStartOffset, log.logEndOffset], [3, 7]);
  expectThrows<OffsetOutOfRangeException>(() => log.read(1, 1)); // already deleted

  // Partitioning: same key, same partition, in order; null keys spread round robin.
  final topic = Topic('orders', 4);
  for (var i = 0; i < 3; i++) {
    topic.produce('customer-7', 'c7-event-$i');
  }
  final p7 = topic.partitionFor('customer-7');
  check(
    topic.partitions[p7].read(0, 10).where((r) => r.key == 'customer-7').map((r) => r.value),
    '(c7-event-0, c7-event-1, c7-event-2)',
  );
  check([for (var i = 0; i < 4; i++) topic.produce(null, 'n$i').$1], [0, 1, 2, 3]);

  // Consumer group: rebalancing and at-least-once redelivery after a crash.
  final group = GroupCoordinator(topic)..join('c1');
  check(group.assignment, {
    'c1': [0, 1, 2, 3],
  });
  group.join('c2');
  check(group.assignment, {
    'c1': [0, 1],
    'c2': [2, 3],
  });
  final processed = <String>[];
  final c2Batch = group.poll('c2');
  for (final (_, r) in c2Batch) {
    processed.add(r.value); // processed...
  }
  // ...but c2 crashes before committing. Its partitions move to c1, which starts from the committed offsets.
  group.leave('c2');
  check(group.assignment, {
    'c1': [0, 1, 2, 3],
  });
  final c1Batch = group.poll('c1');
  for (final (p, r) in c1Batch) {
    processed.add(r.value);
    group.commit(p, r.offset + 1);
  }
  final duplicates = processed.length - processed.toSet().length;
  check([duplicates, duplicates == c2Batch.length], [c2Batch.length, true]); // c2's messages were delivered twice
  check(group.poll('c1'), []); // everything committed
  group.join('c3');
  check([group.assignment['c1'], group.assignment['c3'], group.generation], ['[0, 1]', '[2, 3]', 4]);

  // Replication with a high watermark, acks, idempotent producer and failover.
  final part = ReplicatedPartition(['b1', 'b2', 'b3']);
  check(part.produce('p1', 0, 'm0'), 0); // acks=all: replicated before the ack
  check(part.highWatermark, 1);
  check(part.produce('p1', 0, 'm0'), 0); // retry of the same sequence: deduplicated
  check(part.logs['b1']!.logEndOffset, 1);
  expectThrows<OutOfOrderSequenceException>(() => part.produce('p1', 5, 'gap'));

  part.produce('p1', 1, 'm1', acks: Acks.leader); // only the leader has it
  check([part.logs['b1']!.logEndOffset, part.highWatermark], [2, 1]);
  check(part.consume(0, 10), '[0:m0]'); // m1 is invisible to consumers until replicated

  part.leaderFails(); // b1 dies before b2 and b3 fetched m1
  check([part.leader, part.isr], ['b2', '{b2, b3}']);
  check(part.produce('p2', 0, 'm2'), 1); // m1 was never committed and is gone
  check(part.consume(0, 10), '[0:m0, 1:m2]');
  check(part.logs['b3']!.read(0, 10), '[0:m0, 1:m2]');
}
```

## 5. Walkthrough

- Seven records with 3 per segment give segments at base offsets 0, 3, 6. Reading from offset 4 starts in the second segment. Retention of 2 segments deletes the first one; offset 1 is gone.
- All three `customer-7` events land in one partition in production order. Keyless messages rotate over partitions 0, 1, 2, 3.
- `c2` reads its partitions and processes the messages but crashes before committing. After the rebalance `c1` owns everything and reads from the committed offsets (none for `c2`'s partitions), so exactly `c2`'s messages are processed twice: at-least-once. When `c3` joins, generation 4 splits the partitions again.
- `m0` with `acks = all` is on all three brokers before the producer gets offset 0; a retry with the same sequence returns 0 without appending. `m1` with `acks = leader` exists only on `b1`, so the high watermark stays at 1 and consumers do not see it. When `b1` dies, `b2` becomes leader, `m1` is lost, and no consumer ever saw it. The next message takes offset 1 on all replicas.

## 6. Concurrency

- One partition has one writer (its leader), so appends need only a lock per partition; different partitions proceed in parallel. That is why partitions are the unit of parallelism.
- Consumers fetching while the leader appends read an immutable prefix of the log (up to the high watermark), so no lock is needed on the read path beyond publishing the HW atomically.
- The group coordinator serializes membership changes per group. Production coordinators also reject commits carrying an old `generation` (this code tracks the number but does not check it), which stops a zombie consumer from committing after a rebalance.

## 7. Extensibility

| Change | Where |
|---|---|
| Time-based retention | Segments keep their max timestamp; delete segments older than the limit. |
| Log compaction | Rewrite closed segments keeping the latest record per key. |
| Sticky / cooperative assignment | Another assignment strategy behind the same `_rebalance` hook. |
| Dead-letter topic | Consumer catches processing failures after N attempts and produces to `<topic>.dlq`. |
| Follower lag eviction | Remove a follower from the ISR when its log end offset lags beyond a threshold for too long. |

## 8. Common mistakes in LLD rounds

- A single list for the whole log (retention becomes a rewrite).
- Committing offsets before processing while claiming at-least-once.
- Letting consumers read up to the leader's log end instead of the high watermark.
- Non-deterministic partition assignment across members.
- Partitioning by `hashCode` that differs between processes.

See [HLD.md](HLD.md) for brokers, the controller, storage internals and delivery semantics.
