# Library Management System: High-Level Design

**Asked at:** Amazon, Microsoft, Oracle, Adobe, many LLD rounds. **Core topics:** mostly an object-oriented design question; the HLD version is a multi-branch library network with a shared catalog, holds across branches, transfers, notifications, fines, and digital lending with license limits.

Ask which round this is; [LLD.md](LLD.md) covers the class design most interviews expect.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Size? | A city system: 40 branches, 2 M physical copies, 500K members. |
| Features? | Catalog search, checkout/return at any branch, renewals, holds (reservations) with pickup at a chosen branch, overdue fines, notifications, e-books. |
| Traffic? | Modest: ~50K checkouts/day; search is the main read load. |
| Consistency? | A copy can be lent to only one member; holds served in fair order. |

## 2. Requirements

**Functional:** search titles; place holds; check out, return, renew; compute fines; notify members (hold ready, due soon, overdue); manage copies and branches; e-book loans limited by licenses.

**Non-functional:** correctness of copy states, fairness of hold queues, availability during branch hours (branch desks keep working with brief network issues), privacy of borrowing history.

## 3. Architecture

```text
 OPAC web/app --> Search service (catalog index: title, author, subject; see 22)
              --> Circulation service: copies, loans, holds, fines (PostgreSQL, strongly consistent)
 branch desks (barcode scanners, self-checkout kiosks) --> Circulation service
 events (hold ready, due soon, overdue) --> Notification service (email/SMS, see 07)
 Transfer service: when a hold is placed at branch X, pick a copy at branch Y and schedule transport
 E-book service: licenses per title (e.g. 3 concurrent loans), waitlist like holds, auto-return at expiry
```

## 4. Deep dives

- **Title vs copy:** the catalog describes titles (ISBN); circulation tracks physical copies with barcodes and states (available, on loan, on hold shelf, in transit, lost).
- **Holds:** FIFO per title (not per copy); when any copy is returned, it goes to the next holder's pickup branch with an expiry (e.g. 7 days); unclaimed holds move to the next person.
- **Renewals:** blocked when others are waiting, and limited in count.
- **Fines:** per day overdue, capped per item; members above a fine threshold cannot borrow.
- **Offline branch desk:** a local queue of checkouts/returns synced later; conflicts (copy marked lost, etc.) reconciled by staff.
- **Privacy:** borrowing history deleted after return unless the member opts in.

## 5. Failure modes

| Failure | Behavior |
|---|---|
| Two desks scan the same copy | Copy state change is a conditional update; the second fails. |
| Notification failure | Retry; the hold shelf expiry gives a grace period. |
| Lost transfer | Copy marked in transit with a deadline; investigation after expiry. |

## 6. What interviewers look for

- Title/copy separation and a copy state machine.
- A fair hold queue with pickup expiry.
- Clear business rules (limits, renewals, fines) implemented in one place.

## 7. Common mistakes

- Holds attached to a specific copy (slow and unfair).
- Allowing renewal while others wait.
- Fines in floating point.

See [LLD.md](LLD.md) for books and copies, members with limits, checkout/return/renew rules, hold queues with pickup expiry, fines and search.
