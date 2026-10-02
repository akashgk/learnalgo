# Movie Ticket Booking (BookMyShow / Fandango / Ticketmaster): High-Level Design

**Asked at:** Amazon, Microsoft, Flipkart, Walmart, Uber. **Core topics:** preventing double booking under contention, temporary seat holds with expiry, payment integration and its failure cases, flash-sale traffic.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Features? | Browse movies, theaters and showtimes; view a seat map; pick specific seats; pay; get a ticket. |
| Seat selection? | Specific seats (not general admission). |
| Scale? | 50 M monthly users; 10 M bookings/month; peaks for blockbuster openings (millions of users at the same minute). |
| Hold time? | Seats are held for ~10 minutes while the user pays. |
| Payment? | External payment gateway, which can be slow or fail ambiguously. |
| Cancellation / refunds? | Yes, until some cutoff before the show. |
| Consistency? | **No double booking ever.** The seat map display may be slightly stale. |

## 2. Requirements

**Functional:** search shows; view seat availability; hold selected seats; confirm with payment; cancel; receive the ticket (QR code).

**Non-functional:**

- **Strong consistency for seat state;** two users can never both own a seat.
- **Fairness and survival under flash-sale load** (a virtual waiting room).
- Browse and seat-map reads fast and highly available (cacheable).
- Bookings durable; payment and booking reconciled.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Bookings | 10 M / month / 30 / 86,400 | **~4/s** avg; peaks of **thousands/s** for a big release |
| Seat-map reads | ~50x bookings | **~200/s** avg; **100K+/s** at peaks |
| Seats per show | ~200 (multiplex screen) | contention is concentrated on a few hundred rows per show |
| Shows | 10,000 screens x 5 shows/day | **50K shows/day** → 10 M seat rows/day |
| Storage | 10 M seat rows/day x ~100 B | **~1 GB/day** |

The average load is tiny. The design is driven by **contention on a few hot shows** and by correctness, not by volume.

## 4. API

```text
GET  /movies?city=...                         GET /shows?movieId=&date=&city=
GET  /shows/{showId}/seats                    -> seat map with status: available / held / booked
POST /shows/{showId}/holds   { seatIds[] }    -> { holdId, expiresAt }       409 if any seat is taken
POST /bookings   { holdId, paymentToken, idempotencyKey }  -> { bookingId, status }
DELETE /holds/{holdId}                       (user changed their mind)
POST /bookings/{id}/cancel
```

## 5. Data model

```text
movies(id, title, ...)   theaters(id, city, ...)   screens(id, theater_id, layout)
shows(id, movie_id, screen_id, starts_at, price_by_category)
show_seats(show_id, seat_id, status, hold_id, hold_expires_at, booking_id, version)   PK (show_id, seat_id)
holds(id, user_id, show_id, seat_ids, expires_at, status)
bookings(id, user_id, show_id, seat_ids, amount, status, payment_id, idempotency_key UNIQUE)
```

Relational (PostgreSQL / MySQL), sharded by `show_id`: all seats of one show live in one shard, so a hold is a single-shard transaction. Catalog data (movies, theaters, shows) is read-heavy and cached / indexed in a search engine.

## 6. Architecture

```text
 users --> CDN (posters, static) 
       --> API gateway --> [virtual waiting room for hot shows]
                 |
                 +--> Catalog service --> cache / Elasticsearch (movies, shows)
                 +--> Seat service ------> show_seats (sharded by show_id)   + Redis seat-map cache
                 |        |  hold: conditional update of N seats in one transaction
                 +--> Booking service --> bookings DB
                 |        |  confirm: pay, then mark seats booked
                 |        +--> Payment gateway (external)   <-- webhooks
                 +--> Notification service (ticket email / push)
     Expiry worker: releases holds past expires_at (plus lazy checks on read)
```

## 7. Deep dive: preventing double booking

Two users click the same seat at the same millisecond. Options:

| Approach | How | Trade-off |
|---|---|---|
| Pessimistic lock | `SELECT ... FROM show_seats WHERE show_id = ? AND seat_id IN (...) FOR UPDATE`, check all available, update | simple and correct; locks held briefly (one transaction, no user think time inside) |
| **Optimistic conditional update** (recommended) | `UPDATE show_seats SET status='held', hold_id=?, hold_expires_at=? WHERE show_id=? AND seat_id IN (...) AND (status='available' OR (status='held' AND hold_expires_at < now()))`; succeed only if the updated row count equals the number of seats, else roll back | no lock waits; perfect for "first one wins" |
| Redis `SET seat:{show}:{seat} holdId NX PX 600000` per seat | atomic per seat; multi-seat needs a Lua script for all-or-nothing | very fast; Redis must be authoritative or reconciled with the DB |
| Unique constraint | insert into `seat_bookings(show_id, seat_id)` with a unique key | the database guarantees it; good as a last line of defense |

**All-or-nothing:** a user wanting seats A5 and A6 must get both or neither: one transaction, check the affected row count.

Never hold a database lock while the user is choosing or paying. The hold **is** the lock: a row state with an expiry.

## 8. Deep dive: holds and expiry

- A hold sets `status = held` and `hold_expires_at = now + 10 min`.
- Expiry is enforced **two ways**: availability checks treat expired holds as available (lazy, so correctness never depends on a background job), and a worker periodically clears expired holds (so the seat map looks right).
- The confirm step checks that the hold is still valid **in the same transaction** that marks seats booked.

## 9. Deep dive: payment and the booking state machine

```text
hold created --pay--> PAYMENT_PENDING --gateway success--> CONFIRMED (seats: booked)
     |                      |
     +--expires--> EXPIRED  +--gateway failure--> FAILED (seats released)
                            +--timeout / unknown--> reconcile with the gateway before deciding
```

The dangerous case: the payment succeeded but the hold expired in the meantime (slow gateway, user on a bad network).

- Extend the hold when payment starts (`PAYMENT_PENDING` holds are not expired by the worker until a longer deadline).
- If payment succeeds after the seats were really lost, refund automatically.
- **Idempotency key** on the booking request and on the gateway call, so retries never charge twice.
- Gateway webhooks plus a reconciliation job resolve "unknown" outcomes.

## 10. Deep dive: flash sales

A blockbuster opens booking at 10:00; 2 M users arrive for 50K seats.

- **Virtual waiting room:** admit users to the booking flow at a controlled rate (tokens), others see their place in the queue. Protects the seat service and is fairer than "fastest retry wins".
- Serve the seat map from a cache that is a second or two stale; the hold request is the source of truth (409 means "pick another seat").
- Rate-limit holds per user (no bots holding 500 seats); limit seats per booking.
- Pre-scale; shard by show so one hot show does not affect others.

## 11. Failure modes

| Failure | Behavior |
|---|---|
| App server dies after hold | Hold expires on its own; nothing to clean up. |
| Expiry worker down | Lazy expiry keeps correctness; only the displayed map is stale. |
| Payment gateway slow | Holds extended in `PAYMENT_PENDING`; timeouts trigger reconciliation, not a guess. |
| Double submit of booking | Idempotency key returns the first result. |
| Database shard down | Shows on that shard unavailable; replicas promoted. |

## 12. What interviewers look for

- An airtight answer to "two users, same seat, same time": conditional update or lock, all-or-nothing for multiple seats.
- Holds with expiry instead of long locks.
- Correct handling of payment edge cases (success after expiry, retries, unknown outcomes).
- Recognizing that the problem is contention, not volume, and a plan for flash sales.

## 13. Common mistakes

- Check-then-act without atomicity ("SELECT available seats" then "UPDATE" in separate steps).
- Locking rows while the user pays.
- Relying only on a background job for expiry.
- Ignoring the payment-succeeded-but-hold-expired case.
- Over-engineering the average load (4 bookings per second).

## 14. Follow-ups

1. **General admission (no seat choice):** a counter per show with a conditional decrement.
2. **Seat recommendation:** best available adjacent seats for N people.
3. **Dynamic pricing:** price per seat category and demand.
4. **Waitlist** when sold out: notify when cancellations free seats (see 07 Notification System).

See [LLD.md](LLD.md) for the classes: shows, seats, holds with expiry, booking state machine and payments.
