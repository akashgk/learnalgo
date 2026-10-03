# Vending Machine: High-Level Design

**Asked at:** Amazon, Microsoft, Uber, Goldman Sachs, Adobe (almost always as an LLD / State-pattern question). **Core topics:** the HLD version is a fleet of connected machines: telemetry, remote pricing and planograms, cashless payments, restock routing, and offline operation.

Ask which round this is; the class design in [LLD.md](LLD.md) is what most interviewers want.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Fleet? | 50,000 machines (snacks, drinks) across offices, stations, campuses. |
| Payments? | Coins and notes, plus cards/phones (contactless). |
| Connectivity? | Cellular, intermittent; machines must sell offline. |
| Operations? | Track stock per slot, plan restock routes, update prices remotely, detect faults (jams, coin mechanism full). |

## 2. Requirements

**Functional:** sell products with cash or card; give change; report sales, stock, cash levels and faults; accept remote price and planogram (slot -> product) updates; support restock visits.

**Non-functional:** works offline (sales never blocked by the network), reliable reconciliation of sales and cash, secure payments, low-cost hardware and data usage.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Sales | 50,000 machines x 50 sales/day | **2.5 M sales/day** (~30/s) |
| Telemetry | 1 batched report per machine per 15 minutes + events | **~5K messages/minute** |
| Data | tiny | cost of cellular data dominates design (batch and compress) |

## 4. Architecture

```text
 machine controller (state machine, local DB of stock, prices, sales journal)
   |-- coin/note acceptor, change dispenser, card reader (payment terminal with its own secure link)
   |-- MQTT over cellular: batched sales, stock, cash, faults (store-and-forward when offline)
   v
 IoT gateway --> Kafka --> fleet service (machine registry, planograms, prices, firmware)
                       --> analytics (sales per product/location), anomaly detection (no sales = fault?)
                       --> restock planner (predict depletion per slot -> daily routes for drivers)
 operations app (drivers): restock, collect cash, record counts --> reconciliation with machine journals
```

## 5. Deep dive: offline-first

- The machine is the source of truth for its own sales; it journals every sale locally and syncs when connected (idempotent by machine ID + sequence number).
- Price and planogram updates are versioned commands pulled by the machine; it applies them between sales.
- Card payments: the payment terminal handles authorization (online when possible; offline with small limits, depending on the payment scheme).

## 6. Deep dive: restocking

- Stock per slot from sales telemetry; predict when each slot runs out; schedule routes when a machine's expected lost sales exceed the visit cost.
- Drivers' counts reconcile against the machine's journal; differences flag theft or faults.

## 7. Failure modes

| Failure | Behavior |
|---|---|
| Network down | Sell normally; queue telemetry. |
| Product jam | Refund automatically (drop sensor did not detect a product); mark slot faulty. |
| Change tubes low | Switch to "exact change only" for cash payments. |
| Coin box full | Stop accepting coins; alert operations. |

## 8. What interviewers look for

- (HLD) Edge-first design with store-and-forward telemetry and versioned remote configuration.
- (LLD) A clean state machine, money handling in integer cents, change-making with limited coins, refunds on failure.

## 9. Common mistakes

- Requiring the cloud to approve each cash sale.
- Floating-point money.
- Accepting money for a product that cannot be vended (sold out, no change).

## 10. Follow-ups

1. **Dynamic pricing** by time of day.
2. **Loyalty / app ordering:** reserve and pick up with a code.
3. **Fleet firmware updates:** staged rollouts with rollback.

See [LLD.md](LLD.md) for the State pattern implementation with coins, selection, change-making with limited coins, exact-change mode, cancellation, sold-out handling and jams.
