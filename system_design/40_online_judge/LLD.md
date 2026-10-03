# Online Judge: Low-Level Design

## 1. Scope for the LLD round

- **Submissions** queued with priority (contest before practice, then FIFO) and a **per-user rate limit**.
- A **sandbox interface** that "compiles" and runs a program on one input, reporting output, CPU time, memory and crashes. Here programs are Dart functions with declared resource usage; production uses containers/micro-VMs.
- **Per-language limits:** a base time limit multiplied by a language factor (e.g. Python 3x).
- **Verdict rules:** compile error first; then tests in order, first failure wins (Runtime Error, Time Limit, Memory Limit, Wrong Answer); otherwise Accepted. Output compared after normalizing trailing whitespace.
- **Idempotent re-judge** by submission ID.
- **ICPC scoreboard:** solved count, then penalty = sum over solved problems of (acceptance minute + 20 x wrong attempts before it).

Out of scope: real isolation (cgroups, seccomp), special checkers, plagiarism (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `ExecResult`, `Program` | One run's output and resource usage; a "program" maps input to an `ExecResult`. |
| `Sandbox` (interface) | `compile(code)` -> `Program?`; `run(program, input)`. |
| `Problem`, `TestCase` | Tests and base limits. |
| `Language` | Name and time multiplier. |
| `Submission`, `Verdict` | What was submitted and the result (with failing test index). |
| `Judge` | Runs a submission against a problem and produces a verdict. |
| `JudgeService` | Queue, rate limit, workers draining the queue, results, re-judge, scoreboard. |

```text
submit --> rate limit --> priority queue (contest first, then by sequence)
worker: dequeue --> Judge: Sandbox.compile --> for each test: Sandbox.run -> check limits -> compare output
        --> Verdict --> results[submissionId] --> Scoreboard (contest submissions)
```

## 3. Design decisions and why

- **The sandbox is an interface:** the judge's logic (limits, verdict order, comparison) is testable without containers, and the isolation technology can change.
- **First failing test decides the verdict** and judging stops there: cheaper, and it is how most judges behave.
- **Resource checks before output comparison:** a program that printed the right answer in 10 seconds still gets Time Limit Exceeded.
- **Language multipliers** keep limits fair across languages with different speeds.
- **Results keyed by submission ID:** re-running a submission (after a worker crash or a test-data fix) overwrites its result instead of duplicating it.
- **Scoreboard computed from verdicts in submission order,** so wrong attempts after an accepted one do not add penalty.

## 4. The code

```dart
import 'dart:collection';

// ---------- Sandbox ----------

class ExecResult {
  const ExecResult(this.output, {this.cpuMs = 10, this.memoryMb = 16, this.crashed = false});
  final String output;
  final int cpuMs;
  final int memoryMb;
  final bool crashed;
}

typedef Program = ExecResult Function(String input);

abstract interface class Sandbox {
  Program? compile(String language, String code);
  ExecResult run(Program program, String input);
}

/// Test double: "code" is a key into a table of programs; "syntax error" fails to compile.
class FakeSandbox implements Sandbox {
  FakeSandbox(this.programs);
  final Map<String, Program> programs;
  var runs = 0;

  @override
  Program? compile(String language, String code) => code.contains('syntax error') ? null : programs[code];

  @override
  ExecResult run(Program program, String input) {
    runs++;
    return program(input);
  }
}

// ---------- Domain ----------

class TestCase {
  const TestCase(this.input, this.expected);
  final String input;
  final String expected;
}

class Problem {
  const Problem(this.id, this.tests, {this.timeLimitMs = 1000, this.memoryLimitMb = 256});
  final String id;
  final List<TestCase> tests;
  final int timeLimitMs;
  final int memoryLimitMb;
}

enum Language {
  cpp(1),
  java(2),
  python(3);

  const Language(this.timeMultiplier);
  final int timeMultiplier;
}

enum Status { accepted, wrongAnswer, timeLimit, memoryLimit, runtimeError, compileError }

class Verdict {
  const Verdict(this.status, {this.failedTest});
  final Status status;
  final int? failedTest; // 1-based
  @override
  String toString() => failedTest == null ? status.name : '${status.name}@$failedTest';
}

class Submission {
  Submission(this.id, this.user, this.problemId, this.language, this.code, {this.contestMinute});
  final String id;
  final String user;
  final String problemId;
  final Language language;
  final String code;
  final int? contestMinute; // null for practice
  bool get isContest => contestMinute != null;
}

String normalize(String s) => s.split('\n').map((l) => l.trimRight()).join('\n').trimRight();

class Judge {
  Judge(this.sandbox);
  final Sandbox sandbox;

  Verdict judge(Submission s, Problem p) {
    final program = sandbox.compile(s.language.name, s.code);
    if (program == null) return const Verdict(Status.compileError);
    final timeLimit = p.timeLimitMs * s.language.timeMultiplier;
    for (var i = 0; i < p.tests.length; i++) {
      final r = sandbox.run(program, p.tests[i].input);
      final status = r.crashed
          ? Status.runtimeError
          : r.cpuMs > timeLimit
          ? Status.timeLimit
          : r.memoryMb > p.memoryLimitMb
          ? Status.memoryLimit
          : normalize(r.output) != normalize(p.tests[i].expected)
          ? Status.wrongAnswer
          : null;
      if (status != null) return Verdict(status, failedTest: i + 1); // stop at the first failure
    }
    return const Verdict(Status.accepted);
  }
}

// ---------- Service ----------

class RateLimited implements Exception {}

class JudgeService {
  JudgeService(this.judge, this.problems, {this.minSecondsBetweenSubmissions = 5});
  final Judge judge;
  final Map<String, Problem> problems;
  final int minSecondsBetweenSubmissions;
  final _queue = SplayTreeMap<(int, int), Submission>(
    (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
  );
  final _lastSubmit = <String, int>{};
  final submissions = <String, Submission>{};
  final results = <String, Verdict>{};
  final judgedOrder = <String>[];
  var _seq = 0;

  void submit(Submission s, {required int nowSec}) {
    final last = _lastSubmit[s.user];
    if (last != null && nowSec - last < minSecondsBetweenSubmissions) throw RateLimited();
    _lastSubmit[s.user] = nowSec;
    submissions[s.id] = s;
    _queue[(s.isContest ? 0 : 1, _seq++)] = s;
  }

  /// A worker draining up to [max] queued submissions.
  void runWorker({int max = 1 << 30}) {
    for (var i = 0; i < max && _queue.isNotEmpty; i++) {
      final s = _queue.remove(_queue.firstKey())!;
      results[s.id] = judge.judge(s, problems[s.problemId]!);
      judgedOrder.add(s.id);
    }
  }

  /// Re-judge after a test-data fix or a crashed worker: overwrites, never duplicates.
  void rejudge(String submissionId) =>
      results[submissionId] = judge.judge(submissions[submissionId]!, problems[submissions[submissionId]!.problemId]!);

  /// ICPC ranking: more solved first, then lower penalty, then user name.
  List<(String, int, int)> scoreboard() {
    final solvedAt = <(String, String), int>{};
    final wrong = <(String, String), int>{};
    final users = <String>{};
    final contest = submissions.values.where((s) => s.isContest && results.containsKey(s.id)).toList()
      ..sort((a, b) => a.contestMinute!.compareTo(b.contestMinute!));
    for (final s in contest) {
      users.add(s.user);
      final key = (s.user, s.problemId);
      if (solvedAt.containsKey(key)) continue; // nothing counts after the first acceptance
      final status = results[s.id]!.status;
      if (status == Status.accepted) {
        solvedAt[key] = s.contestMinute!;
      } else if (status != Status.compileError) {
        wrong[key] = (wrong[key] ?? 0) + 1; // compile errors are commonly not penalized
      }
    }
    final rows =
        [
          for (final u in users)
            (
              u,
              solvedAt.keys.where((k) => k.$1 == u).length,
              solvedAt.entries
                  .where((e) => e.key.$1 == u)
                  .fold(0, (sum, e) => sum + e.value + 20 * (wrong[e.key] ?? 0)),
            ),
        ]..sort(
          (a, b) => a.$2 != b.$2 ? b.$2.compareTo(a.$2) : (a.$3 != b.$3 ? a.$3.compareTo(b.$3) : a.$1.compareTo(b.$1)),
        );
    return rows;
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void main() {
  // Problem: print the sum of two numbers.
  const sum = Problem(
    'sum',
    [TestCase('1 2', '3'), TestCase('10 20', '30'), TestCase('-5 5', '0')],
    timeLimitMs: 1000,
    memoryLimitMb: 64,
  );
  String add(String input) => input.split(' ').map(int.parse).reduce((a, b) => a + b).toString();
  final sandbox = FakeSandbox({
    'correct': (i) => ExecResult('${add(i)}  \n\n'), // trailing whitespace is fine
    'off-by-one': (i) => ExecResult(i == '10 20' ? '31' : add(i)),
    'slow': (i) => ExecResult(add(i), cpuMs: 2500),
    'hungry': (i) => ExecResult(add(i), memoryMb: 512),
    'crashes': (i) => i.startsWith('-') ? const ExecResult('', crashed: true) : ExecResult(add(i)),
  });
  final judge = Judge(sandbox);
  Verdict run(String code, [Language lang = Language.cpp]) => judge.judge(Submission('x', 'u', 'sum', lang, code), sum);

  check(
    [run('correct'), run('off-by-one'), run('slow'), run('hungry'), run('crashes'), run('syntax error')],
    ['accepted', 'wrongAnswer@2', 'timeLimit@1', 'memoryLimit@1', 'runtimeError@3', 'compileError'],
  );
  check(run('slow', Language.python), 'accepted'); // 2,500 ms is within 3 x 1,000 ms
  final runsBefore = sandbox.runs;
  run('off-by-one');
  check(sandbox.runs - runsBefore, 2); // stopped after the failing test

  // Queue priority and rate limiting.
  final service = JudgeService(judge, {'sum': sum});
  service
    ..submit(Submission('p1', 'zoe', 'sum', Language.cpp, 'correct'), nowSec: 0)
    ..submit(Submission('p2', 'yan', 'sum', Language.cpp, 'correct'), nowSec: 1)
    ..submit(Submission('c1', 'alice', 'sum', Language.cpp, 'off-by-one', contestMinute: 10), nowSec: 2);
  try {
    service.submit(Submission('c2', 'alice', 'sum', Language.cpp, 'correct', contestMinute: 10), nowSec: 4);
    throw StateError('should be rate limited');
  } on RateLimited {
    print('ok: rate limited');
  }
  service.runWorker(max: 1);
  check(service.judgedOrder, ['c1']); // contest work jumps the practice queue
  service.runWorker();
  check(service.judgedOrder, ['c1', 'p1', 'p2']);

  // ICPC scoreboard: solved count, then penalty (minute + 20 per earlier wrong attempt).
  const echo = Problem('echo', [TestCase('hi', 'hi')]);
  final contest = JudgeService(
    Judge(
      FakeSandbox({
        'correct': (i) => ExecResult(add(i)),
        'echo': (i) => ExecResult(i),
        'bad': (i) => const ExecResult('?'),
      }),
    ),
    {'sum': sum, 'echo': echo},
    minSecondsBetweenSubmissions: 0,
  );
  var t = 0;
  void sub(String id, String user, String problem, String code, int minute) =>
      contest.submit(Submission(id, user, problem, Language.cpp, code, contestMinute: minute), nowSec: t++);
  sub('a1', 'alice', 'sum', 'bad', 5);
  sub('a2', 'alice', 'sum', 'correct', 12); // 12 + 20 = 32
  sub('a3', 'alice', 'echo', 'echo', 30); // 30 -> alice total 62
  sub('b1', 'bob', 'sum', 'correct', 20);
  sub('b2', 'bob', 'echo', 'echo', 35); // bob total 55
  sub('b3', 'bob', 'echo', 'bad', 40); // after acceptance: ignored
  sub('c1', 'carol', 'sum', 'correct', 3); // one problem only
  sub('c2', 'carol', 'echo', 'syntax error', 4); // compile error: no penalty, not solved
  contest.runWorker();
  check(contest.scoreboard(), '[(bob, 2, 55), (alice, 2, 62), (carol, 1, 3)]');

  // Re-judging overwrites the result for the same submission ID.
  contest.rejudge('a2');
  check([contest.results.length, contest.results['a2']], [8, 'accepted']);
}
```

## 5. Walkthrough

- `correct` prints the answer with trailing spaces and blank lines; normalization accepts it.
- `off-by-one` fails test 2 (wrong answer) and judging stops there: only 2 runs.
- `slow` uses 2,500 ms: Time Limit in C++ (1,000 ms) but accepted in Python (3 x 1,000 ms).
- `hungry` exceeds 64 MB; `crashes` fails on the third test (negative input); `syntax error` never runs.
- Alice's contest submission at queue position 3 is judged first because contest work has priority; her second submission 2 seconds later is rate limited.
- Scoreboard: Alice and Bob both solved 2. Alice's penalty is (12 + 20 for one wrong attempt) + 30 = 62; Bob's is 20 + 35 = 55; Bob's wrong answer after his acceptance is ignored. Carol solved one; her compile error is not penalized.
- Re-judging `a2` leaves 8 results, not 9.

## 6. Concurrency

- Many workers consume the queue; a submission is claimed with a visibility timeout (or a lease, see 19), so a crashed worker's submission is retried. Results are written keyed by submission ID, so a duplicate judgment overwrites with the same verdict.
- The rate-limit check and the queue insert should be atomic per user (a Redis script or a conditional update), otherwise two simultaneous submissions could both pass.
- Scoreboard updates per verdict are commutative given submission times, so they can be applied as verdicts arrive and recomputed from scratch when needed.

## 7. Extensibility

| Change | Where |
|---|---|
| Special checkers | Replace the normalized string comparison with a `Checker` interface per problem. |
| Partial scoring | Run all tests; score = fraction passed (IOI style). |
| Per-language memory overhead | Add a memory multiplier to `Language`. |
| Scoreboard freeze | Ignore verdicts after the freeze minute for the public view. |
| Real sandbox | `Sandbox` implemented with containers: cgroups limits, seccomp, no network. |

## 8. Common mistakes in LLD rounds

- Executing code in the request handler.
- Comparing output byte for byte (trailing newline differences become wrong answers).
- Checking output before resource limits.
- Counting attempts after acceptance in penalties.

See [HLD.md](HLD.md) for sandboxing layers, worker scaling and contest traffic.
