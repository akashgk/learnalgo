# Maps and Navigation (Google Maps / Apple Maps / Waze): High-Level Design

**Asked at:** Google, Apple, Uber, Lyft, Grab, Amazon. **Core topics:** map tiles and zoom levels, the road network as a weighted graph, shortest paths at continental scale (Dijkstra, A*, contraction hierarchies, graph partitioning), live traffic and ETAs, rerouting, geocoding.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Features? | Display maps, search places/addresses (geocoding), driving directions with ETA, turn-by-turn navigation with live traffic and rerouting. |
| Scale? | 1 B monthly users; ~100 M route requests/day; 50 M navigating at peak sending location every few seconds. |
| Coverage? | Global road network: ~1 B road segments. |
| Latency? | Route in < 1 s; map tiles in tens of milliseconds (cached). |
| Freshness? | Traffic reflected within a few minutes. |

## 2. Requirements

**Functional:** render maps at many zoom levels, geocode, compute routes (fastest/shortest, avoid tolls), ETA, navigation with rerouting, traffic.

**Non-functional:** low latency, high availability, accurate ETAs, efficient bandwidth on mobile (vector tiles, caching), offline maps (follow-up).

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Route requests | 100 M/day | **~1,200/s** avg, ~5K/s peak |
| Location pings during navigation | 50 M / 5 s | **~10 M/s** |
| Road graph | ~1 B edges x ~50 B | **~50 GB** (fits in memory across a few large machines, partitioned) |
| Tiles | zoom 0-21: tile count grows 4x per level | precomputed for low zooms; generated/cached on demand for high zooms; served by CDN |

## 4. Architecture

```text
 app --> CDN --> tile service (vector tiles per zoom/x/y, precomputed + cached)
     --> geocoding/search service (address and POI index, see 22/23)
     --> routing service (in-memory road graph with preprocessed shortcuts; traffic-weighted)
     --> navigation session service (tracks progress, detects off-route, reroutes, pushes ETA updates)
 location pings --> ingestion (Kafka) --> map matching (snap GPS to road segments)
                 --> traffic aggregation (speed per segment per minute) --> edge weights in routing
                 --> historical speeds (per segment, per time of week) for future ETA prediction
```

## 5. Deep dive: map tiles

- The world is projected (Web Mercator) and cut into square tiles: at zoom z there are 2^z x 2^z tiles. A tile address is `(z, x, y)`.
- **Vector tiles** (geometry + attributes, styled on the device) are much smaller than images and allow rotation and theming.
- Low zooms are precomputed; high zooms for busy areas are cached; tiles are immutable per map version, so CDN caching is very effective.

## 6. Deep dive: routing

| Algorithm | Idea | Cost |
|---|---|---|
| Dijkstra | expand nodes in order of distance from the source | explores a circle around the source; far too slow continent-wide |
| **A*** | Dijkstra plus a lower-bound estimate of the remaining cost (straight-line distance / max speed) | explores an ellipse toward the target; still large for long routes |
| ALT (A* with landmarks) | better lower bounds from precomputed distances to landmarks | faster; more memory |
| **Contraction hierarchies** | preprocess: contract unimportant nodes, add shortcut edges; query searches "upward" from both ends | queries in milliseconds over a continent; preprocessing takes hours |
| Partitioned graphs (CRP) | precompute distances across cell boundaries; traffic updates only recompute cells | fast and supports frequent weight changes |

**Live traffic** changes edge weights constantly, which breaks heavy preprocessing; systems use customizable approaches (CRP) or apply traffic on top of a precomputed structure.

## 7. Deep dive: ETAs and traffic

- GPS pings are **map-matched** to road segments (hidden Markov models handle noisy GPS).
- Current speed per segment = aggregate of recent pings; combined with historical speed for the same time of week to predict the speed when the driver actually reaches that segment (ETA is about the future).
- ETAs are corrected by ML models trained on actual trip durations.

## 8. Deep dive: navigation sessions

- The device follows the route locally (works through brief connectivity loss); it reports position periodically.
- **Off-route detection:** distance from the route polyline beyond a threshold for a few fixes triggers a reroute from the current position.
- Server pushes better routes when traffic changes significantly (e.g. accident ahead).

## 9. Failure modes

| Failure | Behavior |
|---|---|
| Routing node down | Replicas of each graph partition behind a load balancer. |
| Traffic pipeline delayed | Fall back to historical speeds. |
| Device offline | Continue with the downloaded route and cached tiles; resync later. |
| Bad map data (closed road) | User reports and trip data detect anomalies; edge disabled via a hot patch. |

## 10. What interviewers look for

- Tiles with zoom levels and CDN caching.
- Graph search beyond plain Dijkstra (A*, contraction hierarchies or partitioning) and why.
- Traffic from location pings feeding edge weights and ETAs.
- Rerouting during navigation.

## 11. Common mistakes

- Running plain Dijkstra over the world graph per request.
- Storing the road graph in a relational database and querying it per step.
- Ignoring that ETAs must predict future traffic.

## 12. Follow-ups

1. **Offline maps:** downloadable region packs of tiles and a routing graph.
2. **Multi-modal routing:** transit timetables (time-dependent graphs), walking, cycling.
3. **Fleet routing:** vehicle routing problems for deliveries (heuristics, not exact).

See [LLD.md](LLD.md) for tile coordinates, a road graph, Dijkstra vs A* (same answers, fewer expansions), traffic-weighted rerouting and ETAs.
