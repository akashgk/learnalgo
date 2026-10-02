# Distributed Job Scheduler: Low-Level Design

## 1. Scope for the LLD round

- **Cron expressions** (`minute hour day-of-month month day-of-week`) with `*`, lists, ranges and steps, validated, and `next(after)` computed by jumping whole months, days and hours instead of scanning minute by minute. Standard cron rule: when both day fields are restricted, a day matches if **either** matches.
- **Scheduler**: jobs with `nextRunAt`; `tick()` creates runs for due occurrences with a **deterministic run ID** (`job@time`), so re-triggering the same occurrence is a no-op.
- **Misfire policies** after downtime: run once (latest occurrence), run all, or skip stale ones.
- **Workers** claim runs and get a **lease**; heartbeats extend it; expired leases are reaped and the run is retried. A worker whose lease was lost cannot complete the run (**fencing** by attempt number).
- **Retries** with exponential backoff up to `maxAttempts`, then `failed`.

Out of scope: storage, queues, DAG dependencies, time zones (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `CronField` | Allowed values of one field and whether it is restricted. |
| `Cron` | Parses an expression; `matches(t)`, `next(after)`. |
| `Job` | ID, cron, retry settings, misfire policy, next run time. |
| `Run` | One occurrence: ID, scheduled time, attempt, status, worker, lease, ready time. |
| `Scheduler` | `addJob`, `tick` (trigger + reap), `claim`, `heartbeat`, `complete`. |
| `LeaseLostException` | Thrown when a stale worker reports on a run it no longer owns. |

```text
Scheduler --has many--> Job --uses--> Cron --has 5--> CronField
    |
    +--has many--> Run (id = jobId@scheduledFor)   status: queued -> running -> succeeded | failed
                     ^ claim(worker) sets lease;  heartbeat extends;  reaper re-queues expired leases
```

## 3. Design decisions and why

- **Run ID = job ID + scheduled time.** Triggering becomes idempotent: two scheduler nodes (or one node replaying after a crash) cannot create the same occurrence twice. A database enforces this with a unique key.
- **Advance `nextRunAt` in the same step as creating runs.** If a node dies in between in a real system, the unique run ID covers the replay.
- **Leases, not "running" flags.** A dead worker's run would stay `running` forever; a lease expires on its own.
- **Fencing by attempt number:** each claim increments `attempt`; `complete` and `heartbeat` must present the current attempt. A slow worker that lost its lease gets an exception instead of overwriting the new attempt's result.
- **`next()` jumps by field** (wrong month: first day of next month; wrong day: next midnight; wrong hour: next hour), so even "February 29th" is found quickly.
- **Misfire policy per job:** catch-up semantics depend on what the job does, so it is configuration, not code.

## 4. The code

```dart
// ---------- Cron ----------

class CronField {
  CronField(this.values, {required this.restricted});
  final Set<int> values;
  final bool restricted;

  static CronField parse(String spec, int min, int max) {
    int number(String s) => int.tryParse(s) ?? (throw FormatException('not a number: "$s"'));
    final values = <int>{};
    for (final part in spec.split(',')) {
      final pieces = part.split('/');
      if (pieces.length > 2) throw FormatException('bad step in "$part"');
      final step = pieces.length == 2 ? number(pieces[1]) : 1;
      if (step <= 0) throw FormatException('step must be positive in "$part"');
      final range = pieces[0];
      var lo = min, hi = max;
      if (range.contains('-')) {
        final bounds = range.split('-');
        lo = number(bounds[0]);
        hi = number(bounds[1]);
      } else if (range != '*') {
        lo = number(range);
        hi = pieces.length == 2 ? max : lo; // "5/15" means 5, 20, 35, 50
      }
      if (lo < min || hi > max || lo > hi) throw FormatException('"$part" outside $min-$max');
      for (var v = lo; v <= hi; v += step) {
        values.add(v);
      }
    }
    return CronField(values, restricted: spec != '*');
  }
}

class Cron {
  Cron._(this.source, this.minute, this.hour, this.dayOfMonth, this.month, this.dayOfWeek);

  factory Cron.parse(String expr) {
    final f = expr.trim().split(RegExp(r'\s+'));
    if (f.length != 5) throw FormatException('expected 5 fields, got ${f.length}');
    return Cron._(
      expr,
      CronField.parse(f[0], 0, 59),
      CronField.parse(f[1], 0, 23),
      CronField.parse(f[2], 1, 31),
      CronField.parse(f[3], 1, 12),
      CronField.parse(f[4], 0, 6), // 0 = Sunday
    );
  }

  final String source;
  final CronField minute, hour, dayOfMonth, month, dayOfWeek;

  bool _dayMatches(DateTime t) {
    final dom = dayOfMonth.values.contains(t.day), dow = dayOfWeek.values.contains(t.weekday % 7);
    // Classic cron: if both day fields are restricted, either may match.
    return dayOfMonth.restricted && dayOfWeek.restricted ? dom || dow : dom && dow;
  }

  bool matches(DateTime t) =>
      month.values.contains(t.month) &&
      _dayMatches(t) &&
      hour.values.contains(t.hour) &&
      minute.values.contains(t.minute);

  /// The first matching minute strictly after [after] (UTC).
  DateTime next(DateTime after) {
    var t = DateTime.utc(after.year, after.month, after.day, after.hour, after.minute + 1);
    for (var i = 0; i < 100000; i++) {
      if (!month.values.contains(t.month)) {
        t = DateTime.utc(t.year, t.month + 1); // first minute of next month
      } else if (!_dayMatches(t)) {
        t = DateTime.utc(t.year, t.month, t.day + 1);
      } else if (!hour.values.contains(t.hour)) {
        t = DateTime.utc(t.year, t.month, t.day, t.hour + 1);
      } else if (!minute.values.contains(t.minute)) {
        t = DateTime.utc(t.year, t.month, t.day, t.hour, t.minute + 1);
      } else {
        return t;
      }
    }
    throw StateError('"$source" never matches'); // e.g. "0 0 30 2 *"
  }
}

// ---------- Scheduler ----------

class FakeClock {
  FakeClock(this.now);
  DateTime now;
  void advance(Duration d) => now = now.add(d);
}

enum MisfirePolicy { runOnce, runAll, skip }

enum RunStatus { queued, running, succeeded, failed }

class Job {
  Job(
    this.id,
    String cron, {
    this.maxAttempts = 3,
    this.retryDelay = const Duration(seconds: 30),
    this.misfire = MisfirePolicy.runOnce,
  }) : cron = Cron.parse(cron);

  final String id;
  final Cron cron;
  final int maxAttempts;
  final Duration retryDelay;
  final MisfirePolicy misfire;
  late DateTime nextRunAt;
}

class Run {
  Run(this.job, this.scheduledFor) : readyAt = scheduledFor;
  final Job job;
  final DateTime scheduledFor;
  String get id => '${job.id}@${scheduledFor.toIso8601String()}';
  RunStatus status = RunStatus.queued;
  int attempt = 0;
  String? worker;
  DateTime? leaseUntil;
  DateTime readyAt;
  String? lastError;
}

class LeaseLostException implements Exception {}

class Scheduler {
  Scheduler(this.clock, {this.lease = const Duration(seconds: 30), this.misfireGrace = const Duration(minutes: 1)});

  final FakeClock clock;
  final Duration lease;
  final Duration misfireGrace;
  final jobs = <String, Job>{};
  final runs = <String, Run>{}; // insertion-ordered

  void addJob(Job job) {
    job.nextRunAt = job.cron.next(clock.now);
    jobs[job.id] = job;
  }

  /// Creates runs for due occurrences, then reaps expired leases. Returns the number of new runs.
  int tick() {
    final now = clock.now;
    var created = 0;
    for (final job in jobs.values) {
      final due = <DateTime>[];
      while (!job.nextRunAt.isAfter(now)) {
        due.add(job.nextRunAt);
        job.nextRunAt = job.cron.next(job.nextRunAt);
      }
      final selected = switch (job.misfire) {
        MisfirePolicy.runAll => due,
        MisfirePolicy.runOnce => due.isEmpty ? <DateTime>[] : [due.last],
        MisfirePolicy.skip => due.where((t) => now.difference(t) <= misfireGrace).toList(),
      };
      for (final t in selected) {
        final run = Run(job, t);
        if (runs.containsKey(run.id)) continue; // already triggered: idempotent
        runs[run.id] = run;
        created++;
      }
    }
    for (final run in runs.values) {
      if (run.status == RunStatus.running && !run.leaseUntil!.isAfter(now)) {
        _retryOrFail(run, 'lease expired (worker ${run.worker} presumed dead)');
      }
    }
    return created;
  }

  Run? claim(String worker) {
    final now = clock.now;
    for (final run in runs.values) {
      if (run.status == RunStatus.queued && !run.readyAt.isAfter(now)) {
        run
          ..status = RunStatus.running
          ..attempt += 1
          ..worker = worker
          ..leaseUntil = now.add(lease);
        return run;
      }
    }
    return null;
  }

  Run _owned(String runId, String worker, int attempt) {
    final run = runs[runId]!;
    if (run.status != RunStatus.running || run.worker != worker || run.attempt != attempt) {
      throw LeaseLostException();
    }
    return run;
  }

  void heartbeat(String runId, String worker, int attempt) =>
      _owned(runId, worker, attempt).leaseUntil = clock.now.add(lease);

  void complete(String runId, String worker, int attempt, {required bool success, String? error}) {
    final run = _owned(runId, worker, attempt);
    if (success) {
      run.status = RunStatus.succeeded;
    } else {
      _retryOrFail(run, error ?? 'failed');
    }
  }

  void _retryOrFail(Run run, String error) {
    run
      ..lastError = error
      ..worker = null
      ..leaseUntil = null;
    if (run.attempt >= run.job.maxAttempts) {
      run.status = RunStatus.failed;
      return;
    }
    run
      ..status = RunStatus.queued
      ..readyAt = clock.now.add(run.job.retryDelay * (1 << (run.attempt - 1))); // 1x, 2x, 4x ...
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void expectThrows<T extends Object>(void Function() f) {
  try {
    f();
  } on T {
    print('ok: threw $T');
    return;
  }
  throw StateError('expected $T');
}

void main() {
  // ----- Cron -----
  DateTime at(int y, int mo, int d, [int h = 0, int mi = 0]) => DateTime.utc(y, mo, d, h, mi);
  check(Cron.parse('*/15 * * * *').next(at(2025, 1, 1, 10, 7)), at(2025, 1, 1, 10, 15));
  check(Cron.parse('*/15 * * * *').next(at(2025, 1, 1, 10, 45)), at(2025, 1, 1, 11, 0));
  check(Cron.parse('0 9 * * 1-5').next(at(2025, 1, 3, 10)), at(2025, 1, 6, 9)); // Friday after 9 -> Monday
  check(Cron.parse('30 2 1 * *').next(at(2025, 1, 15)), at(2025, 2, 1, 2, 30));
  check(Cron.parse('0 0 29 2 *').next(at(2025, 1, 1)), at(2028, 2, 29)); // next leap day
  check(Cron.parse('0 12 13 * 5').next(at(2025, 1, 1)), at(2025, 1, 3, 12)); // the 13th OR a Friday
  check(Cron.parse('5/20 0 * * *').minute.values, '{5, 25, 45}');
  check(Cron.parse('0 0 * * *').matches(at(2025, 1, 1)), true);
  for (final bad in ['61 * * * *', '* * * *', '*/0 * * * *', '5-2 * * * *', 'x * * * *']) {
    expectThrows<FormatException>(() => Cron.parse(bad));
  }
  expectThrows<StateError>(() => Cron.parse('0 0 30 2 *').next(at(2025, 1, 1)));

  // ----- Scheduler: trigger, idempotency, completion -----
  final clock = FakeClock(at(2025, 1, 1, 10, 0));
  final s = Scheduler(clock);
  final report = Job('report', '*/5 * * * *');
  s.addJob(report);
  check(report.nextRunAt, at(2025, 1, 1, 10, 5));
  clock.advance(const Duration(minutes: 4));
  check(s.tick(), 0);
  clock.advance(const Duration(minutes: 1));
  check([s.tick(), s.tick()], [1, 0]);
  report.nextRunAt = at(2025, 1, 1, 10, 5); // a recovering scheduler replays stale state
  check(s.tick(), 0); // same run ID: no duplicate
  final r1 = s.claim('w1')!;
  check([r1.id, r1.attempt], ['report@2025-01-01T10:05:00.000Z', 1]);
  check(s.claim('w2'), null); // nothing else is ready
  s.complete(r1.id, 'w1', 1, success: true);
  check(r1.status, RunStatus.succeeded);

  // ----- Leases and fencing -----
  clock.advance(const Duration(minutes: 5)); // 10:10
  s.tick();
  final r2 = s.claim('w1')!;
  clock.advance(const Duration(seconds: 20));
  s.heartbeat(r2.id, 'w1', 1); // lease now until 10:10:50
  clock.advance(const Duration(seconds: 31)); // w1 went silent
  s.tick();
  check([r2.status, r2.lastError], [RunStatus.queued, 'lease expired (worker w1 presumed dead)']);
  check(s.claim('w2'), null); // retry delay (30 s) not over yet
  clock.advance(const Duration(seconds: 30));
  final again = s.claim('w2')!;
  check([identical(again, r2), again.attempt, again.worker], [true, 2, 'w2']);
  expectThrows<LeaseLostException>(() => s.complete(r2.id, 'w1', 1, success: true)); // the zombie is fenced off
  s.complete(r2.id, 'w2', 2, success: true);
  check(r2.status, RunStatus.succeeded);

  // ----- Retries with backoff, then permanent failure -----
  final retryClock = FakeClock(at(2025, 1, 1, 0, 0));
  final rs = Scheduler(retryClock);
  rs.addJob(Job('flaky', '0 * * * *', maxAttempts: 3, retryDelay: const Duration(seconds: 10)));
  retryClock.advance(const Duration(hours: 1));
  rs.tick();
  final waits = <int>[];
  for (var attempt = 1; attempt <= 3; attempt++) {
    var waited = 0;
    Run? run;
    while ((run = rs.claim('w')) == null) {
      retryClock.advance(const Duration(seconds: 1));
      waited++;
    }
    waits.add(waited);
    rs.complete(run!.id, 'w', attempt, success: false, error: 'HTTP 503');
  }
  check(waits, [0, 10, 20]);
  check([rs.runs.values.single.status, rs.runs.values.single.lastError], [RunStatus.failed, 'HTTP 503']);

  // ----- Misfire policies after 32 minutes of downtime -----
  final downClock = FakeClock(at(2025, 1, 1, 11, 0));
  final ds = Scheduler(downClock);
  for (final p in MisfirePolicy.values) {
    ds.addJob(Job(p.name, '*/5 * * * *', misfire: p));
  }
  downClock.advance(const Duration(minutes: 32)); // missed 11:05 ... 11:30
  ds.tick();
  int runsOf(String job) => ds.runs.values.where((r) => r.job.id == job).length;
  check([runsOf('runAll'), runsOf('runOnce'), runsOf('skip')], [6, 1, 0]);
  check(ds.runs.values.firstWhere((r) => r.job.id == 'runOnce').scheduledFor, at(2025, 1, 1, 11, 30));
  check(ds.jobs['skip']!.nextRunAt, at(2025, 1, 1, 11, 35)); // every policy resumes the normal schedule
}
```

## 5. Walkthrough

- `*/15` after 10:45 rolls into the next hour. `0 9 * * 1-5` after Friday 10:00 skips the weekend to Monday 09:00 (2025-01-03 is a Friday). `0 0 29 2 *` jumps month by month to 2028-02-29. With both day fields restricted, `0 12 13 * 5` fires on Friday the 3rd, before the 13th.
- The first `tick` at 10:05 creates `report@2025-01-01T10:05:00.000Z`; a second tick and a replay with stale `nextRunAt` create nothing.
- `w1` claims the 10:10 run, heartbeats once, then goes silent. At 10:11:01 the lease (until 10:10:50) has expired; the reaper re-queues the run with a 30 s delay. `w2` claims attempt 2. When `w1` wakes up and reports, it presents attempt 1 and is rejected.
- The flaky job waits 0, 10 and 20 seconds before its three attempts, then is `failed` with the last error.
- After 32 minutes of downtime, six occurrences (11:05 to 11:30) were missed: `runAll` creates six runs, `runOnce` only 11:30, and `skip` none (even 11:30 is two minutes old, beyond the 1-minute grace). All three resume at 11:35.

## 6. Concurrency

- Several scheduler nodes: each tick's "find due jobs, insert runs, advance `nextRunAt`" runs in one transaction with `SELECT ... FOR UPDATE SKIP LOCKED` (or each node owns a shard of jobs). The unique run ID is the safety net.
- `claim` must be atomic: `UPDATE runs SET status = 'running', attempt = attempt + 1, worker = ?, lease_until = ? WHERE id = (SELECT id ... WHERE status = 'queued' AND ready_at <= now LIMIT 1 FOR UPDATE SKIP LOCKED)`.
- `complete` and `heartbeat` are conditional on `(worker, attempt, status = 'running')`: this is the fencing check, done in the same statement as the update.
- Clock skew: lease expiry uses the database server's clock, not the workers'.

## 7. Extensibility

| Change | Where |
|---|---|
| Time zones / DST | Compute `next` in the job's zone, convert to UTC; define behavior for skipped and repeated local times. |
| DAG dependencies | Create a downstream run only when all upstream runs for the same `scheduledFor` succeeded. |
| Priorities | Order `claim` by priority, then `readyAt`. |
| Concurrency limits per job | `claim` skips a job that already has N running runs. |
| Jitter for top-of-hour spikes | Add a per-job deterministic offset to `readyAt`. |

## 8. Common mistakes in LLD rounds

- Random run IDs (duplicates on replay).
- A boolean `isRunning` with no expiry.
- Letting any worker complete any run (no fencing).
- Computing `next()` by scanning every minute for years.
- Treating misfires as an afterthought (a scheduler restart floods the system with catch-up runs).

See [HLD.md](HLD.md) for multi-node triggering, queues and failure handling.
