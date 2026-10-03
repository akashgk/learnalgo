# Feature Flags and Gradual Rollouts (LaunchDarkly / Unleash / internal config systems): High-Level Design

**Asked at:** Meta, Google, Uber, Airbnb, Atlassian, LaunchDarkly. **Core topics:** local evaluation in SDKs, deterministic percentage bucketing, targeting rules, propagating changes in seconds (streaming), kill switches, experiments and exposure logging, safety and auditing.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Use cases? | Release toggles, gradual rollouts (1% -> 100%), kill switches for incidents, A/B experiments, per-customer entitlements. |
| Clients? | Backend services (thousands of instances) and mobile/web apps (millions of devices). |
| Evaluations? | Very high: every request may check several flags: billions per day. |
| Propagation? | A flag change reaches all servers within seconds (kill switch!). |
| Availability? | If the flag service is down, applications keep working with the last known rules. |

## 2. Requirements

**Functional:** create flags with variations; targeting by user attributes, segments and individual users; percentage rollouts; prerequisites; environments (dev, staging, prod); audit log; experiment exposure tracking.

**Non-functional:** evaluation in microseconds (no network call per evaluation), consistent assignment (a user stays in the same bucket), fast propagation, high availability, safe changes (approvals, history, rollback).

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Evaluations | 1 M requests/s x ~5 flags | **5 M evaluations/s**: must be local, in-process |
| Flag rules payload | ~2,000 flags x ~2 KB | **~4 MB** per environment: every SDK holds it all |
| Streaming connections | ~50K server instances + millions of client devices | SSE/WebSocket fan-out via edge relays/CDN |
| Exposure events | sampled/deduplicated | **~100K events/s** into the analytics pipeline |

## 4. Architecture

```text
 dashboard / API --> Flag service (rules DB, versioned, audit log, approvals)
                         |  publish change (version N)
                         v
                 streaming relays (SSE) + CDN snapshot of all rules per environment
                         |
     server SDK (in each service): holds all rules in memory, evaluates locally,
                                   applies updates by version, falls back to last snapshot on disk
     client SDK (mobile/web): asks an edge evaluator for its own flag values (rules stay server-side)
                         |
                 exposure events (sampled, deduplicated) --> analytics / experiment results
```

## 5. Deep dive: evaluation order

1. Flag **off** (kill switch) -> off variation.
2. **Prerequisites:** another flag must evaluate to a given variation.
3. **Individual targets:** user keys explicitly listed.
4. **Rules** in order: conditions on attributes (country in [DE, FR], plan = enterprise, app version >= 5.2) -> a variation or a percentage rollout.
5. **Default rule** (fallthrough): a variation or a percentage rollout.

Every evaluation returns the value **and the reason** (which rule matched): essential for debugging "why does this user see X?".

## 6. Deep dive: percentage rollouts

- Bucket = `hash(flagKey + salt + userKey) mod 100000`. Deterministic: the same user always gets the same bucket; no state stored per user.
- **Monotonic rollouts:** buckets 0-19,999 = 20%. Increasing to 50% keeps everyone already in the 20% inside; nobody flips back.
- **Per-flag salt:** different flags bucket independently, so the same users are not always the guinea pigs.
- Bucket by the right unit: user, organization (all members together), or device.

## 7. Deep dive: propagation and resilience

- SDKs receive the full rule set on startup (from CDN), then incremental updates over a stream; each update has a version, older versions are ignored.
- On disconnect: keep serving last known rules; reconnect with backoff; periodic full refresh to repair drift.
- **Kill switch** latency: streaming delivers within seconds; for mobile clients, the edge evaluator applies it on the next request.

## 8. Deep dive: safety

- Audit log of every change; required approvals for production; scheduled changes; automatic rollback if error rates spike after a change (guarded rollouts).
- Flag hygiene: track last evaluation time; alert on stale flags to remove technical debt.

## 9. Failure modes

| Failure | Behavior |
|---|---|
| Flag service down | SDKs keep last rules; no impact on applications. |
| SDK starts without network | Uses the on-disk snapshot or code defaults. |
| Bad flag change | Rollback to the previous version (versioned rules); auto-rollback on metrics. |
| Streaming relay overload | Clients fall back to polling the CDN snapshot. |

## 10. What interviewers look for

- Local evaluation with replicated rules (no network per check).
- Deterministic, salted, monotonic bucketing.
- Ordered evaluation with reasons.
- Fast propagation, versioned updates, and graceful degradation.

## 11. Common mistakes

- Calling a remote service per flag evaluation.
- Random assignment per request (users flip between variants).
- Same hash for every flag (always the same 1% of users get every experiment).
- No audit trail or kill switch.

## 12. Follow-ups

1. **Experiments:** exposure logging, metrics joins, statistical significance.
2. **Mutually exclusive experiments:** layers/namespaces split traffic.
3. **Server-side config values** (not just booleans): JSON variations with schemas.

See [LLD.md](LLD.md) for flags with variations, ordered rules, individual targets, prerequisites, salted percentage bucketing, evaluation reasons and versioned SDK updates.
