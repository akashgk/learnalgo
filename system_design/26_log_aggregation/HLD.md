# Log Aggregation and Search (ELK / Splunk / Grafana Loki): High-Level Design

**Asked at:** Google, Amazon, Datadog, Splunk, Elastic, Uber. **Core topics:** collection agents, buffering with Kafka, parsing and enrichment, what to index (full-text vs labels only), time-partitioned storage tiers, retention and cost, query patterns, PII redaction.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Sources? | Application and system logs from ~50K hosts/containers. |
| Volume? | ~5 TB/day of raw logs (~5 B lines/day at ~1 KB). |
| Queries? | Debugging: filter by service, level, time range, and free text; tail live logs; count occurrences over time. |
| Freshness? | Searchable within ~10-30 seconds. |
| Retention? | 7 days hot (fast), 30 days warm, 1 year archive (compliance). |
| Compliance? | Remove or mask secrets and personal data before storage. |

## 2. Requirements

**Functional:** ship logs from every host, parse into structured fields, search by fields and text, live tail, aggregate counts, retention policies, access control per team.

**Non-functional:** never block applications (logging must not take services down), absorb bursts (an incident multiplies log volume), cost-efficient storage, reasonable query latency (seconds), durability for the retention period.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Ingest | 5 TB/day | **~60 MB/s** avg, 5-10x during incidents |
| Lines | 5 B/day | **~58K lines/s** avg |
| Hot storage (7 days, compressed ~10x) | 5 TB x 7 / 10 | **~3.5 TB**, plus index overhead |
| Full-text index | Elasticsearch-style indexes are often 0.5-1.5x the compressed data | the main cost driver |
| Archive (1 year in object storage) | 5 TB x 365 / 10 | **~180 TB** |

## 4. Architecture

```text
 app --stdout/file--> node agent (Fluent Bit / Vector): tail files, add host/pod labels, buffer on disk,
                                                       batch + compress, backpressure-aware
                          |
                          v
                  Kafka (topic per tenant/team, partitioned)   <-- absorbs incident bursts
                          |
                 processors: parse (JSON, logfmt, regex), normalize timestamps, enrich (service, region),
                             redact PII/secrets, drop/sample noisy debug logs, extract metrics
                          |
          +---------------+--------------------+
          v                                    v
  index + store (hot tier):               object storage (archive): compressed chunks by
  time-partitioned chunks + indexes        tenant/date/hour; restored on demand
          |
  query service: time range first, then label filters, then text match; fan out across partitions, merge newest-first
  live tail: subscribe directly to the Kafka stream with filters
```

## 5. Deep dive: what to index

| Approach | Index | Query | Cost |
|---|---|---|---|
| Full-text (Elasticsearch/Splunk) | every token of every line (inverted index, see 22) | fast arbitrary text search | high storage and ingest CPU |
| **Label-only (Loki)** | only a few low-cardinality labels (service, level, cluster) + time | filter chunks by labels and time, then **scan** (grep) the compressed chunk text | cheap ingest and storage; text search is brute force but parallel |

A middle ground used in the LLD: label index + a small token set per chunk (a Bloom-filter-like summary) so chunks that cannot contain the search term are skipped.

## 6. Deep dive: storage and retention

- **Time-partitioned chunks** (e.g. per stream per hour): queries almost always have a time range, so they touch few chunks. Retention = delete whole old chunks (no per-line deletes).
- **Tiers:** hot (SSD, indexed), warm (cheaper disks, maybe less indexing), cold (object storage, restored for investigations).
- **Compression:** logs are repetitive; zstd/gzip give ~10x.

## 7. Deep dive: protecting the system and the apps

- Agents use bounded buffers; if the pipeline is slow, they drop (and count drops) rather than block the app or fill the disk.
- **Per-tenant rate limits and quotas** at ingest (one noisy service in a crash loop must not starve others).
- **Sampling** for very chatty debug logs; never for errors and audit logs.
- **PII/secret redaction** at the processor stage (emails, card numbers, tokens), before anything is stored.

## 8. Deep dive: making logs useful

- Structured logging (JSON/logfmt with consistent field names) instead of free text.
- Correlation IDs (trace IDs) in every line to join logs across services.
- **Log patterns:** cluster lines into templates (`user <*> logged in from <*>`) to see which messages are new or spiking during an incident.

## 9. Failure modes

| Failure | Behavior |
|---|---|
| Kafka slow/unavailable | Agents buffer on local disk up to a cap, then drop with counters. |
| Indexer behind | Kafka retains data; ingest lag alert; searches show slightly older data. |
| Query too broad | Require a time range; cap scanned bytes; return partial results with a warning. |
| Log storm (incident) | Rate limits per tenant; sampling of debug; Kafka absorbs the burst. |

## 10. What interviewers look for

- An asynchronous, buffered pipeline that cannot hurt the applications.
- An indexing strategy chosen with its cost trade-off.
- Time partitioning, tiers and retention.
- Redaction, rate limits, and multi-tenancy.

## 11. Common mistakes

- Applications writing logs synchronously to a remote database.
- Full-text indexing everything with no thought about cost.
- High-cardinality labels (request IDs) in the label index.
- Deleting logs line by line for retention.

## 12. Follow-ups

1. **Logs to metrics:** count error lines per service as a metric (see 25) for alerting.
2. **Distributed tracing:** spans with trace IDs, sampled, stored separately and linked from logs.
3. **Access control:** per-team tenants; field-level masking.

See [LLD.md](LLD.md) for logfmt parsing, PII redaction, time-partitioned chunks with label and token indexes, queries, retention, per-service rate limits and log pattern extraction.
