# Hotel Reservation System (Booking.com / Marriott / Airbnb-style inventory): High-Level Design

**Asked at:** Booking.com, Expedia, Airbnb, Marriott, Amazon, Agoda. **Core topics:** inventory per room type per night, preventing overbooking under concurrency (or allowing controlled overbooking), idempotent reservations, read-heavy search vs write-critical booking, sharding by hotel, caching availability.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Chain or marketplace? | A chain/aggregator with 5,000 hotels and ~1 M rooms. |
| Book specific rooms or room types? | **Room types** (guests book "deluxe king"); the specific room is assigned at check-in. |
| Scale? | ~10 M searches/day; ~100K reservations/day (~1% conversion). |
| Overbooking? | Hotels may allow ~10% overbooking per room type (no-shows are common). |
| Payment? | Pay at booking or at the hotel; cancellations allowed until a deadline. |
| Consistency? | Never sell more than total x (1 + overbooking%). |

## 2. Requirements

**Functional:** search availability and prices for dates; reserve; cancel; manage rates and inventory (hotel staff).

**Non-functional:** strong consistency for reservations, high availability and low latency for search, idempotency (no double bookings from retries), auditability.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Reservations | 100K/day | **~1-3/s** avg, ~50/s peak |
| Searches | 10 M/day | **~120/s** avg, ~1K/s peak |
| Inventory rows | 5,000 hotels x ~20 room types x 730 days | **~73 M rows** (two years ahead) |

Writes are low; the challenge is correctness under concurrency on hot dates (holidays, events) and serving search from cache.

## 4. API

```text
GET  /hotels/search?city=&checkIn=&checkOut=&guests=      -> hotels with available room types and prices (cached)
GET  /hotels/{id}/availability?checkIn=&checkOut=
POST /reservations  { idempotencyKey, hotelId, roomTypeId, checkIn, checkOut, rooms, guest }  -> { reservationId, total }
DELETE /reservations/{id}                                  (cancel; refund per policy)
PUT  /hotels/{id}/inventory, /rates                        (staff)
```

## 5. Data model

```text
hotels(id, city, ...)                 room_types(id, hotel_id, name, capacity)
room_type_inventory(hotel_id, room_type_id, date, total_rooms, total_reserved, version)
      PK (hotel_id, room_type_id, date)       CHECK (total_reserved <= total_rooms * 1.1)
rates(hotel_id, room_type_id, date, price)
reservations(id, idempotency_key UNIQUE, hotel_id, room_type_id, check_in, check_out, rooms, status, total)
```

Shard by `hotel_id`: a reservation touches one hotel, so it is a single-shard transaction.

## 6. Deep dive: preventing overbooking under concurrency

Two guests try to book the last deluxe room for the same night.

| Approach | How | Notes |
|---|---|---|
| Pessimistic locking | `SELECT ... FOR UPDATE` on the inventory rows for all nights, check, update | correct; locks held only for the transaction (milliseconds); deadlock risk if nights are locked in different orders (always lock in date order) |
| **Optimistic locking** | read rows with `version`; `UPDATE ... SET total_reserved = total_reserved + n, version = version + 1 WHERE ... AND version = :v` for every night; if any update affects 0 rows, roll back and retry | no lock waits; great when conflicts are rare (they are) |
| Database constraint | `CHECK (total_reserved <= limit)` | last line of defense; the losing transaction fails |

A multi-night stay updates several rows: **all or nothing** in one transaction.

## 7. Deep dive: idempotency and the reservation flow

1. The client generates an `idempotencyKey` when the booking page loads.
2. `POST /reservations` inserts the reservation with the unique key **in the same transaction** as the inventory update. A retry finds the existing row and returns it.
3. Payment (if prepaid) runs after the hold; failure releases the inventory (status `cancelled`), or the reservation stays `pending` with a short expiry (similar to seat holds in 09).

## 8. Deep dive: search and caching

- Availability changes rarely relative to reads: cache `(hotel, roomType, date) -> available` and prices in Redis, updated on each reservation (write-through) or with a short TTL.
- Search results can be slightly stale; the reservation transaction is the source of truth (it may answer "no longer available").
- Precompute city-level indexes for search (hotels by city with min price per date range).

## 9. Failure modes

| Failure | Behavior |
|---|---|
| Client retry after timeout | Idempotency key returns the original reservation. |
| Conflict on hot dates | Optimistic retry a few times, then report unavailable. |
| Cache stale | Booking transaction re-checks; cache corrected on write. |
| Shard failover | Replica promoted; in-flight transactions retried by idempotency key. |

## 10. What interviewers look for

- Inventory modeled per room type per night, not per physical room.
- A correct concurrency control strategy, all-or-nothing across nights.
- Idempotent booking and overbooking as an explicit policy.
- Read path (cache, slightly stale) separated from write path (transactional).

## 11. Common mistakes

- Checking availability and then updating in separate steps without locking or versioning.
- Modeling each physical room's calendar for booking (complex and unnecessary).
- Distributed transactions across hotels when each booking touches one hotel.
- No idempotency key (double bookings from retries).

## 12. Follow-ups

1. **Room assignment at check-in:** interval scheduling of reservations onto physical rooms.
2. **Dynamic pricing:** rates by occupancy and demand.
3. **Channel managers:** the same inventory sold through many sites; push availability updates to them.
4. **Waitlists** for sold-out dates.

See [LLD.md](LLD.md) for per-night inventory with versions, all-or-nothing reservations, overbooking limits, idempotency, cancellations, nightly pricing and an optimistic-concurrency conflict.
