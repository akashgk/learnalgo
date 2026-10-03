# Dating App (Tinder / Bumble / Hinge): High-Level Design

**Asked at:** Match Group, Bumble, Meta, Snap, Uber. **Core topics:** geo-filtered candidate discovery, precomputed recommendation decks, very high swipe write volume, mutual-match detection without races, privacy of location, chat after matching, abuse controls.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Features? | Profiles with photos and preferences (age range, distance, gender); a swipeable deck; like/pass; a match when both like; chat between matches; unmatch and block. |
| Scale? | 75 M MAU, 20 M DAU; ~2 B swipes/day; ~30 M matches/day. |
| Latency? | Swipes feel instant; a match appears right away for the second swiper and is pushed to the first. |
| Privacy? | Exact location never shown; distance shown approximately. |

## 2. Requirements

**Functional:** profile management, discovery deck respecting both users' preferences, swipes, match detection, notifications, chat (see 05), unmatch/block/report, daily like limits for free tiers.

**Non-functional:** high write throughput for swipes, low-latency deck loading, strong correctness for matches (exactly one match per pair), privacy and safety.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Swipes | 2 B/day | **~23K/s** avg, ~70K/s peak |
| Swipe storage | 2 B x ~30 B | **~60 GB/day**; old passes can expire after months |
| Deck requests | 20 M x ~10 refills/day | **~2.3K/s** |
| Location updates | on app open | modest; geo index per region |

## 4. Architecture

```text
 app --> API gateway --> Profile service (profiles, photos via CDN, preferences)
                     --> Discovery service: reads the user's precomputed deck (Redis list)
                              ^ deck builder (async, per user): geo index candidates (see 23) -> filter by
                              |   mutual preferences, exclude swiped/blocked -> rank (activity, compatibility,
                              |   likelihood of mutual like) -> push ~100 profiles
                     --> Swipe service: write swipe (Cassandra, partition by swiper) --> if LIKE:
                              check reverse like (lookup by (target, swiper)) --> create match (idempotent pair key)
                              --> events --> Notification service (push), Chat service (open conversation)
```

## 5. Deep dive: swipes and matches

- Store swipes keyed by `(swiper, target)` so "did B already like A?" is a single point lookup.
- **Match detection on the second like:** when A likes B, look up `(B, A)`. If it is a like, create the match.
- **Race:** A and B like each other at the same moment; both lookups may miss. Fixes: make match creation idempotent with a canonical pair key `min(A,B):max(A,B)` and run a check after writing (each side writes its like, then checks the other); whoever sees both likes creates the match, and the unique key absorbs the duplicate.
- Passes are stored too (to exclude from future decks) but can have a TTL.

## 6. Deep dive: discovery decks

- Candidates within the distance preference from a geo index (geohash cells, see 23), filtered by **both** users' preferences (A within B's age range and vice versa).
- Ranking: recently active users, profile completeness, predicted mutual interest (learned), plus exploration for new users.
- Decks are **precomputed** asynchronously and refilled before they run out; deck reads are cheap list pops.
- Exclusion of already-swiped profiles uses a per-user Bloom filter for speed at deck-build time (false positives only hide a few profiles).

## 7. Deep dive: privacy and safety

- Store precise location server-side only; show distance rounded (e.g. "3 km away") and fuzz location to avoid trilateration attacks (round coordinates to a grid before computing displayed distance).
- Blocks are mutual and absolute: blocked users never appear in each other's decks, matches, or chats.
- Rate limits on likes (product and anti-spam), photo moderation, reporting flows.

## 8. Failure modes

| Failure | Behavior |
|---|---|
| Deck builder behind | Fall back to a simpler on-demand query with fewer candidates. |
| Duplicate swipe requests | Idempotent by `(swiper, target)`. |
| Concurrent mutual likes | Canonical pair key ensures one match. |
| Notification failure | Match still exists; client sees it on next open. |

## 9. What interviewers look for

- Geo-filtered candidate generation with mutual preference filtering.
- Swipe storage keyed for the reverse lookup and an idempotent, race-free match creation.
- Precomputed decks for fast loading.
- Location privacy and blocking semantics.

## 10. Common mistakes

- Computing the deck on every swipe with a full geo scan.
- Filtering only by the viewer's preferences (one-sided matches nobody can act on).
- Creating duplicate matches under concurrency.
- Exposing exact distance or coordinates.

## 11. Follow-ups

1. **Boosts and superlikes:** priority placement in others' decks.
2. **Rewind:** undo the last pass (keep the last swipe in a short buffer).
3. **Recommendation quality:** learn from mutual-like outcomes (see 41).

See [LLD.md](LLD.md) for profiles with mutual preference filters, deck building with exclusions, idempotent swipes, race-free match creation, daily like limits, unmatch/block and distance fuzzing.
