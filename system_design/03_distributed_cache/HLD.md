# Distributed Cache (Redis / Memcached): High-Level Design

**Asked at:** Amazon, Google, Meta, Microsoft, Uber. **Core topics:** partitioning with consistent hashing, eviction, replication, cache patterns, hot keys, consistency with the database.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Build the cache itself, or use one in front of a DB? | Build the cache service (Memcached/Redis-like); explain how clients use it. |
| Operations? | `get`, `set` with optional TTL, `delete`. No complex data types. |
| Data size? | ~10 TB of hot data in total. |
| Traffic? | ~10 M ops/s, 90% reads. |
| Latency? | p99 below ~1 ms inside the data center. |
| Durability? | Not required: it is a cache, the DB is the source of truth. Losing a node means misses, not data loss. |
| Consistency? | Eventual is acceptable; stale reads for a short TTL are tolerated. |

## 2. Requirements

**Functional:** `get(key)`, `set(key, value, ttl?)`, `delete(key)`; entries expire; when memory is full, evict (LRU).

**Non-functional:**

- Sub-millisecond latency (everything in RAM, one network hop).
- Horizontal scale: add nodes to add memory and throughput.
- High availability: a node failure must not take the cache down, and must not move most keys.
- Even load across nodes, including for hot keys.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Memory | 10 TB data + ~30% overhead (pointers, metadata, fragmentation) | **~13 TB** |
| Nodes for memory | 13 TB / 64 GB usable per node | **~200 nodes** |
| Throughput per node | a well-tuned in-memory node: ~100K-200K ops/s | 10 M / 200 nodes = **50K ops/s per node**, comfortable |
| Network per node | 50K ops x ~1 KB average value | **~50 MB/s**, fine on a 10 Gbps NIC |
| With 1 replica each | x2 | **~400 nodes** |

Memory, not CPU, decides the node count. That is typical for caches.

## 4. API

```text
get(key) -> value | miss
set(key, value, ttlSeconds?) -> ok
delete(key) -> ok
(optional) mget(keys...), incr(key), cas(key, value, version)
```

Wire protocol: a compact binary or text protocol over long-lived TCP connections (Memcached text protocol, Redis RESP). Not HTTP: the per-request overhead matters at sub-millisecond targets.

## 5. Architecture

```text
   app servers (cache client library: hash ring + connection pools)
      |         |          |
      v         v          v
  +--------+ +--------+ +--------+        each node: hash table + LRU list + TTL
  | node A | | node B | | node C |  ...   in RAM, single-threaded event loop or striped locks
  +--------+ +--------+ +--------+
      |  async replication   |
  +--------+ +--------+ +--------+
  |replicaA| |replicaB| |replicaC|
  +--------+ +--------+ +--------+

  config service (ZooKeeper / etcd): ring membership, node health, primary/replica roles
```

**Where does routing happen?**

| Option | How | Trade-off |
|---|---|---|
| Client-side (recommended) | the client library holds the ring and talks to the node directly | one hop, fastest; every client must get membership updates |
| Proxy (twemproxy, mcrouter, Envoy) | clients talk to a proxy that routes | simpler clients, one extra hop |
| Server-side redirect (Redis Cluster) | any node answers `MOVED` with the right node | clients cache the slot map; redirects on topology change |

## 6. Deep dive: partitioning with consistent hashing

Naive `hash(key) % N` remaps almost every key when N changes (adding one node to 100 moves ~99% of keys), which empties the cache and stampedes the DB.

**Consistent hashing:** place nodes on a ring of hash values; a key belongs to the first node clockwise from `hash(key)`. Adding or removing a node only moves the keys in its arc: about `1/N` of keys.

**Virtual nodes:** each physical node is placed at many points (100-200) on the ring. This evens out arc sizes (without them, load can differ by several times), and when a node dies its keys spread over many nodes instead of all landing on one neighbor. Weights are easy: a bigger machine gets more virtual nodes.

Redis Cluster uses a variant: 16,384 fixed **hash slots** (`CRC16(key) % 16384`) assigned to nodes; rebalancing moves whole slots.

## 7. Deep dive: inside a node

- **Hash table** for O(1) lookup, plus a **doubly linked list** in recency order for O(1) LRU eviction (see LLD).
- **TTL:** lazy expiry (check on read) plus a periodic sampler that deletes some expired keys (Redis samples 20 keys at a time). Never scan everything.
- **Eviction policy** when memory hits the limit: LRU (default), LFU (better for skewed, stable popularity), or random. Approximate LRU (sample 5 keys, evict the oldest) avoids the list's memory cost; Redis does this.
- **Memory allocator:** slab allocation (Memcached) to avoid fragmentation.
- **Threading:** a single-threaded event loop (Redis) avoids locks entirely; multi-threaded designs (Memcached) use striped locks.

## 8. Deep dive: replication and failure

- Each primary streams writes asynchronously to 1-2 replicas. Async because the cache is not the source of truth; sync replication would add latency for little benefit.
- **Failure detection:** heartbeats to the config service (or gossip between nodes). On primary failure, promote a replica and update the ring.
- Writes acknowledged by the old primary but not yet replicated are lost. Acceptable for a cache; state it.
- **Split brain:** use the config service's consensus (a quorum) to decide who is primary; fence the old primary with an epoch number.

## 9. Deep dive: how applications use the cache

| Pattern | Read | Write | Notes |
|---|---|---|---|
| **Cache-aside** (most common) | app reads cache; on miss reads DB and fills cache | app writes DB, then **deletes** the cache key | simple; brief staleness possible |
| Read-through | cache library loads from DB on miss | as cache-aside | the cache owns the loading logic |
| Write-through | read cache | write cache and DB synchronously | always fresh; slower writes; caches data nobody reads |
| Write-behind | read cache | write cache, flush to DB asynchronously | fastest writes; data loss risk |

**Delete, do not update, on write.** Two concurrent writers updating the cache can leave it with the older value permanently; deleting forces the next read to load the current value. A remaining race (a slow reader fills the cache with a stale value after the delete) is bounded by the TTL; leases (Facebook's memcache paper) close it.

## 10. Hot keys and stampedes

| Problem | Fix |
|---|---|
| **Hot key** (one celebrity profile gets 1 M reads/s) | replicate the key under several names (`key#1..key#k`, read a random one); or a small local in-process cache on app servers with a ~1 s TTL |
| **Cache stampede** (a hot key expires, thousands of requests hit the DB) | request coalescing / single flight (one loader per key, others wait); a lease or lock per key; refresh early with a randomized probability before expiry |
| **Cold start** after a large failure | warm the cache from a snapshot or replay recent keys; rate-limit DB fallback |
| **Large values** (>1 MB) | split or compress; they block a single-threaded node |
| **Penetration** (many reads for keys that do not exist) | cache negative results briefly; a Bloom filter of existing keys |

## 11. Scaling and failure table

| Event | Effect | Mitigation |
|---|---|---|
| Add a node | ~1/N keys move (become misses) | virtual nodes; add nodes gradually |
| Node dies | its keys miss until the replica is promoted | replica promotion in seconds; DB must absorb the miss burst |
| Network partition | clients may see different rings | config service is the single source of membership |
| Multi-region | each region has its own cache | invalidate across regions by publishing DB change events (CDC) |

## 12. What interviewers look for

- Consistent hashing with virtual nodes, and why `% N` fails.
- O(1) LRU (hash map + doubly linked list).
- A clear cache pattern (cache-aside with delete-on-write) and its staleness window.
- Hot keys and stampedes with concrete fixes.
- Accepting data loss explicitly because the cache is not the source of truth.

## 13. Common mistakes

- Modulo hashing.
- Updating the cache on write instead of deleting (race leaves stale data).
- No TTL at all: one missed invalidation leaves stale data forever.
- Treating the cache as durable storage.
- Synchronous replication "for safety" without asking whether the data needs it.

## 14. Follow-ups

1. **Strong consistency for some keys.** Route through a single primary and invalidate synchronously, or skip caching them.
2. **Cache sizing:** measure the hit ratio vs memory curve; the working set usually follows a power law.
3. **Persistence (Redis AOF/RDB):** faster warm restarts, not durability guarantees.
4. **Rebalancing without a miss storm:** copy keys to the new node before switching ownership (Redis slot migration).

See [LLD.md](LLD.md) for an O(1) LRU cache with TTL and a consistent hash ring with virtual nodes.
