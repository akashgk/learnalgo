# Notification System: Low-Level Design

## 1. Scope for the LLD round

- One entry point: `submit(request)` with an **idempotency key**; duplicates return the original ID.
- Channels: **push, SMS, email**, each behind a `ChannelSender` interface (provider adapters).
- **Templates** per notification type and channel, with `{{param}}` substitution; a missing parameter is a permanent error.
- **User preferences** (opt out per category and channel) and missing contact details lead to `skipped` deliveries, with a reason.
- A **priority queue** of delivery tasks: high before normal before low.
- **Retries** with exponential backoff for transient errors; no retry for permanent errors; a **dead-letter** list after the last attempt.
- **Provider failover** as a decorator.

Out of scope: real queues, scheduling at a future time, analytics (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `NotificationRequest` | What a caller asks for: user, category, template, params, priority, channels, idempotency key. |
| `Template` / `TemplateStore` | Text per `(templateId, channel)`; `render(params)`. |
| `UserDirectory` | Contact address per channel and opt-out preferences. |
| `ChannelSender` (interface) | Sends one rendered message to one address; returns a `SendResult`. |
| `SendResult` (sealed) | `Sent`, `TransientFailure`, `PermanentFailure`. |
| `FailoverSender` | Decorator: tries a primary sender, falls back to a secondary on transient failure. |
| `RetryPolicy` | Max attempts and backoff delay for attempt n. |
| `Delivery` | One channel of one notification: status, attempts, last error, next attempt time. |
| `NotificationService` | Accepts requests, creates deliveries, runs due tasks in priority order. |

```text
NotificationService --uses--> TemplateStore, UserDirectory, RetryPolicy, Clock
        |
        +--has--> task queue (SplayTreeSet ordered by priority, ready time, seq)
        +--has many--> Delivery (state: queued -> sent | failed | skipped)
        +--uses per channel--> ChannelSender (interface)
                                  ^             ^
                         FakePushSender    FailoverSender(primary, secondary)
```

## 3. Design decisions and why

- **Strategy / adapter per channel:** each provider (APNs, FCM, Twilio, SES) is wrapped in a `ChannelSender`; the service never sees provider APIs.
- **Decorator for failover:** `FailoverSender` is a `ChannelSender` wrapping two others, so failover (or circuit breakers, logging, rate limits) composes without changing the service.
- **Sealed result type** instead of exceptions for expected provider outcomes; the service switches exhaustively and treats transient and permanent errors differently.
- **One `Delivery` per channel:** email can succeed while SMS fails, and each retries independently.
- **Preferences checked when a delivery is created** here; in production check again just before sending (preferences can change while queued).
- **Idempotency key -> notification ID map**, checked before anything is created.
- **Ordered task set** with `(priority, readyAt, seq)`: high priority first, then earliest due, then FIFO.
- **Deterministic backoff in tests** (jitter is a constructor option).

## 4. The code

```dart
import 'dart:collection';
import 'dart:math';

// ---------- Time ----------

abstract interface class Clock {
  int nowMs();
}

class FakeClock implements Clock {
  int _now = 0;
  @override
  int nowMs() => _now;
  void advance(int ms) => _now += ms;
}

// ---------- Requests, templates, users ----------

enum Channel { push, sms, email }

enum Priority { high, normal, low }

class NotificationRequest {
  const NotificationRequest({
    required this.idempotencyKey,
    required this.userId,
    required this.category,
    required this.templateId,
    required this.channels,
    this.params = const {},
    this.priority = Priority.normal,
  });

  final String idempotencyKey;
  final String userId;
  final String category;
  final String templateId;
  final Set<Channel> channels;
  final Map<String, String> params;
  final Priority priority;
}

class RenderException implements Exception {
  RenderException(this.message);
  final String message;
  @override
  String toString() => message;
}

class Template {
  const Template(this.text);
  final String text;

  static final _placeholder = RegExp(r'\{\{(\w+)\}\}');

  String render(Map<String, String> params) => text.replaceAllMapped(_placeholder, (m) {
    final value = params[m[1]];
    if (value == null) throw RenderException('missing param ${m[1]}');
    return value;
  });
}

class TemplateStore {
  final _templates = <(String, Channel), Template>{};
  void put(String templateId, Channel channel, String text) => _templates[(templateId, channel)] = Template(text);
  Template? get(String templateId, Channel channel) => _templates[(templateId, channel)];
}

class UserDirectory {
  final _addresses = <String, Map<Channel, String>>{};
  final _optOuts = <String, Set<(String, Channel)>>{};

  void setAddress(String userId, Channel channel, String address) =>
      _addresses.putIfAbsent(userId, () => {})[channel] = address;

  void optOut(String userId, String category, Channel channel) =>
      _optOuts.putIfAbsent(userId, () => {}).add((category, channel));

  String? addressOf(String userId, Channel channel) => _addresses[userId]?[channel];
  bool allows(String userId, String category, Channel channel) =>
      !(_optOuts[userId]?.contains((category, channel)) ?? false);
}

// ---------- Senders ----------

sealed class SendResult {}

class Sent extends SendResult {
  Sent(this.providerMessageId);
  final String providerMessageId;
}

class TransientFailure extends SendResult {
  TransientFailure(this.reason);
  final String reason;
}

class PermanentFailure extends SendResult {
  PermanentFailure(this.reason);
  final String reason;
}

abstract interface class ChannelSender {
  SendResult send(String address, String text);
}

/// Decorator: use the secondary provider when the primary fails transiently.
class FailoverSender implements ChannelSender {
  FailoverSender(this.primary, this.secondary);
  final ChannelSender primary;
  final ChannelSender secondary;

  @override
  SendResult send(String address, String text) {
    final first = primary.send(address, text);
    return first is TransientFailure ? secondary.send(address, text) : first;
  }
}

// ---------- Retry policy ----------

class RetryPolicy {
  RetryPolicy({required this.maxAttempts, required this.baseDelayMs, required this.maxDelayMs, Random? jitter})
    : _jitter = jitter;

  final int maxAttempts;
  final int baseDelayMs;
  final int maxDelayMs;
  final Random? _jitter;

  /// Delay before attempt number [attempt] + 1, after [attempt] failures: base * 2^(attempt-1), capped.
  int delayAfter(int attempt) {
    final exp = baseDelayMs * (1 << (attempt - 1));
    final capped = exp < maxDelayMs ? exp : maxDelayMs;
    // "Equal jitter": half fixed, half random, so synchronized clients spread out.
    return _jitter == null ? capped : capped ~/ 2 + _jitter.nextInt(capped ~/ 2 + 1);
  }
}

// ---------- Deliveries and the service ----------

enum DeliveryStatus { queued, sent, failed, skipped }

class Delivery {
  Delivery(this.notificationId, this.channel, this.priority);
  final String notificationId;
  final Channel channel;
  final Priority priority;
  DeliveryStatus status = DeliveryStatus.queued;
  int attempts = 0;
  String? lastError;
  String? providerMessageId;

  @override
  String toString() => '${channel.name}:${status.name}${lastError == null ? '' : '($lastError)'}';
}

class _Task {
  _Task(this.delivery, this.request, this.readyAtMs, this.seq);
  final Delivery delivery;
  final NotificationRequest request;
  final int readyAtMs;
  final int seq;
}

class NotificationService {
  NotificationService({
    required this.templates,
    required this.users,
    required Map<Channel, ChannelSender> senders,
    required this.retry,
    required this.clock,
  }) : _senders = senders;

  final TemplateStore templates;
  final UserDirectory users;
  final Map<Channel, ChannelSender> _senders;
  final RetryPolicy retry;
  final Clock clock;

  final _byKey = <String, String>{}; // idempotency key -> notification ID
  final _deliveries = <String, List<Delivery>>{};
  final deadLetters = <Delivery>[];
  final _queue = SplayTreeSet<_Task>((a, b) {
    final byPriority = a.delivery.priority.index.compareTo(b.delivery.priority.index);
    if (byPriority != 0) return byPriority;
    final byTime = a.readyAtMs.compareTo(b.readyAtMs);
    return byTime != 0 ? byTime : a.seq.compareTo(b.seq);
  });
  var _nextId = 1;
  var _nextSeq = 0;

  String submit(NotificationRequest r) {
    final existing = _byKey[r.idempotencyKey];
    if (existing != null) return existing;
    final id = 'n${_nextId++}';
    _byKey[r.idempotencyKey] = id;

    final deliveries = <Delivery>[];
    for (final channel in r.channels) {
      final d = Delivery(id, channel, r.priority);
      deliveries.add(d);
      final skip = !users.allows(r.userId, r.category, channel)
          ? 'opted out'
          : users.addressOf(r.userId, channel) == null
          ? 'no address'
          : null;
      if (skip != null) {
        d
          ..status = DeliveryStatus.skipped
          ..lastError = skip;
      } else {
        _enqueue(d, r, clock.nowMs());
      }
    }
    _deliveries[id] = deliveries;
    return id;
  }

  List<Delivery> deliveriesOf(String notificationId) => _deliveries[notificationId] ?? const [];

  void _enqueue(Delivery d, NotificationRequest r, int readyAt) => _queue.add(_Task(d, r, readyAt, _nextSeq++));

  /// Runs due tasks, highest priority first. Returns the number of send attempts made.
  int processDue({int maxTasks = 1 << 30}) {
    var done = 0;
    while (done < maxTasks) {
      final now = clock.nowMs();
      // Ordered by priority first, so a ready low-priority task can sit behind a not-yet-due high one.
      _Task? task;
      for (final t in _queue) {
        if (t.readyAtMs <= now) {
          task = t;
          break;
        }
      }
      if (task == null) break;
      _queue.remove(task);
      _attempt(task);
      done++;
    }
    return done;
  }

  void _attempt(_Task task) {
    final d = task.delivery, r = task.request;
    d.attempts++;
    final SendResult result;
    try {
      final template = templates.get(r.templateId, d.channel);
      if (template == null) throw RenderException('no template for ${d.channel.name}');
      final text = template.render(r.params);
      result = _senders[d.channel]!.send(users.addressOf(r.userId, d.channel)!, text);
    } on RenderException catch (e) {
      _fail(d, e.message);
      return;
    }
    switch (result) {
      case Sent(:final providerMessageId):
        d
          ..status = DeliveryStatus.sent
          ..providerMessageId = providerMessageId
          ..lastError = null;
      case PermanentFailure(:final reason):
        _fail(d, reason);
      case TransientFailure(:final reason):
        d.lastError = reason;
        if (d.attempts >= retry.maxAttempts) {
          _fail(d, 'gave up: $reason');
        } else {
          _enqueue(d, r, clock.nowMs() + retry.delayAfter(d.attempts));
        }
    }
  }

  void _fail(Delivery d, String reason) {
    d
      ..status = DeliveryStatus.failed
      ..lastError = reason;
    deadLetters.add(d);
  }
}

// ---------- Test doubles ----------

class ScriptedSender implements ChannelSender {
  ScriptedSender(this.name, [List<SendResult> script = const []]) : _script = [...script];
  final String name;
  final List<SendResult> _script;
  final sent = <String>[];
  var calls = 0;

  @override
  SendResult send(String address, String text) {
    calls++;
    if (_script.isNotEmpty) return _script.removeAt(0);
    sent.add('$address <- $text');
    return Sent('$name-${sent.length}');
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void main() {
  final clock = FakeClock();
  final templates = TemplateStore()
    ..put('shipped', Channel.push, 'Order {{orderId}} ships {{eta}}')
    ..put('shipped', Channel.email, 'Hi {{name}}, order {{orderId}} ships {{eta}}.')
    ..put('otp', Channel.sms, 'Your code is {{code}}')
    ..put('promo', Channel.sms, 'Sale: {{discount}} off')
    ..put('promo', Channel.email, 'Sale: {{discount}} off');
  final users = UserDirectory()
    ..setAddress('u1', Channel.push, 'token-u1')
    ..setAddress('u1', Channel.email, 'u1@example.com')
    ..setAddress('u1', Channel.sms, '+15550001')
    ..optOut('u1', 'marketing', Channel.sms)
    ..setAddress('u2', Channel.email, 'u2@example.com');

  final push = ScriptedSender('apns');
  final email = ScriptedSender('ses');
  final smsPrimary = ScriptedSender('twilio', [
    TransientFailure('timeout'),
    TransientFailure('503'),
    TransientFailure('503'),
  ]);
  final smsBackup = ScriptedSender('sns', [TransientFailure('throttled')]);
  final service = NotificationService(
    templates: templates,
    users: users,
    senders: {Channel.push: push, Channel.email: email, Channel.sms: FailoverSender(smsPrimary, smsBackup)},
    retry: RetryPolicy(maxAttempts: 3, baseDelayMs: 1000, maxDelayMs: 60000),
    clock: clock,
  );

  // Happy path across two channels, and an idempotent resubmission.
  const shipped = NotificationRequest(
    idempotencyKey: 'order-7-shipped',
    userId: 'u1',
    category: 'orders',
    templateId: 'shipped',
    channels: {Channel.push, Channel.email},
    params: {'orderId': '7', 'eta': 'Friday', 'name': 'Ada'},
  );
  final n1 = service.submit(shipped);
  check(service.submit(shipped), n1);
  check(service.processDue(), 2);
  check(push.sent, ['token-u1 <- Order 7 ships Friday']);
  check(email.sent, ['u1@example.com <- Hi Ada, order 7 ships Friday.']);
  check(service.deliveriesOf(n1), [Channel.push, Channel.email].map((c) => '${c.name}:sent').toList());

  // Preferences and missing contact details produce skipped deliveries.
  final promo = service.submit(
    const NotificationRequest(
      idempotencyKey: 'promo-1-u1',
      userId: 'u1',
      category: 'marketing',
      templateId: 'promo',
      channels: {Channel.sms, Channel.email},
      params: {'discount': '20%'},
      priority: Priority.low,
    ),
  );
  final promo2 = service.submit(
    const NotificationRequest(
      idempotencyKey: 'promo-1-u2',
      userId: 'u2',
      category: 'marketing',
      templateId: 'promo',
      channels: {Channel.sms},
      params: {'discount': '20%'},
      priority: Priority.low,
    ),
  );
  check(service.deliveriesOf(promo), ['sms:skipped(opted out)', 'email:queued']);
  check(service.deliveriesOf(promo2), ['sms:skipped(no address)']);

  // Priority: a high-priority OTP submitted later is still sent before the queued low-priority email.
  final otp = service.submit(
    const NotificationRequest(
      idempotencyKey: 'otp-1',
      userId: 'u1',
      category: 'security',
      templateId: 'otp',
      channels: {Channel.sms},
      params: {'code': '123456'},
      priority: Priority.high,
    ),
  );
  service.processDue(maxTasks: 1);
  check(service.deliveriesOf(otp), ['sms:queued(throttled)']); // ran first: primary timeout, backup throttled
  check([smsPrimary.calls, smsBackup.calls, email.sent.length], [1, 1, 1]); // promo email still waiting
  service.processDue();
  check(email.sent.last, 'u1@example.com <- Sale: 20% off');

  // Retries with exponential backoff: 1 s, then 2 s. Primary fails again; backup succeeds.
  clock.advance(999);
  check(service.processDue(), 0); // not due yet
  clock.advance(1);
  service.processDue(); // attempt 2: primary 503, backup ok
  check(service.deliveriesOf(otp), ['sms:sent']);
  check(smsBackup.sent, ['+15550001 <- Your code is 123456']);
  check(service.deliveriesOf(otp).single.attempts, 2);

  // Give up after maxAttempts, into the dead-letter list.
  final flaky = ScriptedSender('flaky', [for (var i = 0; i < 5; i++) TransientFailure('503')]);
  final strict = NotificationService(
    templates: templates,
    users: users,
    senders: {Channel.email: flaky},
    retry: RetryPolicy(maxAttempts: 3, baseDelayMs: 1000, maxDelayMs: 60000),
    clock: clock,
  );
  final n = strict.submit(
    const NotificationRequest(
      idempotencyKey: 'x',
      userId: 'u2',
      category: 'marketing',
      templateId: 'promo',
      channels: {Channel.email},
      params: {'discount': '5%'},
    ),
  );
  for (final step in [0, 1000, 2000]) {
    clock.advance(step);
    strict.processDue();
  }
  check(strict.deliveriesOf(n), ['email:failed(gave up: 503)']);
  check([flaky.calls, strict.deadLetters.length], [3, 1]);

  // A permanent error (here, a missing template parameter) is never retried.
  final bad = strict.submit(
    const NotificationRequest(
      idempotencyKey: 'y',
      userId: 'u2',
      category: 'marketing',
      templateId: 'promo',
      channels: {Channel.email},
    ),
  );
  strict.processDue();
  clock.advance(100000);
  check(strict.processDue(), 0);
  check(strict.deliveriesOf(bad), ['email:failed(missing param discount)']);

  // Backoff values: doubling, capped; jitter stays within [half, full].
  final policy = RetryPolicy(maxAttempts: 10, baseDelayMs: 500, maxDelayMs: 4000);
  check([for (var a = 1; a <= 5; a++) policy.delayAfter(a)], [500, 1000, 2000, 4000, 4000]);
  final jittered = RetryPolicy(maxAttempts: 10, baseDelayMs: 500, maxDelayMs: 4000, jitter: Random(1));
  check(List.generate(50, (_) => jittered.delayAfter(4)).every((d) => d >= 2000 && d <= 4000), true);
}
```

## 5. Walkthrough

- Resubmitting `order-7-shipped` returns `n1` and creates nothing, so the caller's retry after a timeout is harmless.
- `u1` opted out of marketing SMS, and `u2` has no phone number: both deliveries are `skipped` with the reason, which is what support staff need when a user asks "why did I not get it?".
- The OTP is submitted after the promo email but runs first (high priority). Its first attempt fails on both providers (timeout, then throttled), so it is requeued 1 s later. At t = 1000, the primary fails again and the backup succeeds: `sent` after 2 attempts.
- The flaky sender fails 3 times, 0 s, 1 s and 3 s after submission (delays of 1 s then 2 s), and the delivery goes to the dead-letter list.
- A missing template parameter is a bug in the caller, not a transient condition: it fails immediately.

## 6. Concurrency

- In production, each channel has its own worker pool consuming its own queue. Two workers must not send the same delivery: the queue's visibility timeout plus a conditional status update (`UPDATE deliveries SET status = 'sending' WHERE id = ? AND status = 'queued'`) claims it.
- A worker that crashes after the provider accepted but before recording `sent` causes one duplicate on redelivery. Pass a provider-side idempotency key where supported; otherwise accept the rare duplicate.
- `RetryPolicy` with a shared `Random` must be thread-safe or per worker.

## 7. Extensibility

| Change | Where |
|---|---|
| New channel (WhatsApp, in-app) | New `Channel` value and a `ChannelSender`; templates for it. |
| Circuit breaker | Another `ChannelSender` decorator that short-circuits after N failures for a cool-down period. |
| Per-user rate limit for marketing | Check in `submit` (skip with reason "rate limited"), using a limiter from 02. |
| Scheduled send / quiet hours | Enqueue with `readyAt = sendAt` or the end of the user's quiet hours. |
| Localization | Template key `(templateId, channel, locale)`, with a fallback locale. |

## 8. Common mistakes in LLD rounds

- One `NotificationService.send` with `if (channel == "sms") ... else if ...`.
- Exceptions for normal provider responses, with transient and permanent errors handled the same way.
- Retrying immediately in a loop (no backoff), or forever.
- One status for the whole notification instead of per channel.
- No idempotency key on the API.

See [HLD.md](HLD.md) for queues, isolation, providers and failure handling.
