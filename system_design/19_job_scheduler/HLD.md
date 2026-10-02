# Distributed Job Scheduler (cron at scale / Airflow / AWS EventBridge Scheduler): High-Level Design

**Asked at:** Google, Amazon, Microsoft, Uber, Airbnb, Netflix. **Core topics:** triggering jobs exactly once per scheduled time across many scheduler nodes, queues and workers with leases and heartbeats, retries and idempotency, missed-run (misfire) policies, dependencies between jobs.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Job types? | Recurring (cron expressions) and one-off (run at time T). Jobs are calls to a handler: an HTTP endpoint, a container, or a function. |
| Scale? | 10 M scheduled jobs; peak ~100K job starts per minute (many at the top of the hour). |
| Precision? | Start within a few seconds of the scheduled time. |
| Guarantees? | Each scheduled occurrence runs **at least once**; jobs should be idempotent. No duplicate triggering in normal operation. |
| Duration? | Seconds to hours. |
| Dependencies? | Follow-up: DAGs (job B after job A succeeds). |

## 2. Requirements

**Functional:** create/update/delete/pause jobs with schedules; trigger runs on time; execute on workers; retry failures with backoff; record run history and status; misfire handling after downtime.

**Non-functional:** high availability (no single scheduler), scalability (millions of jobs, bursty start times), reliability (no lost runs, bounded duplicates), observability.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Jobs | 10 M definitions | ~1 KB each → **10 GB** metadata |
| Runs/day | average job every hour: 10 M x 24 | **240 M runs/day** ≈ 2,800/s avg |
| Peak | many cron jobs at :00 | **~100K+ triggers in the first seconds of an hour**: spread with jitter or absorb with a queue |
| Run history | 240 M x 500 B | **~120 GB/day**; keep 30-90 days |

## 4. API

```text
POST /jobs   { name, schedule: "0 * * * *" | runAt, target, payload, timeout, maxAttempts, retryPolicy,
               misfirePolicy: run_once | run_all | skip, timezone }
PATCH /jobs/{id} (pause/resume, change schedule)     DELETE /jobs/{id}
GET  /jobs/{id}/runs?status=...                     POST /jobs/{id}/trigger   (manual run)
```

## 5. Data model

```text
jobs(id, schedule, timezone, target, payload, next_run_at, paused, version, ...)
     INDEX (next_run_at) WHERE NOT paused          <-- the trigger query
runs(id = job_id + scheduled_for  UNIQUE, job_id, scheduled_for, attempt, status,
     worker_id, lease_until, started_at, finished_at, error)
```

The deterministic run ID `(job_id, scheduled_for)` is what makes triggering idempotent: inserting the same occurrence twice fails on the unique key.

## 6. Architecture

```text
 API --> jobs DB (sharded by job_id; index on next_run_at)
                     ^
                     |  every second, each scheduler node (owning some shards) runs:
   Scheduler nodes --+    SELECT jobs WHERE next_run_at <= now LIMIT 1000 FOR UPDATE SKIP LOCKED
   (stateless, many)      insert run rows (unique id), advance next_run_at, enqueue run IDs
                     |
                     v
               queue (Kafka / SQS), partitioned
                     |
                     v
   Workers: take a run, set status=running with a lease (lease_until = now + 30 s), heartbeat to extend it,
            execute the target, report success/failure
                     |
   Lease reaper: runs whose lease expired (worker died) are re-queued as a new attempt
   Retry manager: failed attempts re-queued at now + backoff, up to maxAttempts; then status=failed + alert
```

## 7. Deep dive: triggering each occurrence once

Options for coordinating many scheduler nodes:

| Approach | How | Trade-off |
|---|---|---|
| Single leader (ZooKeeper/etcd election) | one active scheduler, others standby | simple; throughput limited to one node; failover gap |
| **Partitioned ownership** | jobs sharded; each shard owned by one scheduler via leases | scales horizontally; rebalance on node failure |
| Row locking (`FOR UPDATE SKIP LOCKED`) | any node can take due jobs; locked rows are skipped by others | simple with a relational DB; DB becomes the bottleneck at very high rates |
| Time-bucketed queues | runs pre-materialized into minute buckets (e.g. Redis sorted sets or a timing wheel); nodes pop due buckets | very high throughput; needs materialization ahead of time |

In all cases, the **unique run ID** is the final defense: even if two nodes race, only one insert succeeds.

## 8. Deep dive: execution guarantees

- **At-least-once:** a run can execute twice (worker finishes the work but dies before reporting; the lease expires and another worker retries). Jobs must be idempotent, or use the run ID as an idempotency key in the target system.
- **Leases + heartbeats** detect dead workers without false positives from slow ones (as long as heartbeats keep coming).
- **Fencing:** a worker whose lease expired must not be able to mark the run complete after another worker took it; status updates check the current lease holder / attempt number.
- **Timeouts:** a run exceeding its timeout is killed and counted as a failed attempt.

## 9. Deep dive: misfires and hot spots

- After downtime, a job may have missed several occurrences. Policies: **run once** (one catch-up run, typical), **run all** (every missed occurrence, for jobs processing time windows), **skip** (only future runs).
- **Top-of-hour spikes:** encourage jittered schedules; spread execution with a queue and enough workers; prioritize by job priority.
- **Time zones and DST:** compute next run in the job's time zone; a 02:30 job on a spring-forward day either runs at 03:00 or is skipped (document it).

## 10. Failure modes

| Failure | Behavior |
|---|---|
| Scheduler node dies | Its shards' leases expire; another node takes them; due jobs triggered late by a few seconds, not lost (next_run_at only advances in the same transaction as the run insert). |
| Worker dies mid-run | Lease expires; reaper re-queues the run (new attempt). |
| Queue unavailable | Runs remain in `queued` in the DB; a sweeper re-enqueues them. |
| Target service down | Retries with exponential backoff; eventually failed + alert. |
| Duplicate trigger race | Unique run ID rejects the second insert. |

## 11. What interviewers look for

- How a due job is found efficiently (index on `next_run_at`, buckets) and triggered exactly once (locking/partitioning plus unique run IDs).
- Leases, heartbeats, fencing, and at-least-once with idempotent jobs.
- Retry with backoff and misfire policy.
- Handling the top-of-hour thundering herd.

## 12. Common mistakes

- One cron daemon on one machine (single point of failure).
- Scanning all jobs every second.
- Claiming exactly-once execution.
- No lease expiry: a crashed worker's run stays `running` forever.

## 13. Follow-ups

1. **DAG workflows:** a run of B is created when all its upstream runs for the same logical date succeed (Airflow).
2. **Priorities and quotas** per tenant.
3. **Long-running jobs:** checkpointing; heartbeats carry progress.
4. **One-off delayed tasks at huge scale:** hierarchical timing wheels.

See [LLD.md](LLD.md) for a cron parser and next-run calculation, the scheduler with idempotent run creation, leases with fencing, retries and misfire policies.
