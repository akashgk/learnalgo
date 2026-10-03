# Content Delivery Network (Cloudflare / Akamai / CloudFront): High-Level Design

**Asked at:** Cloudflare, Akamai, Amazon, Google, Netflix, Fastly. **Core topics:** edge locations and request routing (anycast, DNS), cache hierarchies (edge -> regional shield -> origin), cache keys and HTTP caching semantics, invalidation, request coalescing, stale-while-revalidate, TLS at the edge, DDoS absorption.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Content? | Static assets, images, video segments (see 12), and cacheable API responses. |
| Customers? | Many websites (multi-tenant), each with an origin server. |
| Scale? | 300 edge locations (PoPs); ~50 M requests/s; ~100 Tbps peak egress. |
| Goals? | Low latency (serve near users), offload origins (high hit ratio), absorb attacks. |
| Freshness? | Respect origin `Cache-Control`; purge on demand within seconds. |

## 2. Requirements

**Functional:** route users to a nearby PoP, serve cached content, fetch misses from origin, honor caching headers, purge by URL or tag, TLS termination, custom rules per customer.

**Non-functional:** very low latency, high hit ratio, origin protection, high availability (a PoP failure is invisible), security (DDoS, WAF).

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Requests per PoP | 50 M/s / 300 | **~170K/s** per PoP (dozens of servers each) |
| Egress per PoP | 100 Tbps / 300 | **~330 Gbps** per PoP |
| Cache per server | RAM for hot objects (~256 GB) + SSD (~20-50 TB) | hot set in RAM, long tail on SSD |
| Origin offload | hit ratio 95% | origins see 5% of requests; shields reduce it further |

## 4. Architecture

```text
 user --DNS (geo/latency-based) or anycast IP--> nearest healthy PoP
   PoP: L4 load balancer --> edge servers (TLS, WAF, rules) --> local cache (RAM + SSD)
          miss --> (consistent hashing inside the PoP so each object is cached on one server)
          miss --> regional shield PoP (a second cache tier, few per region)
          miss --> customer origin (with request coalescing: one fetch per object at a time)
 control plane: customer configs, certificates, purge API --> pushed to all PoPs within seconds
 logs/analytics --> aggregated per customer
```

## 5. Deep dive: request routing

- **Anycast:** the same IP is announced from every PoP; BGP routes users to a nearby one; a failed PoP withdraws its announcement. Simple and resilient to DDoS (attack traffic spreads across PoPs).
- **DNS-based:** the authoritative DNS returns the IP of the best PoP for the resolver's location/latency; slower to react (DNS TTLs) but finer control.

## 6. Deep dive: caching semantics

- **Cache key:** scheme + host + path + selected query parameters (ignore tracking parameters; sort the rest) + `Vary` headers (e.g. `Accept-Encoding`). A bad cache key either leaks content between users or kills the hit ratio.
- **Freshness:** `Cache-Control: s-maxage` / `max-age`; `no-store` and `private` are never cached at a shared cache; `stale-while-revalidate` serves a stale copy while refreshing in the background; `stale-if-error` serves stale when the origin is down.
- **Conditional revalidation:** `If-None-Match` / `If-Modified-Since` with the origin returns `304 Not Modified`, saving bandwidth.

## 7. Deep dive: protecting the origin

- **Request coalescing (collapsed forwarding):** when 10,000 users request a just-expired object at once, the edge sends one origin request and the rest wait for it.
- **Origin shield:** all edges in a region miss to one shield location, so the origin sees one request per object per region, not per PoP.
- Within a PoP, consistent hashing on the cache key avoids storing the same object on every server.

## 8. Deep dive: invalidation

- **Purge by URL** or by **tag** (surrogate keys: a product page and all its images share a tag `product:42`). The purge is broadcast to all PoPs; edges drop or mark entries stale.
- **Versioned URLs** (`app.3f9a2c.js`) make invalidation unnecessary for static assets: cache them forever.

## 9. Failure modes

| Failure | Behavior |
|---|---|
| PoP down | Anycast/DNS steer users to the next PoP; hit ratio dips briefly there. |
| Origin down | `stale-if-error` serves cached content; custom error pages. |
| Thundering herd on expiry | Coalescing and stale-while-revalidate. |
| DDoS | Absorbed across all PoPs; rate limits and WAF at the edge; challenge suspicious clients. |

## 10. What interviewers look for

- Routing users to PoPs (anycast vs DNS) and failover.
- Tiered caching and request coalescing to protect origins.
- Correct cache keys and HTTP caching headers.
- Invalidation strategy (purge, tags, versioned URLs).

## 11. Common mistakes

- Caching personalized responses (missing `private`/`Vary`), leaking data between users.
- Cache keys including random query parameters (zero hit ratio).
- No protection against simultaneous misses.
- Relying on purges for assets that should be versioned.

## 12. Follow-ups

1. **Edge compute:** run small functions at the edge (auth, A/B, personalization).
2. **Video delivery:** segment caching, prefetching the next segments (see 12).
3. **Image optimization:** resize/convert at the edge, cached per variant.

See [LLD.md](LLD.md) for cache key normalization, Cache-Control handling, a byte-bounded LRU, request coalescing, stale-while-revalidate, a shield tier and purge by tag.
