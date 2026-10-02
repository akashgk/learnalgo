# Expense Sharing (Splitwise): High-Level Design

**Asked at:** Amazon, Flipkart, Microsoft, Uber, Atlassian, Goldman Sachs (very often as an LLD question). **Core topics:** the HLD side is a modest-scale, correctness-heavy service: an immutable ledger of expenses, derived balances, debt simplification, concurrent edits by group members, multi-currency, notifications.

Ask which round this is: the class design (split strategies, balances, simplification) is the usual focus; see [LLD.md](LLD.md).

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Features? | Groups and friends; add expenses with different split types (equal, exact, percentage, shares); see who owes whom; settle up; simplify debts; activity feed; comments. |
| Scale? | 50 M users, 5 M daily active; ~10 M expenses/day. |
| Money movement? | No: the app records debts; settlement happens outside (or through a payment integration as a follow-up). |
| Currencies? | Multiple; balances kept per currency (conversion is a follow-up). |
| Edits? | Expenses can be edited or deleted by group members; history must be kept. |

## 2. Requirements

**Functional:** create groups, add/edit/delete expenses, compute balances per user and per pair, suggest simplified settlements, record payments, notify members.

**Non-functional:** correctness (balances always equal the sum of expenses and payments; never lose an expense), auditability (history of edits), consistency within a group (everyone sees the same balances), moderate latency, high availability for reads.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Expense writes | 10 M / 86,400 | **~120/s** avg, ~1K/s peak (weekend evenings, trips) |
| Reads | ~10x writes (balances, feeds) | **~1-10K/s** |
| Storage | 10 M x ~1 KB (expense + splits + metadata) | **~10 GB/day**, ~3.6 TB/year |

Small scale. The design is about **data modeling and correctness**, not throughput.

## 4. API

```text
POST /groups                              { name, members }
POST /groups/{g}/expenses                 { idempotencyKey, payer(s), amount, currency, split: { type, details }, note }
PUT  /expenses/{id}   { ..., version }    DELETE /expenses/{id}
POST /groups/{g}/payments                 { from, to, amount, currency }        (settle up)
GET  /groups/{g}/balances                 -> net per member, per currency
GET  /groups/{g}/settlements/suggested    -> simplified list of payments
GET  /users/me/balances                   -> across all groups and friends
```

## 5. Data model

```text
users(id, name, default_currency)
groups(id, name, simplify_debts: bool)        group_members(group_id, user_id)
expenses(id, group_id, created_by, amount_minor, currency, split_type, note, version, deleted, created_at)
expense_shares(expense_id, user_id, paid_minor, owed_minor)   -- per participant; sum(paid) = sum(owed) = amount
payments(id, group_id, from_user, to_user, amount_minor, currency)
expense_history(expense_id, version, snapshot, edited_by, ts)  -- audit trail of edits
balances(group_id, user_id, currency, net_minor)               -- derived cache, rebuildable
```

**Balances are derived** from shares and payments. A cache table is updated in the same transaction as the expense, and can always be rebuilt by summing. The invariant `sum(net) = 0` per group and currency is checked.

## 6. Architecture

```text
 mobile/web --> API gateway --> Expense service --(transaction)--> PostgreSQL (sharded by group_id)
                                     |                                 expenses, shares, payments, balances
                                     +--> outbox --> Kafka --> Notification service (push/email)
                                                          --> Activity feed service
                                                          --> Analytics
                Balance service: reads cached balances; computes simplified settlements on demand
```

Sharding by `group_id` keeps every write for a group on one shard: one ACID transaction per expense. "My balances across all groups" is a fan-out read (or a per-user summary table updated asynchronously).

## 7. Deep dives

**Splits and rounding.** All amounts in integer minor units. $100 split three ways is 33.34 + 33.33 + 33.33: the remainder cents are distributed deterministically (for percentages, to the largest fractional parts). The split must sum exactly to the amount, validated on the server.

**Edits and deletes.** An edit is: reverse the old shares' effect on balances, apply the new ones, bump the version, append to history, all in one transaction. Optimistic concurrency (`version`) stops two members from overwriting each other's edit silently.

**Debt simplification.** Only net balances matter. Greedily match the largest creditor with the largest debtor until all are zero: at most n - 1 payments for n people. Finding the absolute minimum number of payments is NP-hard (it is related to partitioning into zero-sum subsets), so the greedy result is what is shown; for small groups an exact search is feasible.

**Multi-currency.** Keep balances per currency. Conversion (if offered) records the rate used at settlement time as its own entry.

**Idempotency.** Mobile clients on bad networks retry: `idempotencyKey` per expense creation.

## 8. Failure modes

| Failure | Behavior |
|---|---|
| Retry after timeout | Idempotency key: no duplicate expense. |
| Concurrent edits | Version conflict returned; client reloads and reapplies. |
| Balance cache drift (bug) | Nightly job recomputes from expenses and payments and alerts on mismatch. |
| Notification service down | Outbox keeps events; delivered later. |

## 9. What interviewers look for

- Integer money and exact split rules, including rounding.
- Balances as derived data with a zero-sum invariant.
- A clear simplification algorithm and honesty about optimality.
- Transactions per group, edit history, idempotency.

## 10. Common mistakes

- Floating-point amounts.
- Storing only balances (no way to explain or edit them).
- Claiming the greedy simplification is optimal.
- Mixing currencies in one balance.

## 11. Follow-ups

1. **Recurring expenses:** a scheduler (see 19) creates them.
2. **Receipt scanning:** OCR into line items; itemized splits.
3. **Payments integration:** "settle up" triggers a real transfer (see 14).
4. **Offline mode:** queue expenses locally with idempotency keys; resolve version conflicts on sync.

See [LLD.md](LLD.md) for split strategies, the balance sheet, settle-up and debt simplification.
