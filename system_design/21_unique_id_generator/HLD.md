# Distributed Unique ID Generator (Snowflake): High-Level Design

**Asked at:** Twitter/X, Amazon, Google, Uber, Instagram, Discord. **Core topics:** uniqueness without coordination, time-sortable IDs, bit layout trade-offs, clock skew, assigning worker IDs, capacity per node.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Format? | 64-bit integer (fits a database `BIGINT` and is cheap to index). |
| Sortable? | Roughly by creation time (newer IDs are larger), so they work as primary keys and for pagination. |
| Throughput? | 10K+ IDs/s per node; ~1 M/s cluster-wide. |
| Strictly sequential (no gaps)? | No: gaps are fine. Strictly increasing per generator; only roughly ordered across generators. |
| Guessable? | Not a security token; IDs may reveal creation time. |
| Availability? | Generating an ID must not depend on a remote call in the hot path. |

## 2. Requirements

**Functional:** `nextId()` returns a unique 64-bit ID; IDs decode to (timestamp, worker, sequence).

**Non-functional:** globally unique across all nodes forever (within the epoch), low latency (local, no network), high availability, time-ordered, compact.

## 3. Options

| Approach | How | Pros | Cons |
|---|---|---|---|
| UUID v4 | 122 random bits | no coordination | 128 bits; random order fragments B-tree indexes; not sortable |
| UUID v7 / ULID | 48-bit ms timestamp + random bits | sortable, no coordination | 128 bits |
| Database auto-increment | one counter in one DB | simple, dense | single point of failure and bottleneck |
| Multi-master auto-increment | N databases, step N (`id = k, k+N, k+2N`) | no single point | adding nodes changes the step; not time-ordered across nodes |
| Ticket server / range allocation (Flickr) | a central service hands out blocks of IDs | dense IDs, cheap per ID | central dependency for block refills; not time-ordered |
| **Snowflake** | timestamp + worker ID + sequence in 64 bits | sortable, 64-bit, no coordination per ID | needs unique worker IDs and sane clocks |

## 4. Snowflake layout

```text
 0 | 41 bits: ms since custom epoch | 10 bits: worker ID | 12 bits: sequence
 ^ sign bit kept 0 so IDs are positive signed integers

 41 bits of ms  = 2^41 ms ≈ 69.7 years from the chosen epoch
 10 bits worker = 1,024 generators (often split: 5 bits datacenter + 5 bits machine)
 12 bits seq    = 4,096 IDs per ms per worker = ~4 M IDs/s per worker
```

Trade-offs are adjustable: fewer worker bits, more sequence bits, or a coarser time unit (10 ms, as Sonyflake does) for a longer lifetime.

## 5. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Per worker | 4,096 per ms | **~4 M IDs/s** |
| Cluster | 1,024 workers | **~4 B IDs/s** theoretical |
| Lifetime | 2^41 ms | **~69 years** from the epoch |

## 6. Deep dive: assigning worker IDs

Two generators with the same worker ID can produce duplicates. Options:

- Static configuration per host (simple, error-prone at scale).
- **Lease from a coordination service** (ZooKeeper/etcd): on startup, a node claims a free worker ID with a lease and renews it; if it cannot renew, it stops generating. A crashed node's ID becomes free only after its lease expires.
- Derive from something unique (Kubernetes StatefulSet ordinal, last bits of a private IP) when the address space allows.

## 7. Deep dive: clocks

- **Clock goes backwards** (NTP step adjustment, VM migration): the generator remembers the last timestamp it used. If the clock is behind by a few ms, wait until it catches up; if far behind, refuse (and alert) rather than risk duplicates.
- **Sequence exhausted within one ms:** wait for the next millisecond.
- Use a monotonic time source where possible, and slew (not step) NTP corrections.

## 8. Architecture

```text
 app instance --(in-process library, no network per ID)--> Snowflake generator(workerId)
                                                     ^
                     on startup / every few seconds  | lease renewal
                                         coordination service (etcd/ZooKeeper): workerId -> lease
 Alternative: a small ID service cluster (each node a generator) behind a load balancer, for languages
 where embedding the library is awkward; adds a network hop.
```

## 9. Failure modes

| Failure | Behavior |
|---|---|
| Coordination service down | Running generators keep their lease until expiry; new nodes cannot start generating. |
| Lease lost (network partition) | Generator stops issuing IDs; another node may take the worker ID after expiry. |
| Clock jumps back far | Generator refuses and alerts; the app retries on another instance. |
| Epoch exhaustion | Decades away; pick the epoch at launch time, not 1970. |

## 10. What interviewers look for

- Comparing several approaches, then choosing with reasons.
- The bit layout and the arithmetic behind it.
- Worker ID uniqueness and clock-skew handling.

## 11. Common mistakes

- Using `currentTimeMillis` since 1970 with 41 bits (only until 2039).
- Ignoring clock rollback.
- Hard-coded worker IDs copied across containers.
- Claiming strict global ordering across workers (only per worker; across workers order is approximate).

## 12. Follow-ups

1. **Shorter public IDs:** encode in base62, or map through a reversible permutation to hide volume and creation time.
2. **IDs embedding the shard:** Instagram put the logical shard ID in the bits to route by ID.
3. **Strictly sequential, gap-free numbers** (invoices): a transactional counter per scope, not Snowflake.

See [LLD.md](LLD.md) for a configurable Snowflake generator, clock rollback handling, a range allocator and worker-ID leases.
