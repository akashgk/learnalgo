# Distributed Lock Service (Chubby / ZooKeeper / etcd locks): High-Level Design

**Asked at:** Google, Amazon, Microsoft, Uber, Databricks, Confluent. **Core topics:** why locks across machines need consensus, leases instead of forever-locks, fencing tokens (the GC-pause problem), fair waiting queues and watches, Redlock's pitfalls, and when not to use a lock at all.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| What is locked? | Coarse-grained resources: leader election for a service, "only one job processes partition 7", schema migrations. Not per-request fine-grained locking. |
| Clients? | Thousands of service instances. |
| Correctness? | **Safety first:** two clients must never both believe they hold the lock in a way that corrupts data. |
| Failures? | Clients crash, pause (GC, VM migration), or get partitioned; lock servers fail. |
| Latency? | Milliseconds to tens of milliseconds per acquire: fine for coarse locks. |

## 2. Requirements

**Functional:** acquire (blocking or try), release, lease renewal (keep-alive), lock expiry when a holder dies, fair ordering of waiters, notifications when a lock frees up.

**Non-functional:** strong consistency (linearizable lock state), high availability (survives minority server failures), no split brain.

## 3. Why consensus

A lock service on one server is a single point of failure; naive replication (async primary/backup) can grant the same lock twice during failover. Lock state must live in a **replicated state machine** (Raft/Paxos) so a majority agrees on every grant: etcd, ZooKeeper (ZAB), Chubby (Paxos). A 5-node cluster tolerates 2 failures.

## 4. Architecture

```text
 clients (lock library) --session/keep-alive--> lock service cluster (5 nodes, Raft leader + followers)
                                                 state: lock name -> holder session, lease expiry,
                                                        fencing token (monotonic revision), wait queue
                         <--watch notifications-- (lock released / expired -> next waiter)
 protected resource (database, storage) --checks fencing token on every write--
```

## 5. Deep dive: leases

- A lock is held under a **lease** (TTL). The client renews it periodically; if the client dies or is partitioned, renewals stop and the lock expires automatically.
- Expiry is measured by the server (the client's clock is untrusted). The client should stop acting as holder slightly before its local view of the lease ends.

## 6. Deep dive: fencing tokens

The classic failure: client A acquires the lock, then pauses for 30 s (GC, VM freeze). Its lease expires; client B acquires the lock and writes. A wakes up, still believing it holds the lock, and writes too: **corruption**, even though the lock service behaved perfectly.

Fix: every grant returns a **fencing token**, a number that increases with every grant (etcd's revision, ZooKeeper's zxid). The protected resource remembers the highest token it has seen and **rejects writes with an older token**. A's late write carries token 33, B already wrote with 34, so A's write is refused.

Leases alone cannot prevent this; only the resource can, using tokens.

## 7. Deep dive: waiting and fairness

- **Herd effect:** if 1,000 clients all watch the lock and retry when it frees, they stampede the service.
- ZooKeeper recipe: each waiter creates a **sequential ephemeral node**; each waiter watches only the node just before it. When the holder releases, exactly one waiter is notified (FIFO fairness, no herd).

## 8. Deep dive: Redlock and alternatives

- Redis `SET key value NX PX ttl` is a fine *efficiency* lock (avoid duplicate work occasionally) on one instance.
- **Redlock** (majority of independent Redis nodes) depends on timing assumptions (bounded clock drift, bounded pauses) and provides no fencing token; it is controversial for correctness-critical locks. Use a consensus system plus fencing when correctness matters.
- Often the best answer is **no lock**: idempotent operations, conditional writes (compare-and-set on the resource itself), or partition ownership with leases (see 19).

## 9. Failure modes

| Failure | Behavior |
|---|---|
| Holder crashes | Lease expires; next waiter is granted with a higher token. |
| Holder paused past its lease | Another client gets the lock; fencing rejects the paused client's late writes. |
| Lock server leader fails | Raft elects a new leader; sessions survive if within the grace period. |
| Network partition | Minority side cannot grant or renew (no quorum); clients there lose their locks after expiry. |

## 10. What interviewers look for

- Consensus-backed state, not a single Redis node, for correctness-critical locks.
- Leases with renewal; expiry on the server's clock.
- Fencing tokens and the GC-pause scenario.
- Fair queues without thundering herds.

## 11. Common mistakes

- Locks with no expiry (a crashed holder blocks everyone forever).
- Trusting the lease alone for safety.
- Fine-grained, high-frequency locking through a remote service.
- Releasing a lock you no longer own (must check the owner).

## 12. Follow-ups

1. **Leader election:** "hold the lock = be the leader"; followers watch the lock.
2. **Read/write locks:** shared and exclusive modes with sequential nodes.
3. **Lock granularity:** hierarchical names (`/db/table/row`) and lock ordering to avoid deadlocks.

See [LLD.md](LLD.md) for leases, renewal, owner-checked release, a FIFO wait queue with notifications, monotonic fencing tokens and a fenced resource that rejects the paused client.
