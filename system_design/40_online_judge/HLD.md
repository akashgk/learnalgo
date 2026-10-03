# Online Judge / Coding Platform (LeetCode / Codeforces / HackerRank): High-Level Design

**Asked at:** LeetCode, HackerRank, Amazon, Google, Meta, Bloomberg. **Core topics:** running untrusted code safely (sandboxing), an asynchronous judging pipeline with queues and workers, resource limits and verdicts, contest traffic spikes, real-time scoreboards.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Features? | Problems with hidden test cases; submit code in ~20 languages; verdicts (Accepted, Wrong Answer, Time Limit, Memory Limit, Runtime Error, Compile Error); contests with live leaderboards. |
| Scale? | 2 M DAU; ~5 M submissions/day normally; contests with 50K participants submitting in bursts. |
| Latency? | Verdict in a few seconds normally; under a minute during contest peaks. |
| Security? | User code is hostile: it must not escape, access the network, read test data, or affect other submissions. |

## 2. Requirements

**Functional:** browse problems, run code against sample tests, submit against hidden tests, see verdicts and per-test details (for samples), contests with ranking rules and penalties, submission history.

**Non-functional:** strong isolation, fairness (consistent CPU limits across workers), elastic capacity for contests, durability of submissions, reasonable latency.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Submissions | 5 M/day | **~60/s** avg; contests: **~1-2K/s** for minutes |
| Execution cost | ~50 tests x ~100 ms + compile ~1-3 s | **~5-10 CPU-seconds per submission** |
| Workers for contest peak | 2K/s x ~8 CPU-s | **~16K cores** briefly: autoscaling and queueing are essential |
| Test data | 3,000 problems x ~50 MB | **~150 GB**, cached on worker nodes |

## 4. Architecture

```text
 web --> API --> Submission service --> submissions DB (status: queued)
                     |  enqueue (priority: contest > practice; per-language queues)
                     v
                 queue (SQS/Kafka/Redis streams)
                     |
         judge workers (autoscaled, per language image):
             1. pull submission + test data (local cache)
             2. compile in a sandbox (time/memory limits)
             3. run each test in a fresh sandbox: cgroups (CPU, memory), seccomp syscall filter,
                no network, read-only filesystem, PID limits, wall-clock + CPU time limits
             4. compare outputs (exact, whitespace-insensitive, or special checker)
             5. write verdict --> DB; publish event --> websocket to the user; contest scoreboard update
```

## 5. Deep dive: sandboxing

- **Layers:** container or micro-VM per run (Docker + gVisor, Firecracker), cgroups for CPU/memory/PIDs, seccomp to block dangerous syscalls, no network namespace, unprivileged user, read-only image with a small writable tmpfs.
- **Limits:** CPU time (fair across languages via per-language multipliers), wall time (catches sleeping/blocked programs), memory, output size, process count (fork bombs).
- Test inputs are mounted read-only; expected outputs never enter the sandbox.
- Workers are disposable; a compromised worker is replaced, and workers run in an isolated network segment.

## 6. Deep dive: verdicts

- Compile error before any test runs.
- Tests run in order; the first failure determines the verdict (stop early to save CPU), or run all for partial scoring.
- Output comparison: normalize trailing whitespace/newlines; floating-point tolerance or custom checkers for problems with multiple correct answers.

## 7. Deep dive: contests

- **Spikes:** pre-warm worker pools before the start; queue with priority for contest submissions; show "queued" status honestly.
- **Scoreboard:** ICPC rules (problems solved, then penalty minutes: time of acceptance + 20 minutes per wrong attempt before acceptance) or point-based; maintained in a sorted set (see 24), recomputed incrementally per verdict; frozen in the last hour.
- **Fairness:** rate limits per user (one submission every few seconds), plagiarism detection after the contest.

## 8. Failure modes

| Failure | Behavior |
|---|---|
| Worker crash mid-judging | Queue visibility timeout returns the submission; re-judge (idempotent by submission ID). |
| Judge bug / bad test data | Re-judge affected submissions from stored code. |
| Queue backlog | Autoscale; contest priority; status updates to users. |
| Malicious code | Sandbox limits; kill and report; worker recycled. |

## 9. What interviewers look for

- Asynchronous pipeline (queue + workers), not running code in the web tier.
- A credible sandbox with layered limits.
- Verdict logic and resource limits per language.
- Contest spike handling and scoreboard rules.

## 10. Common mistakes

- Running user code on the API servers.
- One limit for every language (Python vs C++ fairness).
- Letting test outputs be readable inside the sandbox.
- No plan for contest bursts.

## 11. Follow-ups

1. **Custom checkers and interactive problems:** a checker process talks to the user program through pipes.
2. **Code execution for interviews (collaborative):** see 17 for real-time editing.
3. **Plagiarism detection:** token-based similarity (MOSS-like) across submissions.

See [LLD.md](LLD.md) for the submission queue with priorities, rate limits, a sandbox interface with per-language limits, verdict rules, output normalization, idempotent re-judging and an ICPC scoreboard.
