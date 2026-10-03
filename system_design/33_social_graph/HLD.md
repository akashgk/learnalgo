# Social Graph (LinkedIn connections, Facebook friends, "People You May Know"): High-Level Design

**Asked at:** LinkedIn, Meta, Twitter/X, Snap, Pinterest. **Core topics:** storing a huge graph (adjacency lists, TAO-style caches), degree-of-connection queries (bidirectional BFS), mutual connections, friend recommendations, super-nodes, sharding a graph.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Edge type? | Undirected connections (LinkedIn/Facebook friends). Follows (directed) as a variant. |
| Scale? | 1 B users; average 300 connections; max 30,000 (LinkedIn's cap) for connections; followers unbounded. |
| Queries? | Are A and B connected? Degree of connection (1st, 2nd, 3rd+) shown on every profile view; mutual connections; People You May Know (PYMK). |
| Latency? | Degree badge on a profile: < 50 ms. PYMK: precomputed, can be hours stale. |
| Writes? | Connect, remove, block: low rate compared to reads. |

## 2. Requirements

**Functional:** add/remove connections (with requests/acceptance), list connections, degree up to 3, mutual connections, PYMK, blocking.

**Non-functional:** read-heavy, low latency, highly available, eventually consistent for derived data (PYMK, counts).

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Edges | 1 B users x 300 / 2 | **150 B undirected edges** (300 B adjacency entries) |
| Adjacency storage | 300 B x 8 B | **~2.4 TB** of IDs (plus metadata), sharded across many machines; hot part in cache |
| Profile views needing a degree | ~10 B/day | **~115K degree queries/s** |
| 2nd-degree neighborhood | 300 x 300 = 90K users (with overlap) | too large to compute naively per request |

## 4. Data model and storage

```text
edges(user_id, friend_id, created_at, state)      -- both directions stored: (A,B) and (B,A)
      partitioned by user_id -> one partition read returns a user's whole adjacency list
cache: user_id -> sorted friend list (memcache / TAO-style write-through cache)
```

Store each undirected edge twice so "list A's connections" is a single-partition read. A graph database is optional; most large social networks use sharded key-value/MySQL plus a graph-aware caching layer (Facebook TAO).

## 5. Deep dive: degree of connection

- 1st degree: a membership check in A's list (sorted list or hash set).
- 2nd degree: do A's and B's friend lists intersect? Intersect two sorted lists of ~300: microseconds. No BFS needed.
- 3rd degree: is there an edge between A's friends and B's friends? **Bidirectional BFS**: expand one level from each side and check for overlap. Each side touches ~300 lists; that is ~600 adjacency fetches instead of 300^3 for a one-sided BFS.
- Production systems often cache each user's 2nd-degree network (as a compressed bitmap) for fast degree badges.

## 6. Deep dive: People You May Know

- Candidates: friends of friends (2nd degree), ranked by the number of mutual connections, plus signals (same company, school, imported contacts, profile views).
- Computed offline (Spark / graph processing) daily for every user, stored per user, refreshed incrementally on new connections; served from a KV store.
- Exclude existing connections, pending invitations, blocked users, and recently dismissed suggestions.

## 7. Deep dive: super-nodes and sharding

- A user with millions of followers makes adjacency lists huge: paginate lists, cap expansions in BFS (skip or sample super-nodes), keep separate follower storage.
- **Sharding by user ID** keeps a user's list together, but traversals cross shards constantly. Graph partitioning (placing friends on the same shard) reduces cross-shard calls but is hard to maintain; most systems accept cross-shard fetches and rely on caching and batching (fetch many adjacency lists in one round trip per shard).

## 8. Architecture

```text
 clients --> API --> Graph service --> cache (adjacency lists) --miss--> edge store (sharded by user)
                         |  degree(A,B): membership -> sorted intersection -> bidirectional expansion
                         |  mutuals(A,B): sorted intersection
                         v
              connection events --> Kafka --> PYMK offline pipeline --> recommendations KV store
                                          --> counters (connection counts), notifications
```

## 9. Failure modes

| Failure | Behavior |
|---|---|
| Cache cluster loss | Fall back to the edge store with request coalescing; degree badges may degrade to "not shown". |
| Edge write half-applied (one direction) | Write both directions in one transaction per shard pair or via an async repair job that checks symmetry. |
| PYMK pipeline late | Serve yesterday's suggestions. |

## 10. What interviewers look for

- Adjacency lists stored per user (both directions) and cached.
- Degree computation with intersections and bidirectional BFS, with the math showing why one-sided BFS is too expensive.
- PYMK as an offline friends-of-friends ranking.
- Awareness of super-nodes and cross-shard traversal costs.

## 11. Common mistakes

- Running an unbounded BFS per profile view.
- Storing edges once (reads then need two queries or a scan).
- Computing PYMK at request time.

## 12. Follow-ups

1. **Directed follow graph:** separate follower and following lists; fan-out concerns as in 06.
2. **Privacy:** hidden connection lists; blocked users excluded from all traversals.
3. **Graph analytics:** communities, influence (PageRank) offline.

See [LLD.md](LLD.md) for the adjacency-list graph, degree up to 3 with bidirectional BFS (and a count of the work saved), mutual connections, PYMK and blocking.
