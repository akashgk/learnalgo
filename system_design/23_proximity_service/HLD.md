# Proximity Service (Yelp / Google Places "near me"): High-Level Design

**Asked at:** Yelp, Google, Uber, DoorDash, Amazon. **Core topics:** geospatial indexing (geohash, quadtree, S2/H3), read-heavy scaling, caching by cell, the trade-off between static points of interest (this problem) and moving objects (see 08 Ride Sharing).

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| What is searched? | Businesses (restaurants, shops): mostly static locations. |
| Query? | Businesses within radius r (0.5 to 20 km) of a point, optionally filtered by category, ranked by distance (and rating). |
| Scale? | 200 M businesses; 100 M DAU, ~5 searches each. |
| Writes? | Owners add/update businesses; changes may take minutes to appear. |
| Latency? | p99 < ~200 ms. |

## 2. Requirements

**Functional:** nearby search with radius and filters; business details; business CRUD.

**Non-functional:** low latency, high availability, read-heavy (reads ≫ writes), privacy for user location (not stored with searches beyond analytics needs).

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Search QPS | 100 M x 5 / 86,400 | **~5,800/s** avg, ~20K/s peak |
| Business data | 200 M x ~1 KB | **~200 GB** (details, in a sharded DB) |
| Geo index | 200 M x (8-byte ID + 8-byte geohash) | **~3.2 GB**: fits in memory on every index server |
| Writes | ~100K updates/day | **~1/s**: negligible |

The index is small enough to replicate everywhere; scale reads by adding replicas.

## 4. API

```text
GET /v1/search/nearby?lat=37.77&lng=-122.42&radius=2000&category=coffee&limit=20&cursor=...
  -> { businesses: [{ id, name, distanceMeters, rating, ... }], nextCursor }
GET /v1/businesses/{id}      POST/PUT/DELETE /v1/businesses/{id}  (owners, authenticated)
```

## 5. Geospatial index options

| Option | How | Notes |
|---|---|---|
| 2D range query in SQL | index on lat and on lng separately | each index narrows one dimension only; the intersection is large |
| **Geohash** | interleave lat/lng bits into a base32 string; nearby points share prefixes | a prefix is a rectangular cell; query the cell plus its 8 neighbors; works as a plain string index (`WHERE geohash LIKE '9q8yy%'`) |
| **Quadtree** | recursively split a region into 4 until a cell has ≤ k points | adapts to density (dense downtown, empty desert); built in memory on each server |
| Google S2 / Uber H3 | Hilbert-curve cells on a sphere / hexagons | better cell shapes, used in production at Google/Uber |

**Choice:** geohash (simple, stored in any database, cacheable by cell) or a quadtree held in memory. Both are shown in the LLD.

**Geohash precision vs cell size (at the equator):** 4 chars ≈ 39 x 20 km, 5 ≈ 4.9 x 4.9 km, 6 ≈ 1.2 x 0.6 km, 7 ≈ 153 x 153 m. Choose the longest precision whose cell is at least as large as the radius, then search the 3 x 3 block of cells.

**Edge cases:** points just across a cell boundary have different prefixes (hence the neighbors); cells shrink in width toward the poles; the antimeridian wraps longitude.

## 6. Architecture

```text
 client --> LB --> Location-based service (stateless, read-only)
                     | 1. pick precision from radius, compute center cell + 8 neighbors
                     | 2. for each cell: Redis cache geohash:{cell} -> [business IDs] (miss -> geo index DB)
                     | 3. fetch business locations/details (cache), compute exact distance, filter, sort
                     v
               Geo index: table (geohash, business_id) on read replicas, or in-memory quadtree per server
 owners --> Business service --> businesses DB (primary) --> CDC/nightly job --> rebuild geo index / invalidate cell caches
```

## 7. Deep dives

- **Too few results:** if the 3 x 3 block returns fewer than requested, drop one geohash character (bigger cells) and search again, up to the maximum radius.
- **Ranking:** distance first, or a blend of distance, rating and popularity; computed after the candidate set is small.
- **Caching:** cache by geohash cell (shared by every user in that area), not by exact coordinates (unique per user, useless as a cache key).
- **Quadtree updates:** rebuilding takes minutes for 200 M points; rebuild offline and swap, or apply incremental updates in batches; servers roll the new tree in gradually.

## 8. Failure modes

| Failure | Behavior |
|---|---|
| Index server down | Stateless replicas behind the load balancer. |
| Cache miss storm (cold start) | Warm popular cells; request coalescing per cell. |
| Business update lag | Acceptable (minutes); new businesses appear after the next index update. |

## 9. What interviewers look for

- Why a plain lat/lng index is not enough.
- Geohash or quadtree explained, with the neighbor-cell edge case.
- Precision chosen from the radius; expanding when results are sparse.
- Read-heavy scaling: small replicated index, cell-level caching.

## 10. Common mistakes

- Querying only the center cell (misses nearby points across the boundary).
- Using exact coordinates as cache keys.
- Treating this like ride sharing (moving objects need a different update strategy).

## 11. Follow-ups

1. **Moving objects:** see 08 (drivers update every few seconds; in-memory grid).
2. **Polygons (delivery zones):** point-in-polygon tests on candidate zones from an R-tree or S2 covering.
3. **Personalized ranking:** user preferences and history.

See [LLD.md](LLD.md) for geohash encoding and neighbors, a geohash index, a quadtree, and both validated against brute force.
