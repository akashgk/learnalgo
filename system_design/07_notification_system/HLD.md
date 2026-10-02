# Notification System: High-Level Design

**Asked at:** Amazon, Uber, LinkedIn, Meta, Stripe. **Core topics:** queues and workers, multiple channels (push, SMS, email), user preferences, retries with backoff, idempotency, rate limiting, third-party provider failures.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Channels? | Mobile push (APNs / FCM), SMS, email. In-app inbox as a follow-up. |
| Who sends? | Internal services (orders, payments, social, marketing) through one API. |
| Types? | Transactional (OTP, order shipped: urgent, must arrive) and marketing (bulk campaigns: can wait, can be dropped). |
| Scale? | ~10 M notifications/day normally; campaigns of 50 M in an hour. |
| Delivery guarantee? | At-least-once to the provider, with deduplication so users do not get duplicates in practice. |
| User control? | Per-user, per-category, per-channel opt-out; quiet hours. |
| Real-time? | OTPs within seconds; marketing within hours. |

## 2. Requirements

**Functional:** `send(userId, templateId, params, category, channels?)`; template rendering with localization; respect preferences and opt-outs; retries; delivery status tracking; scheduling.

**Non-functional:**

- **Reliable:** an accepted notification is not lost (persisted before acknowledging).
- **No duplicates** from retries (idempotency).
- **Priority isolation:** a 50 M marketing campaign must not delay OTPs.
- **Resilient to provider outages and rate limits.**
- **Scalable** to bursty traffic.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Normal rate | 10 M / 86,400 | **~115/s** |
| Campaign burst | 50 M / 3,600 | **~14K/s** |
| Provider limits | e.g. an SMS provider at 1K/s per account; APNs/FCM much higher | campaigns must be **throttled**, so queues absorb the burst |
| Log storage | 10 M x ~500 B per status record x 90 days | **~450 GB** |
| Cost | SMS costs ~cents each; email and push ~free | SMS volume is a business decision; prefer push |

The design is about **buffering and isolation**, not raw throughput: providers are the bottleneck.

## 4. API

```text
POST /v1/notifications
  { "idempotencyKey": "order-123-shipped",
    "userId": "u42", "category": "order_updates", "templateId": "order_shipped",
    "params": { "orderId": "123", "eta": "Friday" },
    "channels": ["push", "email"]?,            (default: the category's channels)
    "priority": "high" | "normal" | "low",
    "sendAt": "2025-01-01T09:00:00Z"? }
  202 Accepted { notificationId }            (accepted and persisted, not yet delivered)

GET /v1/notifications/{id}  -> per-channel status: queued / sent / delivered / failed / skipped(reason)
```

## 5. Data model

```text
notifications(id, idempotency_key UNIQUE, user_id, category, template_id, params, priority, send_at, created_at)
deliveries(notification_id, channel, status, attempts, last_error, provider_message_id, updated_at)
preferences(user_id, category, channel, enabled)         + quiet hours, timezone
devices(user_id, device_token, platform, last_seen)      -- push tokens; remove invalid ones
contacts(user_id, email, phone, verified)
templates(template_id, channel, locale, subject, body, version)
```

## 6. Architecture

```text
 services --> Notification API --(1) dedupe on idempotency key, persist--> DB
                    |
                    v (2) enqueue by priority
             +------------------+
             | Kafka / SQS      |   topics: high, normal, low
             +------------------+
                    |
                    v
             Router workers: (3) load user prefs, contacts, device tokens
                             (4) drop opted-out channels, defer for quiet hours
                             (5) render template per channel and locale
                    |
        +-----------+------------+
        v           v            v       per-channel queues (isolation)
   push queue   SMS queue   email queue
        |           |            |
   push workers  SMS workers  email workers  -- rate-limited per provider, retries with backoff
        |           |            |
      APNs/FCM   Twilio/SNS   SES/SendGrid
        |           |            |
        +---- provider callbacks / receipts --> status updates --> deliveries table, analytics

   failed after max retries --> dead-letter queue --> alert / manual replay
   Scheduler: polls notifications with send_at <= now and enqueues them
```

## 7. Deep dives

**Idempotency.** Callers retry on timeouts. The `idempotencyKey` has a unique constraint; a duplicate request returns the original `notificationId` without enqueueing again. Inside the pipeline, each delivery has a stable ID passed to providers that support deduplication; workers check the `deliveries` status before sending, so a redelivered queue message for an already-sent delivery is skipped. Exactly-once to the user's phone is impossible in general (the provider may succeed after our timeout); at-least-once with deduplication gets close.

**Retries.** Transient errors (timeouts, 5xx, 429) retry with **exponential backoff and jitter**: `delay = base x 2^attempt` plus random jitter, capped, for a maximum number of attempts, then the dead-letter queue. Permanent errors (invalid token, unsubscribed email, invalid number) are not retried; invalid push tokens are deleted.

**Priority and isolation.** Separate queues per priority and per channel, with dedicated worker pools. A marketing campaign fills the low-priority email queue; OTPs travel through the high-priority SMS queue untouched. An SMS provider outage backs up only the SMS queue.

**Rate limiting.** Outbound: token buckets per provider account (see 02 Rate Limiter). Per user: caps like "at most 3 marketing pushes per day" to avoid spamming.

**Provider failover.** Two SMS providers behind a `SmsProvider` interface; a circuit breaker on each. When one's error rate crosses a threshold, route to the other.

**Preferences and quiet hours.** Checked by the router at send time, not at request time, because preferences can change while a notification waits. Quiet hours defer non-urgent notifications to the user's morning (in the user's time zone).

**Templates.** Stored with versions and locales; rendered by the router so channels get the right format (SMS length limits, email HTML, push title/body).

## 8. Failure modes

| Failure | Behavior |
|---|---|
| API server crashes after accepting | Accepted means persisted; a sweeper re-enqueues persisted but unqueued notifications (or use a transactional outbox). |
| Worker crashes mid-send | The queue redelivers; the delivery status check skips if already sent; otherwise a possible duplicate (accepted risk). |
| Provider down | Circuit breaker opens; failover provider or queue backs up; retries resume later. |
| Campaign floods the system | Separate low-priority queues and throttled workers. |
| Bad template deployed | Rendering errors go to the DLQ, alerting; versioned templates allow rollback. |

## 9. What interviewers look for

- Asynchronous pipeline with queues; 202 Accepted.
- Idempotency keys and retry with backoff, distinguishing transient from permanent errors.
- Isolation of priorities and channels.
- Preferences, opt-outs, and rate limits as first-class concerns.
- Provider failures handled (circuit breaker, failover, DLQ).

## 10. Common mistakes

- Calling providers synchronously inside the request.
- One queue for everything (a campaign blocks OTPs).
- Retrying permanent failures forever; retrying without backoff (amplifies outages).
- Checking preferences only at request time.
- Claiming exactly-once delivery.

## 11. Follow-ups

1. **In-app notification inbox:** store per user, mark read, unread badge counts (similar to chat watermarks).
2. **Digest / batching:** combine "5 people liked your post" into one notification within a time window.
3. **Analytics:** open and click tracking via provider webhooks and tracked links.
4. **Global users:** regional deployments and data residency for contact data.

See [LLD.md](LLD.md) for the classes: channels, templates, preferences, retry policy and idempotency.
