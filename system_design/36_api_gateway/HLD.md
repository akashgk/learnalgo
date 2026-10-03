# API Gateway (Kong / AWS API Gateway / Envoy edge): High-Level Design

**Asked at:** Amazon, Google, Netflix, Uber, Stripe, Cloudflare. **Core topics:** a single entry point for many services: routing, authentication, rate limiting, load balancing, retries and timeouts, circuit breakers, canary releases, observability; data plane vs control plane.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Who calls it? | Mobile/web clients and third-party developers (API keys/OAuth). |
| Behind it? | ~200 microservices, each with several instances. |
| Traffic? | ~500K requests/s at peak. |
| Features? | Routing by path/host/method, auth, per-client rate limits, load balancing, retries, circuit breaking, request/response transformation, canary routing, logging/metrics/tracing. |
| Latency budget? | A few milliseconds added at p99. |

## 2. Requirements

**Functional:** route requests to the right service; authenticate and authorize; enforce quotas; balance load across healthy instances; protect services from failing dependencies; support gradual rollouts; emit telemetry.

**Non-functional:** very low overhead, highly available (it is in front of everything), horizontally scalable, configuration changes without restarts, secure by default.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Requests | 500K/s | stateless gateway nodes at ~10-20K req/s each: **~25-50 nodes** plus headroom |
| Rate-limit state | 10 M API keys x small buckets | Redis cluster or local approximations (see 02) |
| Logs | 500K/s x 500 B | **~250 MB/s** to the log pipeline (sampled) |

## 4. Architecture

```text
 clients --> DNS / anycast --> L4 load balancers --> Gateway nodes (stateless data plane)
                                                       per request: TLS termination -> route match ->
                                                       auth (JWT verify / API key lookup, cached) ->
                                                       rate limit (local + Redis) -> transform ->
                                                       pick instance (LB strategy, health, circuit state) ->
                                                       timeout/retry -> response -> metrics/logs/traces
                                                                 |
                                                     service instances (via service discovery)
 Control plane: route and policy configuration (versioned, validated) --push--> gateway nodes (hot reload)
                service discovery (instances + health) --push--> gateway nodes
```

## 5. Deep dive: routing

- Match on host, method and path; **most specific route wins** (`/users/:id/orders` before `/users/:id`, exact before prefix). Compile routes into a trie for fast matching.
- Path parameters are extracted and can be forwarded as headers.
- Versioned APIs (`/v1`, `/v2`) and header-based routing (canaries, tenants).

## 6. Deep dive: resilience

- **Timeouts** on every upstream call, shorter than the client's.
- **Retries** only for idempotent requests (GET, PUT with idempotency keys), on a different instance, with a retry budget (e.g. at most 10% extra load) so retries do not amplify an outage.
- **Circuit breakers** per upstream instance or service: after N consecutive failures, stop sending traffic for a cool-down (open), then allow a trial request (half-open); success closes the circuit. Fail fast instead of piling up waiting requests.
- **Load balancing:** round robin, least outstanding requests, or power-of-two-choices; only healthy instances (active health checks plus passive outlier detection).

## 7. Deep dive: security and quotas

- Authentication at the edge (JWT signature verification with cached keys, or API key lookup), passing a verified identity header to services; services still authorize business actions.
- Rate limits per API key / user / IP (see 02); return `429` with `Retry-After`.
- Request size limits, header normalization, WAF rules for common attacks.

## 8. Deep dive: canary releases

Route a percentage of traffic to the new version, chosen by a **stable hash of the user ID** so a user stays on one version (no flip-flopping between versions mid-session). Increase gradually while watching error rates; roll back by changing the weight in the control plane.

## 9. Failure modes

| Failure | Behavior |
|---|---|
| Gateway node dies | L4 load balancer removes it; nodes are stateless. |
| Bad configuration pushed | Validate before applying; staged rollout of config; instant rollback to the previous version. |
| Upstream service failing | Circuit breaker opens; fast 503s; retry budget prevents storms. |
| Redis (rate limits) down | Fall back to local per-node limits (fail open with approximate limits). |

## 10. What interviewers look for

- The request pipeline (route, auth, limit, balance, call, observe).
- Resilience patterns used correctly: timeouts, idempotent-only retries with budgets, circuit breakers.
- Data plane vs control plane; hot configuration reload.
- Canary routing that is sticky per user.

## 11. Common mistakes

- Retrying non-idempotent POSTs.
- Business logic in the gateway.
- A single gateway instance or a gateway that keeps per-request state.
- Random per-request canary assignment (users bounce between versions).

## 12. Follow-ups

1. **GraphQL / backend-for-frontend:** aggregation of several service calls per client request.
2. **Service mesh:** the same features as sidecars for service-to-service traffic.
3. **mTLS to upstreams** and certificate rotation.

See [LLD.md](LLD.md) for route matching with parameters, a middleware chain (auth and rate limit), load balancing, idempotent-only retries, circuit breakers and sticky canary routing.
