# Food Delivery (DoorDash / Uber Eats / Swiggy / Zomato): High-Level Design

**Asked at:** DoorDash, Uber, Swiggy, Zomato, Deliveroo, Instacart. **Core topics:** a three-sided marketplace (customers, restaurants, couriers), the order lifecycle, courier dispatch timed to food readiness, batching, ETAs, live tracking, peak-hour supply and demand.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Features? | Browse nearby restaurants and menus, place an order, pay, restaurant accepts and prepares, a courier picks up and delivers, live tracking, ratings. |
| Scale? | 10 M orders/day; 500K restaurants; 1 M couriers, 300K online at peak. |
| Peaks? | Lunch and dinner: ~3x average; Friday nights more. |
| ETA? | Shown before ordering and updated live. |
| Out of scope | Grocery inventory, ads, loyalty programs. |

## 2. Requirements

**Functional:** restaurant discovery (by location, cuisine, delivery time), menu and cart, ordering and payment, restaurant order management, courier dispatch, tracking, notifications, cancellations and refunds.

**Non-functional:** dispatch decisions within seconds, accurate ETAs, high availability at meal peaks, consistency for orders and payments, location updates at scale (see 08).

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Orders | 10 M/day, peak hour ~1.5 M | **~400/s** at peak |
| Courier location updates | 300K couriers / 5 s | **~60K writes/s** (in-memory geo index) |
| Discovery queries | ~20 per order | **~8K/s** peak, mostly cacheable |
| Order events | ~10 state changes per order | ~100 M events/day |

## 4. Architecture

```text
 customer app --> gateway --> Discovery (restaurants near me: geo index + availability + ETA estimate; cached)
                          --> Cart/Order service (order DB, state machine, outbox --> Kafka "order-events")
                          --> Payment service (authorize at order, capture at delivery; see 14)
 restaurant tablet <--> Restaurant service (accept/reject, prep time, ready signal, menu availability)
 courier app --> Location service (in-memory geo index by city, see 08)
              <--> Dispatch service: consumes order events; matches orders to couriers per city every few seconds
                     |  inputs: food-ready estimates, courier positions/ETAs (routing service), batching rules
 Tracking: courier positions pushed to the customer (WebSocket) while the order is out for delivery
 ETA service: ML model (prep time by restaurant/time/order size + travel time) used everywhere
```

## 5. Deep dive: the order lifecycle

```text
 placed --restaurant accepts--> accepted --> preparing --> ready --courier picks up--> picked_up --> delivered
    |            |                                                                     
    +--rejected / timeout (no answer in N minutes) --> cancelled (full refund)
    +--customer cancels: free before preparation starts; partial charge after
```

Each transition is a conditional update and an event; downstream services (notifications, dispatch, payments) react to events.

## 6. Deep dive: dispatch

- **Timing, not just distance:** the courier should arrive when the food is ready. Too early wastes courier time (they wait at the restaurant); too late leaves food cooling. The cost combines pickup time, courier waiting, and delivery time.
- **Batching:** one courier carries two or three orders from the same or nearby restaurants going in similar directions. Saves courier capacity at peaks; adds a few minutes for the second customer, which must be bounded.
- **Global optimization:** instead of greedy per order, solve an assignment problem across all pending orders and available couriers in a city every few seconds (Hungarian algorithm or min-cost flow on a sparse candidate graph).
- **Offers:** couriers can decline; on decline or timeout, re-dispatch (like 08).

## 7. Deep dive: ETAs

ETA = time to restaurant acceptance + prep time (model per restaurant, hour, basket size, current load) + courier travel to restaurant (overlapping with prep) + travel to the customer + handoff time. Shown as a range; updated on every event. Bad ETAs are the top customer complaint; measure and retrain constantly.

## 8. Deep dive: peaks and supply

- Surge pricing / delivery fees and courier incentives balance demand and supply per zone.
- Throttle discovery: hide or delay restaurants whose kitchens are overloaded (prep time rising), or extend their ETA.
- Pre-scale services for meal times; order placement must never be the bottleneck.

## 9. Failure modes

| Failure | Behavior |
|---|---|
| Restaurant does not respond | Auto-cancel after a timeout with refund; restaurant marked paused. |
| Courier goes offline mid-delivery | Detected by missing location updates; support contacts courier; reassign if not picked up yet. |
| Dispatch service down | Orders queue; on recovery, dispatch catches up; restaurants keep preparing. |
| Payment capture fails at delivery | Retry; the authorization from order time guarantees funds. |

## 10. What interviewers look for

- The three parties and their apps; the order state machine.
- Dispatch that accounts for food readiness, plus batching.
- ETA as a first-class model.
- Reuse of the geo index and real-time tracking ideas from ride sharing.

## 11. Common mistakes

- Assigning the nearest courier the moment an order is placed (they wait 20 minutes at the restaurant).
- Ignoring restaurant acceptance and prep time.
- Treating it exactly like ride sharing (food readiness and batching are the differences).

## 12. Follow-ups

1. **Scheduled orders:** dispatch planned backward from the requested delivery time.
2. **Group orders:** shared cart with per-person payments.
3. **Dark kitchens / grocery:** inventory per store (see 30).

See [LLD.md](LLD.md) for the order state machine with cancellation rules, ETA calculation, readiness-aware courier selection and order batching.
