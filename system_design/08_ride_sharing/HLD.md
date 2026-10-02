# Ride Sharing (Uber / Lyft): High-Level Design

**Asked at:** Uber, Lyft, Grab, Amazon, Google. **Core topics:** high-frequency location updates, geospatial indexing (geohash, quadtree, H3), matching drivers to riders without double assignment, trip state machine, surge pricing.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Core flow? | Rider requests a ride; nearby available driver is matched; driver accepts; pickup; trip; payment. |
| Ride types? | One type (UberX-like). Pooling as a follow-up. |
| Scale? | 20 M rides/day; 5 M drivers online at peak, each sending location every ~4 s. |
| ETA and pricing? | Fare estimate before requesting; surge pricing by area. |
| Real-time tracking? | Rider sees the driver moving on the map. |
| Payments? | Charged at trip end through a payment service (external). |
| Regions? | Global, but every trip is local to one city. |

## 2. Requirements

**Functional:** drivers go online and stream locations; riders get fare estimates and request rides; the system matches a nearby driver; driver accepts or declines (timeout); trip progresses through states; fare computed and charged; both sides see each other's location.

**Non-functional:**

- **Matching within seconds;** a driver is never assigned to two trips at once.
- **Location ingestion at very high write rates;** freshness of seconds.
- **Highly available** per city; partial failures degrade gracefully.
- **Trip and payment data strongly consistent** and durable.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Location updates | 5 M drivers / 4 s | **~1.25 M writes/s** |
| Ride requests | 20 M / 86,400 | **~230/s** avg, ~1K/s peak |
| Location payload | driver ID, lat, lng, heading, timestamp ≈ 50 B | 1.25 M x 50 B ≈ **60 MB/s** ingress |
| Live location state | 5 M x ~100 B | **~500 MB**: fits in memory, sharded by city |
| Trip storage | 20 M x ~2 KB | **~40 GB/day** |

The location stream dominates. Rides are modest in rate but need correctness. These two parts get different technologies.

## 4. API

```text
Driver app (WebSocket or frequent HTTP):
  PUT  /drivers/me/status      { online | offline }
  POST /drivers/me/location    { lat, lng, heading, ts }          every ~4 s (batched when on a trip)
  POST /trips/{id}/accept | decline
  POST /trips/{id}/arrived | start | complete

Rider app:
  GET  /estimates?from=&to=        -> { fare, surgeMultiplier, etaMinutes, quoteId }
  POST /trips                      { quoteId, pickup, dropoff, idempotencyKey } -> { tripId, status: "matching" }
  GET  /trips/{id}                 (or a push channel for driver location and status)
  POST /trips/{id}/cancel
```

The `quoteId` locks the shown price (including surge) for a few minutes so the rider pays what they agreed to.

## 5. Data model

```text
drivers(id, name, vehicle, rating, status)                         -- PostgreSQL
driver_locations: in-memory geo index per city (Redis GEO / custom service), key driver_id -> (lat, lng, ts)
trips(id, rider_id, driver_id?, status, pickup, dropoff, quote_id, fare, requested_at, ..., version)
trip_events(trip_id, ts, from_status, to_status, actor)            -- audit trail
quotes(id, rider_id, fare, surge, expires_at)
location history: append to Kafka -> cold storage (for disputes, ETA model training)
```

Trips need transactions and conditional updates: PostgreSQL (sharded by city or trip ID) or a strongly consistent store (Spanner / CockroachDB).

## 6. Architecture

```text
 driver apps ==> gateway ==> Location service ==> geo index per city (in memory, sharded by cell)
                                   |                 ^
                                   +--> Kafka ------+--> history storage, ETA / surge analytics
                                                     |
 rider apps ==> gateway ==> Trip service ----> Matching service --(nearest available drivers)--+
                               |  ^                 |
                               |  |                 +--> offer to driver (push) --> accept/decline/timeout
                               v  |
                           Trips DB (state machine, conditional updates)
                               |
                               +--> Pricing service (estimates, surge per cell)
                               +--> Payment service (charge on complete)
                               +--> Notification service (push)
```

## 7. Deep dive: geospatial index

The question "available drivers within 2 km of this point" over 1.25 M updates per second.

| Option | How | Notes |
|---|---|---|
| SQL `WHERE lat BETWEEN ... AND lng BETWEEN ...` | B-tree on lat or lng | uses one index dimension, scans a strip; too slow at this update rate |
| **Geohash** | encode (lat, lng) as a string; nearby points share prefixes; query the cell and its 8 neighbors | simple; cell sizes vary with latitude; edge effects handled by neighbors |
| **Quadtree** | split a cell into 4 when it has too many points | adapts to density (Manhattan vs suburbs); more complex to update |
| **H3 (Uber)** | hexagonal cells; all neighbors are equidistant | used for surge and matching at Uber |
| Redis GEO | geohash in a sorted set; `GEOSEARCH` | good off-the-shelf choice |

**Update cost:** a location update moves a driver from one cell to another only when they cross a boundary; usually it is an in-place update of coordinates. Keep the index **in memory**, sharded by city/region (a city's drivers fit on a few machines), and accept that a crash loses positions for a few seconds until drivers report again (no durability needed for current location).

## 8. Deep dive: matching without double assignment

1. Trip created in state `matching`.
2. Matching service queries the geo index for available drivers near the pickup, ranks them (ETA by road network, not straight-line distance; rating; acceptance rate).
3. It **reserves** the best driver atomically: a conditional update `driver.status: available -> offered(tripId)` (compare-and-set in Redis or the DB). If it fails, another trip got that driver; try the next.
4. Send the offer; wait up to ~15 s. On accept: `trip: matching -> accepted` and `driver: offered -> on_trip` (one transaction or a saga with compensation). On decline or timeout: release the driver and offer the next candidate.
5. After N failures, widen the radius or tell the rider no drivers are available.

Single-writer alternative: one matching process per city cell owns all driver assignments in its area, which removes contention entirely; scale by splitting cells.

**Batch matching (follow-up):** collect requests for ~2 s and solve an assignment problem across riders and drivers in a region; better global ETA than greedy one-by-one.

## 9. Deep dive: the trip state machine

```text
 matching --accept--> accepted --arrive--> arrived --start--> in_progress --complete--> completed --> paid
    |                    |                    |
    +--no driver--> failed                    |
    +--rider cancel--> cancelled <--rider/driver cancel (fee may apply after a grace period)
```

Every transition is a conditional update on `(trip_id, expected_status, version)`. Invalid transitions (completing a trip that never started) are rejected. Each transition is appended to `trip_events` for audit and support.

## 10. Deep dive: pricing and surge

- Fare = base + per km x distance + per minute x duration, times the surge multiplier, with a minimum fare.
- **Surge** per cell, recomputed every ~minute from demand (requests) vs supply (available drivers) in that cell. Published to the pricing service; quotes lock it.
- Final fare uses the actual route (from location history), or the upfront quoted price if the route did not deviate much.

## 11. Failure modes

| Failure | Behavior |
|---|---|
| Location service node dies | Drivers in its shard vanish from matching for a few seconds until their next update lands on the replacement. |
| Driver's app loses connection mid-offer | Offer times out, next driver; the reservation expires automatically (TTL on the `offered` state). |
| Duplicate trip requests (rider double-taps) | `idempotencyKey` on `POST /trips`. |
| Payment fails at trip end | Trip is `completed`; payment retried asynchronously; rider's account flagged if it keeps failing. |
| Region outage | Trips are city-local; fail over the city's services to another region with the trips DB replica. |

## 12. What interviewers look for

- Separating the high-volume ephemeral location stream from the low-volume transactional trip data.
- A real geospatial index, with the trade-offs.
- Atomic driver reservation, offers with timeouts, no double assignment.
- An explicit trip state machine.

## 13. Common mistakes

- Storing every location update in the main relational database.
- Matching by straight-line distance only, without saying ETA is better.
- No reservation step, so two riders get the same driver.
- Forgetting offer timeouts and declines.

## 14. Follow-ups

1. **Pool / shared rides:** route insertion problem; match riders whose detours stay under a limit.
2. **ETA service:** road graph with live traffic (contraction hierarchies), ML corrections.
3. **Scheduled rides:** reserve a driver near the time; treat as a normal request ~15 minutes before.
4. **Fraud:** GPS spoofing detection from speed and route plausibility.

See [LLD.md](LLD.md) for the classes: grid index, matching with reservations, trip state machine and fare strategy.
