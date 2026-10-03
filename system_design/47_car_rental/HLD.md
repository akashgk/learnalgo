# Car Rental System (Hertz / Zipcar / Turo-style fleet): High-Level Design

**Asked at:** Amazon, Uber, Expedia, Booking.com, many LLD rounds. **Core topics:** availability over time intervals (not nights), reservations by vehicle class vs assignment of a specific car at pickup, one-way rentals and fleet rebalancing, pricing rules, pickup/return flows with damage and fuel charges.

Ask which round this is; most interviews want the class design in [LLD.md](LLD.md). The inventory logic is related to 29 (hotel) but with arbitrary time intervals and vehicles that move between locations.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Fleet? | 50,000 cars at 500 locations (airports, city branches). |
| Booking unit? | Vehicle class (economy, SUV, ...) at a pickup location for a time window; a specific car is assigned at pickup. |
| One-way? | Allowed with a drop fee; the car ends at the return location. |
| Traffic? | ~100K searches/hour peak; ~20K bookings/day. |
| Pricing? | Daily rates by class/location/season, weekly discounts, one-way fees, late fees, fuel and mileage charges. |

## 2. Requirements

**Functional:** search availability and prices; reserve; modify/cancel; pickup (assign a car, record mileage/fuel); return (inspect, compute final charges); manage fleet movements and maintenance.

**Non-functional:** no overbooking beyond the configured policy, consistent reservations, fast search (cached availability), auditability of charges.

## 3. Architecture

```text
 web/app --> Search service: availability per (location, class, window) from a cached projection
         --> Reservation service: reservations (PostgreSQL), conflict checks per (location, class), idempotency keys
         --> Pricing service: rate tables + rules (seasonal, weekly, one-way, promotions)
 branch counter app --> Pickup/Return service: assign vehicle, record odometer/fuel/damage, final invoice
 Fleet service: vehicle registry, location, status (available, rented, maintenance, in transit)
 Rebalancing planner: forecasts demand per location; schedules transfers (drivers/trucks)
 Payments: authorization hold at pickup, capture at return (see 14)
```

## 4. Deep dives

- **Availability over intervals:** a reservation occupies `[pickup, return + cleaning buffer)`. Capacity check for a new booking = peak number of overlapping reservations in its window (sweep over start/end events) must stay below the class count expected at that location.
- **Expected count at a location changes over time:** one-way returns add cars, one-way departures remove them, transfers move them. A simple model counts cars currently assigned to the location plus scheduled arrivals.
- **Class reservations, car assignment at pickup:** maximizes flexibility (any clean car of the class), like hotels assign rooms at check-in.
- **Overbooking:** small, deliberate (no-shows); upgrades to a higher class when a class runs out.
- **Pricing:** computed by a rules engine; quoted price stored with the reservation so later rate changes do not affect it.

## 5. Failure modes

| Failure | Behavior |
|---|---|
| Car not returned on time for the next rental | Upgrade or substitute from another class; overbooking policy covers rare cases. |
| Double booking race | Conditional insert after the overlap check in one transaction per (location, class). |
| Damage disputes | Photos at pickup/return stored with the rental. |

## 6. What interviewers look for

- Interval overlap reasoning for availability.
- Separation of class reservation and vehicle assignment.
- One-way rentals and fleet movements.
- Clear pricing rules and final invoicing.

## 7. Common mistakes

- Treating availability per day like hotels (rentals start and end at any hour).
- Reserving a specific car months ahead.
- Ignoring the cleaning/turnaround buffer between rentals.

See [LLD.md](LLD.md) for vehicles, interval-based class availability, reservations, vehicle assignment at pickup, one-way moves, and pricing with weekly discounts, one-way and late fees and fuel charges.
