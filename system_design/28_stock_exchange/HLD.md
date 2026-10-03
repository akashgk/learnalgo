# Stock Exchange / Order Matching Engine: High-Level Design

**Asked at:** Coinbase, Robinhood, Citadel, Jane Street, Goldman Sachs, Bloomberg, Amazon. **Core topics:** the order book and price-time priority, a deterministic single-threaded matching engine, sequencing and event sourcing, primary/backup replication by replay, market data distribution, very low latency, risk checks.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Market? | Equities (or crypto) exchange; ~10,000 symbols. |
| Order types? | Limit, market, cancel; immediate-or-cancel (IOC). (Stop orders, modify, auctions as follow-ups.) |
| Volume? | ~1 B orders/day overall, heavily concentrated in a few hundred symbols; peaks of ~1 M orders/s. |
| Latency? | Matching in microseconds; end-to-end (gateway to acknowledgment) in tens of microseconds to low milliseconds. |
| Fairness? | Strict price-time priority; deterministic outcomes. |
| Durability? | No acknowledged order or trade may be lost. |

## 2. Requirements

**Functional:** accept and validate orders, risk-check them, match buy and sell orders, report executions, cancel orders, publish market data (top of book, depth, trades), end-of-day reporting and clearing.

**Non-functional:** extreme low latency and predictable tail latency, determinism (same input order sequence gives the same output), high availability with fast failover and no lost state, fairness.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Orders/s peak | | **~1 M/s** across symbols |
| Per hot symbol | | ~100K orders/s: one core can match millions of simple orders per second in memory |
| Event log | 1 B events x ~100 B | **~100 GB/day** |
| Market data fan-out | thousands of subscribers x every book change | multicast UDP, not TCP per client |

## 4. Architecture

```text
 brokers --FIX/binary over TCP--> Order gateways (auth, validation, throttling)
                                        |
                                 Risk checks (buying power, position limits, fat-finger price bands)
                                        |
                                    Sequencer: assigns a global sequence number to every inbound event,
                                    writes it to the replicated event log (journal)
                                        |
                  Matching engines (one thread per symbol group, in memory, no locks, no I/O in the hot loop)
                                        |  output events: accepted, trades, cancels (also sequenced)
                         +--------------+----------------+
                         v                               v
              Market data publisher (multicast)    Execution reports to brokers via gateways
                                                   Post-trade: clearing, settlement, reporting (async)
 Backup engine: consumes the same sequenced log and holds identical state; takes over on failure.
```

## 5. Deep dive: the order book

- Two sides: **bids** (buy orders, best = highest price) and **asks** (sell orders, best = lowest price).
- Each side is a sorted map of **price levels**; each level is a **FIFO queue** of orders (time priority).
- An incoming buy limit order at price P matches against asks while the best ask ≤ P, oldest order first at each level; any remainder rests on the bid side.
- Market orders take liquidity at any price (sweeping levels); IOC orders never rest.
- **Cancel** needs O(1) lookup: a map order ID -> (side, level, position).

## 6. Deep dive: determinism, sequencing and replication

- The matching engine is a **pure state machine**: state' = f(state, event). A single thread per symbol (or symbol group) means no locks and no nondeterminism.
- The **sequencer** gives every event a total order and persists it before it reaches the engine. The **event log is the source of truth** (event sourcing).
- **Recovery and replication:** a backup engine replays the same log and is always in the same state; failover is switching which engine's output is published. Snapshots bound replay time.
- Latency techniques: kernel bypass networking, pinned cores, preallocated memory (no garbage collection pauses), batching log writes, binary protocols (LMAX Disruptor-style ring buffers).

## 7. Deep dive: market data

- Level 1 (best bid/ask), Level 2 (depth per price), trade prints.
- Published over **multicast** with sequence numbers; receivers detect gaps and recover from a snapshot/retransmission service.
- Every subscriber must receive data at the same time (fairness): no per-client queues in the hot path.

## 8. Failure modes

| Failure | Behavior |
|---|---|
| Matching engine crash | Backup (already caught up from the log) takes over; in-flight events replayed. |
| Sequencer failure | Replicated sequencer (consensus or primary/backup with a fencing epoch). |
| Gateway failure | Brokers reconnect to another gateway; order IDs dedupe resends. |
| Market data packet loss | Gap detection and retransmission by sequence number. |

## 9. What interviewers look for

- The order book data structure and price-time priority.
- Single-threaded deterministic matching with a sequenced, replicated event log.
- How state survives failures (replay, snapshots, hot backup).
- Separating the latency-critical path from post-trade processing.

## 10. Common mistakes

- Storing the order book in a database and matching with SQL.
- Multi-threaded matching on one symbol with locks (nondeterministic, slower).
- Acknowledging orders before they are durably sequenced.
- Per-subscriber TCP fan-out for market data at scale.

## 11. Follow-ups

1. **Stop orders:** a separate book triggered by trade prices.
2. **Opening/closing auctions:** collect orders, compute a single clearing price maximizing volume.
3. **Self-trade prevention:** reject or cancel when both sides belong to the same account.
4. **Crypto exchange custody:** wallets and ledger (see 14).

See [LLD.md](LLD.md) for the order book with price levels, limit/market/IOC orders, partial fills, cancels, and deterministic replay from an event log.
