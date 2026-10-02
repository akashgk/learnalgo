# Distributed Key-Value Store (Dynamo / Cassandra): High-Level Design

**Asked at:** Amazon, Google, Microsoft, Meta, Apple, Databricks. **Core topics:** partitioning, replication, quorum consistency (N, R, W), conflict resolution (last-writer-wins vs vector clocks), handling failures (sloppy quorum, hinted handoff, anti-entropy), the storage engine (LSM tree), CAP trade-offs.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| API? | `get(key)`, `put(key, value)`, `delete(key)`. Values up to ~1 MB. No transactions, no secondary indexes. |
| Scale? | Petabytes, millions of operations per second, hundreds to thousands of nodes. |
| Consistency vs availability? | Tunable per request; default favors availability (an AP system, like Dynamo). |
| Latency? | Single-digit milliseconds at p99. |
| Durability? | Writes survive node failures (replicated, logged to disk). |
| Range scans? | Not required across the cluster (hash partitioning); sorted within a partition. |

## 2. Requirements

**Functional:** get, put, delete, with configurable consistency.

**Non-functional:** horizontal scalability (add nodes, data rebalances), high availability (writes accepted even during failures), durability, tunable consistency, low latency, no single point of failure (every node equal).

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Data | 1 PB logical x 3 replicas | **3 PB** raw |
| Nodes | 3 PB / ~10 TB usable per node | **~300 nodes** |
| Throughput | 1 M ops/s / 300 nodes, x3 for replication on writes | **~5-10K ops/s per node**: comfortable for an LSM engine on SSD |
| Per-key metadata | version / vector clock, timestamps | tens of bytes |

## 4. Architecture

```text
 client --> any node (coordinator for this request)
              |  hash(key) -> position on the ring -> preference list: next N distinct nodes
              v
      +---------------+   +---------------+   +---------------+
      | node A        |   | node B        |   | node C        |   ... (all nodes identical)
      |  request layer|   |               |   |               |
      |  replication  |   |               |   |               |
      |  storage: LSM |   |  WAL, memtable, SSTables, bloom filters, compaction
      +---------------+   +---------------+   +---------------+
      membership + failure detection: gossip protocol (no master)
      background: hinted handoff delivery, anti-entropy with Merkle trees, compaction
```

## 5. Deep dive: partitioning and replication

- **Consistent hashing with virtual nodes** (see 03): adding a node moves ~1/N of the data; virtual nodes spread load and recovery traffic.
- Each key is stored on the **N** distinct physical nodes following its position on the ring (its preference list). N = 3 is typical; place replicas in different racks / zones.

## 6. Deep dive: quorums

A write goes to all N replicas; the coordinator waits for **W** acknowledgments. A read queries replicas and waits for **R** responses, returning the newest version.

| Setting | Effect |
|---|---|
| **R + W > N** (e.g. N=3, R=2, W=2) | Read and write sets overlap in at least one replica: a read sees the latest acknowledged write (absent sloppy quorum and concurrent writes). |
| W = 1 | Fastest writes, highest availability; a read may miss recent writes. |
| R = 1 | Fastest reads, possibly stale. |
| W = N | Writes fail if any replica is down. |

Quorums give **tunable consistency**, not linearizability: concurrent writes, failures during writes and sloppy quorums can still produce anomalies. Strong consistency needs consensus (Raft/Paxos) per partition, at a latency and availability cost: this is the CP choice (Spanner, etcd).

## 7. Deep dive: versions and conflicts

| Strategy | How | Trade-off |
|---|---|---|
| **Last-writer-wins** (Cassandra) | each write carries a timestamp; newest wins | simple; concurrent writes silently lose data; relies on reasonably synced clocks |
| **Vector clocks** (original Dynamo) | each version carries `{node: counter}`; descendants replace ancestors; concurrent siblings are both kept and returned | no silent loss; the application must merge (shopping-cart union) |
| CRDTs | data types whose merges are automatic and commutative (counters, sets) | conflict-free by construction for those types |

## 8. Deep dive: handling failures

- **Sloppy quorum + hinted handoff:** if a preferred replica is down, the write goes to the next healthy node with a **hint** naming the intended owner. When the owner recovers, the hint is delivered and deleted. Keeps writes available during failures.
- **Read repair:** when a read sees stale replicas, the coordinator writes the newest version back to them.
- **Anti-entropy:** replicas compare **Merkle trees** (hash trees over key ranges) and exchange only differing ranges. Catches what hints and read repair miss.
- **Failure detection:** gossip: every node periodically exchanges membership and heartbeat counters with a few random peers; a node not heard from in a while is suspected (phi accrual detector).
- **Deletes:** written as **tombstones** (a delete marker with a version) so a stale replica cannot resurrect the value; tombstones are purged after a grace period longer than the repair interval.

## 9. Deep dive: storage engine (LSM tree)

```text
put --> append to WAL (disk, sequential) --> insert into memtable (sorted, in memory)
                                                 | full
                                                 v
                                         flush to SSTable (immutable, sorted file + index + bloom filter)
get --> memtable --> newest SSTable --> ... --> oldest   (bloom filters skip files that cannot contain the key)
background compaction merges SSTables: keeps newest versions, drops overwritten values and expired tombstones
```

Why LSM: writes are sequential appends (fast on any disk); reads are helped by bloom filters and caches; compaction reclaims space. B-trees (in-place updates) favor reads; LSM favors writes.

## 10. Scaling and failure table

| Event | Behavior |
|---|---|
| Node added | Takes ownership of ranges from neighbors; data streamed to it; ring updated via gossip. |
| Node down briefly | Sloppy quorum + hints; delivered on recovery. |
| Node dead permanently | Replaced; data rebuilt from replicas (streaming + anti-entropy). |
| Network partition | Both sides keep accepting writes (AP); conflicts reconciled later by LWW or vector clocks. |
| Hot key | Caching in front; split the key at the application level. |

## 11. What interviewers look for

- Consistent hashing, replication factor, preference lists.
- N/R/W quorums and the R + W > N reasoning, plus its limits.
- A conflict resolution strategy and its trade-offs.
- Sloppy quorum, hinted handoff, read repair, Merkle-tree anti-entropy, gossip.
- The LSM write and read path.

## 12. Common mistakes

- A single master that all writes go through (now it is not Dynamo, and it needs its own failover story).
- Claiming R + W > N gives strong consistency in all cases.
- Deleting by removing the key (stale replicas resurrect it): use tombstones.
- Ignoring clock skew with last-writer-wins.

## 13. Follow-ups

1. **Strongly consistent mode:** Raft per partition (leader-based), like etcd or CockroachDB ranges.
2. **Secondary indexes:** local per node (scatter-gather reads) or global (another partitioned table, updated asynchronously).
3. **TTL:** expiry time per value, dropped during compaction.
4. **Multi-datacenter:** per-DC quorums (`LOCAL_QUORUM`), asynchronous cross-DC replication.

See [LLD.md](LLD.md) for an LSM storage engine (WAL, memtable, SSTables, tombstones, compaction, recovery) and a quorum coordinator with hinted handoff and read repair.
