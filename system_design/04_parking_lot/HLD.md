# Parking Lot System: High-Level Design

**Asked at:** Amazon, Microsoft, Uber, Goldman Sachs, and most companies with an LLD round. **Core topics:** this is primarily a low-level design question; the HLD version scales it to many garages with gates, live availability, reservations and payments.

Be upfront in the interview: if the interviewer says "design a parking lot", ask whether they want the class design (LLD, most common) or the multi-garage service (HLD). This file covers the HLD; [LLD.md](LLD.md) covers the classes.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| One garage or many? | A company running ~5,000 garages in many cities. |
| Size of a garage? | Up to ~2,000 spots over several levels. |
| Vehicle and spot types? | Motorcycle, car, van/truck; spots: small, compact, large, plus EV-charging and accessible spots. |
| Entry and exit? | Automated gates: ticket or license-plate recognition (LPR) at entry, payment at exit or in the app. |
| Reservations? | Yes, users can reserve a spot type in a garage for a time window. |
| Live availability? | Yes: apps and road signs show free spots per garage and type. |
| Pricing? | Hourly, varies by garage, spot type, time of day; daily maximum. |

## 2. Requirements

**Functional**

1. Entry: issue a ticket (or record the plate), assign or validate a spot, open the gate.
2. Exit: compute the fee, take payment, open the gate.
3. Show live availability per garage and spot type.
4. Reserve a spot type for a time window; honor it at entry.
5. Admin: configure garages, levels, spots, rates.

**Non-functional**

- **Gates must keep working when the network is down.** A car stuck at a gate is the worst failure. This drives the design.
- No double allocation of a spot; no overbooking of reservations beyond capacity.
- Entry/exit decision in under ~1 s.
- Payments are exactly-once (no double charge).

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Spots | 5,000 garages x 1,000 avg | **5 M spots** |
| Parking sessions | ~3 turnovers per spot per day x 5 M | **15 M sessions/day** |
| Gate events | entry + exit per session | 30 M/day ≈ **350/s** avg, ~1,500/s peak |
| Availability reads | apps + signs, ~20x events | **~7K reads/s**, cacheable |
| Storage | 15 M sessions x ~1 KB x 365 | **~5.5 TB/year** of history |

This is a modest-scale system. The hard parts are **correctness** (no double booking) and **offline resilience**, not throughput.

## 4. API

```text
POST /garages/{g}/entries      { plate, gateId, reservationId? }   -> { ticketId, spotId?, level }
POST /garages/{g}/exits        { ticketId | plate, gateId }        -> { amount, paymentStatus }
POST /payments                 { ticketId, method, idempotencyKey } -> { status }
GET  /garages/{g}/availability                                      -> { small: 12, compact: 40, large: 3, ev: 0 }
POST /reservations             { garageId, spotType, from, to }      -> { reservationId, price }
DELETE /reservations/{id}
```

## 5. Data model

```text
garages(id, name, location, timezone)
spots(id, garage_id, level, number, type, features)            -- static config
sessions(ticket_id PK, garage_id, plate, spot_id?, spot_type,
         entry_time, exit_time?, amount?, status)               -- one row per visit
reservations(id PK, garage_id, spot_type, start, end, user_id, status)
reservation_capacity(garage_id, spot_type, time_slot, reserved_count, limit)  -- for overbooking checks
payments(id PK, ticket_id, amount, status, idempotency_key UNIQUE)
rates(garage_id, spot_type, rules_json)
```

A relational database (PostgreSQL) per region fits: modest volume, strong need for transactions (allocation, reservations, payments).

## 6. Architecture

```text
 Garage (edge)                                   |   Cloud (per region)
                                                 |
 [LPR camera]--+                                 |
 [ticket kiosk]+--> Garage controller ------------+--> API gateway --> Session service ----> PostgreSQL
 [gate arm] <--+    (local server)  <-- sync ---+|                --> Reservation service --> PostgreSQL
 [spot sensors]--> |  local DB of               ||                --> Payment service ------> payment provider
 [level signs] <-- |  spots + open sessions     ||                --> Availability service --> Redis (counts)
                   +----------------------------+|                --> Pricing service
                                                 |  apps / web  --> API gateway
```

**The garage controller is the key decision.** Each garage runs a local controller that owns the live spot state for that garage and can admit and release cars on its own. It syncs sessions to the cloud asynchronously (an outbox of events). The cloud is the system of record for history, reservations, payments and the cross-garage view.

## 7. Deep dive: spot allocation and counts

- **Assign a specific spot or just count?** Most real garages only track **counts per type** (sensors or entry/exit counting) and let drivers pick; assigned spots are used in valet or premium lots. Ask. Counting is simpler and more robust.
- Allocation happens inside the garage controller, which is single-writer for its garage, so there is no distributed race: a local transaction or a single-threaded allocator is enough.
- **Availability** = capacity - occupied - held for upcoming reservations. The controller publishes count changes; the availability service keeps `garage:type -> free` in Redis for apps and signs. Slightly stale (seconds) is fine for display; the gate makes the real decision.

## 8. Deep dive: reservations without overbooking

- Reserve a **spot type** for a window, not a specific spot (much more flexible).
- Split time into slots (for example 15 minutes). A reservation for 10:00-12:00 increments `reserved_count` for 8 slots, in **one transaction** with a check `reserved_count < limit` for each slot (`SELECT ... FOR UPDATE` or a conditional update). If any slot is full, roll back.
- `limit` is a share of capacity (say 30%), so walk-in drivers are not locked out and no-shows do not leave the garage empty.
- Push reservations for the next few hours down to the garage controller so it can honor them offline.

## 9. Deep dive: payments and pricing

- The fee is computed from entry time, exit time, spot type and the garage's rate rules (first hour, hourly, daily cap, night rate). Pricing is a pure function: easy to test and to run both at the gate and in the cloud.
- **Idempotency key** per payment attempt (`ticketId + attempt`) stored with a unique constraint, so a retried request after a timeout does not charge twice.
- Pay-in-app before reaching the exit; the gate checks a "paid" flag (cached locally with a grace period, for example 15 minutes to exit).

## 10. Failure modes

| Failure | Behavior |
|---|---|
| Garage loses internet | Controller keeps admitting and releasing using local state and cached rates; card payments at the gate terminal still work (the terminal has its own connection) or are deferred; events sync later. |
| Controller crashes | Hot standby in the garage, or gates fall back to "issue ticket, open gate" mode with reconciliation later. |
| LPR misread | Fall back to a printed ticket or a manual intercom. |
| Lost ticket | Look up by plate; otherwise charge the daily maximum (business rule). |
| Duplicate entry event (retries) | Sessions keyed by a client-generated ticket ID; inserts are idempotent. |

## 11. What interviewers look for

- Recognizing that this is mostly an LLD problem, and asking which one they want.
- Good entity modeling (spot types, vehicle types, tickets, pricing rules).
- Edge resilience: the gate cannot depend on the cloud.
- Correct reservation capacity checks under concurrency.

## 12. Common mistakes

- Designing a globally distributed, massively sharded system for 350 events per second.
- Gates that call the cloud synchronously with no offline mode.
- Reserving specific spots for long windows (fragmentation, easy to overbook or under-use).
- Forgetting the exit path and payment idempotency.

## 13. Follow-ups

1. **EV charging:** a spot feature plus a charging session billed per kWh; the spot type matching becomes "type plus required features".
2. **Dynamic pricing:** price by occupancy level; the pricing service publishes rates to controllers.
3. **Monthly passes:** a plate allowlist synced to the controller.
4. **Analytics:** occupancy over time from the session history, for capacity planning.
