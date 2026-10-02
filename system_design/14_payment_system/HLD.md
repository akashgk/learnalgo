# Payment System (Stripe / PayPal checkout backend): High-Level Design

**Asked at:** Stripe, PayPal, Amazon, Uber, Airbnb, Coinbase, banks. **Core topics:** exactly-once effects with idempotency keys, double-entry ledgers, payment state machines, integrating unreliable external processors (PSPs), reconciliation, consistency over availability.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Whose payments? | An e-commerce platform charging buyers and paying out to sellers (pay-in and pay-out). |
| Card processing ourselves? | No: we integrate with payment service providers (PSPs: Stripe, Adyen) and never store raw card numbers (tokens only, PCI scope reduced). |
| Scale? | 10 M payments/day. |
| Features? | Authorize + capture, refunds, seller balances and payouts, multiple currencies (amounts kept per currency). |
| Correctness? | Never charge twice; never lose money; every cent accounted for. Correctness beats latency and availability. |

## 2. Requirements

**Functional:** create a payment for an order; charge via a PSP; record results; refund; maintain wallet balances; pay out sellers; reconcile against PSP and bank reports.

**Non-functional:**

- **Exactly-once effects** despite retries, timeouts and crashes.
- **Auditability:** immutable history of every money movement.
- **Strong consistency** for balances.
- **Fault tolerance** against PSP outages and ambiguous responses.
- Security: tokenization, encryption, least privilege.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Payments | 10 M / 86,400 | **~120/s** avg, ~1K/s peak (sales events) |
| Ledger entries | ~4-6 per payment (charge, fees, seller credit, refunds) | **~50 M rows/day**, ~18 B/year |
| Storage | 50 M x ~200 B | **~10 GB/day** |

Throughput is modest. The challenge is correctness under partial failure, not scale.

## 4. API

```text
POST /payments   Idempotency-Key: <uuid>
     { orderId, amount: 4999, currency: "USD", paymentMethodToken, sellerId }
     -> 201 { paymentId, status }       (same key + same body -> same response; same key + different body -> 422)
POST /payments/{id}/capture | /refunds { amount }      (each with its own idempotency key)
GET  /payments/{id}
POST /webhooks/psp      (PSP notifies final results asynchronously; verify signatures)
```

## 5. Data model

```text
idempotency_keys(key PK, request_hash, response, status, created_at)    -- stored for ~24 h+
payments(id, order_id UNIQUE, amount, currency, status, psp_reference, version, ...)
payment_events(payment_id, seq, from_status, to_status, details, ts)    -- append-only
ledger_entries(id, transaction_id, account_id, amount (+/-), currency, ts)  -- append-only, double-entry
accounts(id, type: buyer_funding | seller_balance | platform_fees | psp_clearing | ...)
balances(account_id, currency, amount, version)                         -- derived; can be rebuilt from the ledger
outbox(id, event, payload, published)                                    -- for reliable event publishing
```

Relational database with ACID transactions (PostgreSQL), sharded by merchant or account if needed. Money stored as **integer minor units** (cents) with a currency code, never floating point.

## 6. Architecture

```text
 checkout --> Payment API (idempotency layer) --> Payment service (state machine) --> PSP adapter --> PSP
                                                       |          ^                       |
                                                       |          +---- webhooks ----------+
                                                       v
                                         Ledger service (double-entry, append-only)
                                                       |
                                       outbox --> Kafka --> order service, notifications, analytics
                                                       |
                         Reconciliation job: daily PSP settlement files + bank statements vs ledger
                         Payout service: seller balances -> bank transfers (batched)
```

## 7. Deep dive: idempotency (exactly-once effects)

Networks fail between "PSP charged the card" and "we recorded it". Exactly-once delivery is impossible; exactly-once **effects** come from idempotency at every hop:

1. **Client -> us:** the `Idempotency-Key` header. In one transaction: insert the key (unique) with status `in_progress`; if it already exists, return the stored response (or 409 while still in progress). Same key with a different request body is an error.
2. **Us -> PSP:** pass our payment ID as the PSP's idempotency key, so our own retries do not double charge.
3. **Webhooks -> us:** deduplicate by PSP event ID; state transitions are conditional, so a repeated "succeeded" is a no-op.

## 8. Deep dive: payment state machine

```text
 created --> authorizing --> authorized --> capturing --> captured --> (partially_)refunded
                 |                |                                         
                 +--> failed      +--> voided (cancel before capture)
                 +--> unknown (timeout) --query PSP / wait for webhook--> authorized | failed
```

- Each transition is a conditional update (`WHERE id = ? AND status = ?` or a version check) plus an appended event.
- **Unknown is a real state.** On a timeout, never assume failure and retry blindly with a new key, and never assume success. Query the PSP with the same idempotency key, or wait for the webhook.

## 9. Deep dive: double-entry ledger

Every money movement is a **transaction** of entries that **sum to zero** per currency:

```text
Buyer pays $49.99, platform fee 10%:
  psp_clearing       +4999      (money the PSP owes us)
  seller_balance     -4499      (we owe the seller)        signs: a consistent convention, e.g. debit +, credit -
  platform_revenue    -500
  sum = 0
```

- Entries are immutable; corrections are new reversing transactions.
- Balances are derived (sum of entries) and can be cached in a `balances` table updated in the same transaction.
- The zero-sum invariant catches bugs immediately; reconciliation compares `psp_clearing` with what the PSP actually settled.

## 10. Deep dive: reliability patterns

- **Transactional outbox:** write the state change and the event to publish in one DB transaction; a relay publishes outbox rows to Kafka. No "updated DB but failed to send event" gaps.
- **Retries with backoff** only for safe (idempotent) operations; circuit breakers per PSP; failover to a second PSP for new payments (never for an in-flight one).
- **Reconciliation:** daily, match every ledger entry against PSP settlement reports and bank statements; mismatches go to an exception queue for humans. This is how the money ultimately stays correct.
- **Payouts:** batched, with their own idempotency and a hold period for fraud and chargebacks.

## 11. Failure modes

| Failure | Behavior |
|---|---|
| Client retries after timeout | Idempotency key returns the original result. |
| PSP times out | Payment `unknown`; query PSP by our ID; webhook resolves it. |
| Service crashes after PSP success, before DB write | The PSP knows the charge by our idempotency key; the webhook or a query recovers the state; reconciliation is the final net. |
| Duplicate webhooks | Deduplicated by event ID; conditional transitions. |
| Database primary fails | Synchronous replica promotion (no lost committed money movements). |

## 12. What interviewers look for

- Idempotency keys end to end, and why exactly-once delivery is not available.
- A double-entry ledger with immutable entries.
- An explicit state machine with an "unknown" state for timeouts.
- Reconciliation as a first-class component.
- Choosing consistency over availability, and integer money.

## 13. Common mistakes

- Floating-point amounts.
- `UPDATE balance = balance - x` without a ledger.
- Retrying a charge after a timeout with a new idempotency key (double charge).
- Treating webhook order or uniqueness as guaranteed.
- No reconciliation.

## 14. Follow-ups

1. **Multi-currency:** separate balances per currency; FX conversion as an explicit ledger transaction at a recorded rate.
2. **Fraud:** risk scoring before authorization; 3-D Secure challenges.
3. **Chargebacks:** a new state and ledger transactions debiting the seller.
4. **Global scale:** shard ledgers by account; cross-shard transfers via sagas with compensating entries.

See [LLD.md](LLD.md) for idempotency handling, the payment state machine, a double-entry ledger and the PSP adapter with unknown outcomes.
