# Rate Limiter: High-Level Design

**Asked at:** Google, Amazon, Stripe, Cloudflare, and as a component inside other designs. **Core topics:** limiting algorithms, distributed counters, atomicity, failure policy.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Client-side or server-side? | Server-side (clients cannot be trusted). |
| Limit by what? | By API key or user ID; by IP for unauthenticated traffic; rules can differ per endpoint. |
| Scale? | ~1 M requests/s across the fleet, ~10 M distinct active keys. |
| Exactness? | Approximately right is fine (a few percent over the limit occasionally is acceptable); never block far below the limit. |
| What happens to a rejected request? | HTTP 429 with `Retry-After`; rejections are logged. |
| Rules changed at runtime? | Yes, without redeploying. |
| Distributed? | Yes: many API servers must share the same counters. |

## 2. Requirements

**Functional:** decide allow/deny per request based on configurable rules such as "100 requests per minute per API key on `/search`".

**Non-functional:**

- **Low latency:** the check is on every request's path; target ~1 ms added latency.
- **Highly available:** if the limiter is down, the API must still work (see "fail open" below).
- **Accurate across servers:** a client hitting 50 servers must not get 50x its limit.
- **Memory efficient:** 10 M keys.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Checks per second | one per request | **1 M/s** (plus peak headroom) |
| State per key (token bucket) | key (~40 B) + tokens + timestamp (16 B) + store overhead (~50 B) | **~100 B** |
| Total state | 10 M keys x 100 B | **~1 GB**, fits in memory on a small Redis cluster |
| Redis throughput | a Redis shard handles ~100K simple ops/s | **~10+ shards** for 1 M/s, sharded by key |

## 4. Where does the limiter live?

```text
Option A: in each API server (library)        Option B: API gateway / middleware        Option C: sidecar (service mesh)

client -> LB -> [API server + limiter lib]    client -> LB -> [gateway: limiter] -> API   client -> LB -> [proxy+limiter | API]
                         |                                        |                                         |
                         +--------- shared counter store (Redis cluster) ------------------------------------+
```

The gateway (B) is the common answer: one place to enforce limits for every service, and services stay unaware. A library (A) gives the service fine-grained control. All options need the **shared counter store** for accuracy across instances.

## 5. Algorithms (the main discussion)

| Algorithm | Idea | Memory per key | Burst behavior | Accuracy |
|---|---|---|---|---|
| **Token bucket** | bucket of capacity B refills at r tokens/s; a request takes a token | 2 numbers | allows bursts up to B, then rate r | good |
| Leaky bucket | queue drained at a constant rate | queue | smooths output to exactly rate r; adds delay | good |
| **Fixed window counter** | count requests per calendar window (e.g. per minute) | 1 number | 2x burst at window edges (100 at 0:59 + 100 at 1:00) | edge problem |
| Sliding window log | store each request timestamp; count those within the last window | O(limit) per key | exact | exact, memory heavy |
| **Sliding window counter** | weighted sum: `prev_window_count * overlap + current_count` | 2 numbers | smooths the edge problem | approximate (assumes even spread in the previous window) |

**Recommendation:** token bucket for most APIs (simple, two numbers, allows reasonable bursts, used by AWS and Stripe). Sliding window counter if the edge burst of fixed windows matters but logs are too expensive.

## 6. Distributed counting: race conditions and atomicity

With a shared Redis, a naive "read count, check, write count + 1" from two servers at once lets both through on the last slot. The check-and-update must be **atomic**:

- **Fixed window:** `INCR key:window` then `EXPIRE` on first creation; `INCR` is atomic. Compare the returned value with the limit.
- **Token bucket / sliding window:** a **Lua script** executed by Redis atomically: read state, refill, decide, write state, all in one server-side operation (Redis runs one script at a time per shard).
- Keys for one user stay on one shard (hash the key), so each check is one round trip to one shard.

```text
API server --EVALSHA token_bucket.lua key capacity rate now--> Redis shard (by hash(key))
           <-- {allowed: 1, remaining: 42, retry_after_ms: 0} --
```

**Clock source:** use the Redis server time (or pass a timestamp and tolerate small skew); never trust the client's clock.

## 7. Reducing latency and load

- **Local pre-check:** each server keeps an in-memory approximate counter and only consults Redis near the limit, or synchronizes counts every few hundred milliseconds. Trades accuracy (a key can exceed its limit by up to `servers x sync interval x rate`) for far fewer Redis calls.
- **Batching:** take several tokens at once from Redis and spend them locally.
- **Pipelining** multiple rule checks for one request in one round trip.

## 8. Rules and configuration

```text
rules (stored in a config service / DB, cached in every gateway, refreshed on change)
  - match: { endpoint: "/search", tier: "free" }  limit: 100 per 60s   algorithm: token_bucket burst: 20
  - match: { endpoint: "/login",  by: "ip" }      limit: 10  per 60s
  - match: { by: "api_key" }                       limit: 10000 per 60s (global default)
```

A request may match several rules (per endpoint and global); it must pass **all** of them.

## 9. Responses

```text
HTTP 429 Too Many Requests
Retry-After: 12
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1735689660
```

Headers on successful responses too, so well-behaved clients can slow down before hitting the limit.

## 10. Failure modes

| Failure | Policy |
|---|---|
| Redis shard down or slow | **Fail open** for most endpoints (allow the request, log it): a rate limiter outage should not become an API outage. **Fail closed** for abuse-sensitive endpoints (login, password reset, SMS sending). Use a short timeout (a few ms) on the Redis call. |
| Hot key (one huge customer) | That key's shard gets heavy; use local batching for that key, or split the key's budget across N sub-keys. |
| Clock skew between servers | Use the Redis server time inside the Lua script. |
| Retry storms | `Retry-After` plus clients with exponential backoff and jitter. |

## 11. What interviewers look for

- Knowing several algorithms and **choosing** one with a reason.
- Spotting the race condition in a shared counter and fixing it with atomic operations (`INCR`, Lua).
- A clear fail-open / fail-closed policy.
- Where the limiter sits, and how rules are configured.

## 12. Common mistakes

- A per-server in-memory limiter presented as a complete solution (each server allows the full limit, so N servers allow N times the limit).
- Read-then-write against Redis without atomicity.
- Forgetting key expiry (memory grows forever with old windows).
- Making Redis a hard dependency with no timeout.

## 13. Follow-ups

1. **Different limits per pricing tier.** Rule matching on the customer's tier, cached in the gateway.
2. **Global (multi-region) limits.** Per-region budgets (split the limit), or asynchronous cross-region counter sync with some overshoot accepted.
3. **Throttling instead of rejecting.** Leaky bucket queue with a maximum wait.
4. **Concurrency limits** (at most N in-flight requests). A counter incremented on start and decremented on finish, with leases that expire if a server dies.

See [LLD.md](LLD.md) for the class design and runnable implementations of four algorithms.
