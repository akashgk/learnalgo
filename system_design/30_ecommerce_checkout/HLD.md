# E-Commerce Checkout (Amazon cart, inventory and orders): High-Level Design

**Asked at:** Amazon, Shopify, Walmart, Flipkart, eBay, Zalando. **Core topics:** microservices for cart, inventory, orders, payments and shipping; the **saga pattern** for a transaction spanning services (no distributed locks, no 2PC); inventory reservation; idempotency; flash-sale contention; the order state machine.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Scope? | Cart -> checkout -> order -> payment -> fulfillment handoff. Catalog, search and recommendations are separate systems. |
| Scale? | 50 M orders/day at peak season; flash sales with 100K buyers for 1,000 units. |
| Inventory? | Multiple warehouses; never sell stock that does not exist (or explicitly allow backorders). |
| Payment? | External PSP (see 14). |
| Consistency? | An order is either fully placed (stock reserved, payment captured) or cleanly cancelled; no lost money, no phantom stock. |

## 2. Requirements

**Functional:** add/remove cart items; checkout with address, coupons and payment; reserve stock; charge; create shipment; order history; cancellations and refunds.

**Non-functional:** cart and browse highly available; checkout correct (consistency) and idempotent; handles traffic spikes; services independently deployable and scalable.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Orders | 50 M/day | **~600/s** avg, several thousand/s at peak |
| Cart operations | ~10x orders | **~6K/s** |
| Flash sale | 100K requests in seconds for 1,000 units | contention on a handful of inventory rows |

## 4. Architecture

```text
 client --> API gateway --> Cart service (Redis/DynamoDB, per user; available, eventually consistent)
                        --> Checkout / Order service (saga orchestrator, order DB + saga log + outbox)
                                 |  1. reserve stock        --> Inventory service (per-SKU counters by warehouse)
                                 |  2. authorize/charge     --> Payment service --> PSP
                                 |  3. create shipment      --> Fulfillment service --> warehouse
                                 |  4. mark order confirmed
                                 |  on failure: run compensations in reverse (release stock, refund)
                                 v
                           Kafka events (OrderPlaced, OrderCancelled) --> email, analytics, recommendations
```

## 5. Deep dive: why a saga

A checkout touches four services with four databases. Options:

| Approach | Problem |
|---|---|
| One database transaction | services do not share a database |
| Two-phase commit | blocking, needs every service and the PSP to support it; the PSP will not |
| **Saga** | a sequence of local transactions; each has a **compensating action**; on failure, undo completed steps in reverse order |

- **Orchestration** (a central checkout service drives the steps, used here) is easier to reason about than **choreography** (services react to each other's events) for a fixed, critical flow.
- A **saga log** (persisted step state) lets a crashed orchestrator resume: completed steps are skipped, in-progress steps retried. Every step and compensation must be **idempotent** (keyed by order ID), because retries happen.
- Sagas give atomicity eventually, not isolation: between steps, other requests can see intermediate state (e.g. stock reserved for an order that will be cancelled). Design for it (reserved stock is not "sold").

## 6. Deep dive: inventory under contention

- **Reserve, then commit:** checkout reserves units with a TTL (e.g. 15 minutes); payment success commits them; failure or expiry releases them.
- Atomic conditional decrement: `UPDATE inventory SET available = available - :n WHERE sku = ? AND available >= :n`.
- **Flash sales:** pre-load the stock count into Redis and decrement atomically there (`DECRBY` with a Lua check), queue the winners for the real order flow; a virtual waiting room in front (see 09).

## 7. Deep dive: idempotency and the order state machine

```text
 PENDING --stock reserved--> RESERVED --paid--> PAID --shipment created--> CONFIRMED --> SHIPPED --> DELIVERED
    \                            \                 \
     +--> FAILED (no stock)       +--> CANCELLED (payment failed: stock released)
                                                    +--> CANCELLED (shipping failed: refund + release)
```

- The client sends a checkout idempotency key; double-clicking "Place order" creates one order.
- Each downstream call carries the order ID as its idempotency key (PSP charge, inventory reservation).
- Events are published through the **transactional outbox** (see 14) so "order confirmed" is never emitted for an order that was rolled back.

## 8. Failure modes

| Failure | Behavior |
|---|---|
| Payment declined | Compensate: release stock; order CANCELLED; user notified. |
| Orchestrator crash mid-saga | On restart, read the saga log and resume (idempotent steps). |
| Inventory service down | Checkout fails fast before charging. |
| Payment timeout (unknown) | Query the PSP by order ID before deciding (see 14). |
| Reservation expires during slow payment | Payment window longer than PSP timeout; if stock is lost, refund. |

## 9. What interviewers look for

- Recognizing a distributed transaction and choosing a saga with compensations.
- Idempotency at every step; a persisted saga log for recovery.
- Inventory reservation with atomic conditional updates and expiry.
- A clear order state machine.

## 10. Common mistakes

- Charging before reserving stock (then refunding when stock is gone).
- Distributed locks across services for the whole checkout.
- Assuming 2PC with external payment providers.
- Non-idempotent compensations (refunding twice).

## 11. Follow-ups

1. **Split shipments** across warehouses: per-warehouse reservations and partial fulfillment.
2. **Price changes between cart and checkout:** reprice at checkout; show the difference.
3. **Returns:** reverse saga (receive item, refund, restock).
4. **Guest checkout and saved carts:** cart merging on login.

See [LLD.md](LLD.md) for the cart and pricing, inventory reservations with expiry, a saga orchestrator with compensations and a resumable saga log, and idempotent steps.
