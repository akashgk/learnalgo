# Metrics Monitoring and Alerting (Prometheus / Datadog): High-Level Design

**Asked at:** Google, Amazon, Datadog, Uber, Netflix, Meta. **Core topics:** time-series data model and storage, push vs pull collection, label cardinality, compression, downsampling and retention, query and aggregation, alert evaluation and notification.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| What is monitored? | Infrastructure and service metrics (CPU, memory, request rate, latency, errors) from ~100K hosts/containers. Logs and traces are separate systems (see 26 for logs). |
| Data model? | Numeric samples: metric name + labels + timestamp + value. |
| Resolution? | 10 s scrape interval; raw data kept 15 days; downsampled (1 min, 1 h) kept 1 year+. |
| Queries? | Dashboards (last hours/days), ad hoc queries, alert rules evaluated every 30 s. |
| Alerts? | Threshold rules with a duration, routed to on-call (pager, chat, email) with deduplication. |

## 2. Requirements

**Functional:** collect metrics, store, query with label filters and aggregations (sum, avg, rate, percentiles), dashboards, alert rules with notifications.

**Non-functional:** write-heavy at very high volume, fast queries on recent data, high availability for alerting (monitoring must stay up when production is down), cost-efficient storage.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Active series | 100K hosts x ~1,000 series each | **~100 M series** |
| Samples ingested | 100 M / 10 s | **~10 M samples/s** |
| Raw size | 16 B per sample uncompressed; ~1.4 B with Gorilla compression | 10 M x 1.4 B x 86,400 ≈ **~1.2 TB/day** compressed |
| 15 days raw | | **~18 TB** |
| Downsampled 1-min for a year | 1/6 of samples, x5 aggregates (min/max/sum/count/last) | **~25 TB/year** |

## 4. Data model

```text
http_requests_total{service="checkout", method="POST", status="500", instance="10.0.3.7:9100"}  @t  value
\_________________/ \______________________________________________________________________/
   metric name                          labels (the set identifies one time series)
```

- **Counter** (only goes up; reset on restart; query with `rate()`), **gauge** (up and down), **histogram** (bucket counters for percentiles).
- **Cardinality** = number of distinct label combinations. Putting user IDs or request IDs in labels explodes it; this is the most common way to break a metrics system. Enforce limits per metric and per tenant.

## 5. Collection: pull vs push

| | Pull (Prometheus scrapes `/metrics`) | Push (agents send to a gateway, StatsD/Datadog) |
|---|---|---|
| Pros | the monitor controls the rate; "target down" is detectable; easy to debug | works through firewalls/NAT, for short-lived jobs, from clients |
| Cons | needs service discovery; hard for batch jobs | senders can overload the backend; needs auth and rate limiting |

Either way, a collection tier buffers into Kafka before storage so ingestion spikes do not hurt the database.

## 6. Architecture

```text
 targets (/metrics) <--scrape-- collectors (sharded by target, service discovery)
 agents --push--> ingestion gateway (auth, rate limit, cardinality checks)
                          |
                          v
                    Kafka (partitioned by series hash)
                          |
            +-------------+-----------------+
            v                               v
   TSDB ingesters (in-memory head block,   stream evaluator for low-latency alerts (optional)
   WAL, 2-hour blocks flushed to object storage)
            |
   compactor: merges blocks, downsamples to 1m/1h, applies retention
            |
   query service: fan out to ingesters (recent) + object storage blocks (older), merge, aggregate
            |                        |
       dashboards (Grafana)     rule evaluator (every 30 s) --> Alertmanager: dedup, group, silence, route --> pager/chat/email
```

## 7. Deep dive: storage

- **Time-series database:** per series, append-only chunks of samples. Timestamps compress with **delta-of-delta** (scrapes are regular, so most deltas-of-deltas are 0); values compress with **XOR of consecutive floats** (Facebook Gorilla): ~1.4 bytes per sample.
- **Inverted index** from label pairs to series IDs (like a search engine, see 22) to answer `{service="checkout", status=~"5.."}`.
- **Blocks:** the last ~2 hours in memory (with a write-ahead log), then immutable blocks on disk/object storage; compaction merges them.
- **Downsampling:** old data kept at 1-minute and 1-hour resolution with min, max, sum, count (enough for averages and extremes); raw data deleted after the retention period.

## 8. Deep dive: queries

- `rate(http_requests_total[5m])`: per-second increase over 5 minutes, handling counter resets.
- `sum by (service) (...)`: aggregate across series sharing the `service` label.
- Percentiles from histogram buckets (`histogram_quantile`), not by averaging percentiles (mathematically wrong).
- Query cost grows with series x time range: cache results for dashboards, use downsampled data for long ranges, limit series per query.

## 9. Deep dive: alerting

- A rule: `expr > threshold for 5m`. States per series: **inactive -> pending** (condition true, waiting out the duration) **-> firing -> resolved**.
- The `for` duration suppresses flapping on brief spikes.
- **Alertmanager:** deduplicates identical alerts from redundant evaluators, groups related alerts into one notification, applies silences and inhibition (a "datacenter down" alert suppresses its thousand host alerts), routes by labels (team, severity).
- **Meta-monitoring:** monitor the monitoring system from outside (a dead man's switch alert that must keep firing; silence means monitoring is broken).

## 10. Failure modes

| Failure | Behavior |
|---|---|
| Ingester crash | Replay WAL; Kafka retains data meanwhile; replication factor 2-3 for ingesters. |
| Cardinality explosion | Gateway rejects new series beyond the limit for that metric; alert the owning team. |
| Query of death (huge range) | Per-query limits on series and samples; timeouts. |
| Alerting path down | Redundant rule evaluators and Alertmanager cluster; dead man's switch. |

## 11. What interviewers look for

- The data model and the cardinality danger.
- Write-optimized storage with compression and blocks; downsampling and retention.
- Pull vs push trade-offs.
- Alert states with `for`, deduplication and routing.

## 12. Common mistakes

- Storing every sample as a row in a relational database.
- Labels with unbounded values (user IDs).
- Averaging percentiles.
- Alerting on raw instantaneous values without a duration (alert storms).

## 13. Follow-ups

1. **Multi-tenancy:** per-tenant quotas and isolation (Cortex/Mimir).
2. **Anomaly detection:** seasonal baselines instead of static thresholds.
3. **SLOs:** error-budget burn-rate alerts.
4. **Exemplars:** link a latency spike to a trace ID.

See [LLD.md](LLD.md) for series identity, label matching, `rate` with counter resets, aggregation, downsampling, retention, cardinality limits and an alert state machine.
