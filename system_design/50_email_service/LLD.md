# Email Service: Low-Level Design

## 1. Scope for the LLD round

- **Messages** with `Message-ID`, `In-Reply-To` and `References` headers, sender, recipients, subject, body, attachments, date, DKIM result.
- **Threading:** by references first; otherwise by normalized subject (`Re:`/`Fwd:` stripped) within 30 days and only if participants overlap.
- **Labels** (inbox, sent, spam, custom); archiving removes the inbox label; **unread counts** per label.
- **Per-user search** with operators `from:`, `to:`, `subject:`, `label:`, `has:attachment` and free-text words (all must match), newest first.
- **Spam scoring** with simple, explainable rules.
- **Outbound queue:** retries with exponential backoff on temporary (4xx) failures, immediate **bounce** on permanent (5xx) failures, and a bounce after the maximum retry period.

Out of scope: SMTP protocol details, storage engines, ML spam models (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Email` | Immutable message with headers. |
| `normalizeSubject`, `tokens` | Threading key; search tokens. |
| `Mailbox` | Messages, labels, unread set, threads, search index; delivery, archive, read, search. |
| `spamScore` | Rule-based score and a threshold. |
| `OutboundQueue` | Pending sends, retry schedule, bounces. |

```text
deliver(email) --> spamScore --> labels {inbox | spam} (sender = owner -> sent)
             --> thread: References/In-Reply-To match ? existing : subject match (30 days, shared participant) ? existing : new
             --> search index: token -> {message IDs}; field tokens like "from:bob@x.com"
send(email) --> OutboundQueue --> transport(code) --> 2xx done | 4xx retry (5 min x 2^n) | 5xx or too old -> bounce
```

## 3. Design decisions and why

- **Labels, not folders:** a message can be in several views; archiving or labeling changes metadata only, never moves data.
- **Headers before subjects for threading:** they are exact; subjects are only a fallback with safeguards (time window, shared participants), so unrelated "Hello" emails do not merge.
- **Field-prefixed tokens in the index** (`from:bob@x.com`, `subject:lunch`) make operator queries plain set intersections.
- **Spam rules return a score,** not a boolean: thresholds and weights can be tuned, and the reasons are inspectable.
- **SMTP semantics for retries:** 4xx means "try later", 5xx means "never"; retrying permanent errors only delays the bounce the sender needs.

## 4. The code

```dart
class Email {
  const Email({
    required this.id,
    required this.from,
    required this.to,
    required this.subject,
    required this.body,
    required this.date,
    this.inReplyTo,
    this.references = const [],
    this.attachments = const [],
    this.dkimPass = true,
  });
  final String id; // Message-ID
  final String from;
  final List<String> to;
  final String subject;
  final String body;
  final int date; // seconds
  final String? inReplyTo;
  final List<String> references;
  final List<String> attachments;
  final bool dkimPass;
}

String normalizeSubject(String s) =>
    s.replaceFirst(RegExp(r'^\s*((re|fwd?)\s*:\s*)+', caseSensitive: false), '').trim().toLowerCase();

Iterable<String> tokens(String text) => text.toLowerCase().split(RegExp(r'[^a-z0-9@.]+')).where((t) => t.length > 1);

int spamScore(Email e, {Set<String> contacts = const {}}) {
  var score = 0;
  if (!e.dkimPass) score += 3; // claims a domain it cannot prove
  final letters = e.subject.replaceAll(RegExp(r'[^A-Za-z]'), '');
  if (letters.length >= 6 && letters == letters.toUpperCase()) score += 2;
  for (final phrase in const ['free money', 'winner', 'act now', 'wire transfer']) {
    if ('${e.subject} ${e.body}'.toLowerCase().contains(phrase)) score += 3;
  }
  if ('http'.allMatches(e.body).length > 3) score += 1;
  if (contacts.contains(e.from)) score -= 5;
  return score;
}

class Mailbox {
  Mailbox(this.owner, {this.contacts = const {}, this.spamThreshold = 5});
  final String owner;
  final Set<String> contacts;
  final int spamThreshold;
  static const subjectWindowSec = 30 * 86400;

  final messages = <String, Email>{};
  final labels = <String, Set<String>>{};
  final _unread = <String>{};
  final _threadOf = <String, String>{};
  final threads = <String, List<String>>{};
  final _index = <String, Set<String>>{};

  void deliver(Email e) {
    messages[e.id] = e;
    final mine = e.from == owner;
    labels[e.id] = {if (mine) 'sent' else if (spamScore(e, contacts: contacts) >= spamThreshold) 'spam' else 'inbox'};
    if (!mine) _unread.add(e.id);
    final thread = _findThread(e) ?? e.id;
    _threadOf[e.id] = thread;
    threads.putIfAbsent(thread, () => []).add(e.id);
    for (final t in {
      ...tokens('${e.subject} ${e.body}'),
      'from:${e.from.toLowerCase()}',
      for (final r in e.to) 'to:${r.toLowerCase()}',
      for (final w in tokens(e.subject)) 'subject:$w',
      if (e.attachments.isNotEmpty) 'has:attachment',
    }) {
      _index.putIfAbsent(t, () => {}).add(e.id);
    }
  }

  String? _findThread(Email e) {
    for (final ref in [?e.inReplyTo, ...e.references.reversed]) {
      final t = _threadOf[ref];
      if (t != null) return t;
    }
    final key = normalizeSubject(e.subject);
    final people = {e.from, ...e.to};
    for (final MapEntry(key: threadId, value: ids) in threads.entries) {
      final last = messages[ids.last]!;
      if (normalizeSubject(last.subject) == key &&
          e.date - last.date <= subjectWindowSec &&
          ({last.from, ...last.to}.intersection(people).length > 1 || people.contains(last.from))) {
        return threadId;
      }
    }
    return null;
  }

  void markRead(String id) => _unread.remove(id);
  void archive(String id) => labels[id]!.remove('inbox');
  void addLabel(String id, String label) => labels[id]!.add(label);

  int unreadCount(String label) => _unread.where((id) => labels[id]!.contains(label)).length;

  List<String> threadView(String messageId) => [for (final id in threads[_threadOf[messageId]]!) messages[id]!.subject];

  /// All terms must match; `label:` checks current labels; newest first.
  List<String> search(String query) {
    Set<String>? result;
    for (final term in query.toLowerCase().split(' ').where((t) => t.isNotEmpty)) {
      final Set<String> ids;
      if (term.startsWith('label:')) {
        final l = term.substring(6);
        ids = {
          for (final e in labels.entries)
            if (e.value.contains(l)) e.key,
        };
      } else if (term.startsWith('subject:')) {
        ids = _index[term] ?? {};
      } else if (term.contains(':')) {
        ids = _index[term] ?? {};
      } else {
        ids = {for (final t in tokens(term)) ...?_index[t]};
      }
      result = result == null ? ids : result.intersection(ids);
    }
    final list = (result ?? <String>{}).toList()..sort((a, b) => messages[b]!.date.compareTo(messages[a]!.date));
    return [for (final id in list) messages[id]!.subject];
  }
}

// ---------- Outbound ----------

class OutboundQueue {
  OutboundQueue({this.baseDelaySec = 300, this.maxAgeSec = 5 * 86400});
  final int baseDelaySec;
  final int maxAgeSec;
  final _pending = <(Email, int, int, int)>[]; // (email, queuedAt, attempts, nextTryAt)
  final delivered = <String>[];
  final bounces = <String>[];

  void enqueue(Email e, int now) => _pending.add((e, now, 0, now));

  /// [transport] returns an SMTP reply code for a delivery attempt.
  void process(int now, int Function(Email e) transport) {
    final still = <(Email, int, int, int)>[];
    for (final (e, queuedAt, attempts, nextTry) in _pending) {
      if (nextTry > now) {
        still.add((e, queuedAt, attempts, nextTry));
        continue;
      }
      final code = transport(e);
      if (code < 300) {
        delivered.add('${e.id} after ${attempts + 1} attempt(s)');
      } else if (code >= 500) {
        bounces.add('${e.id}: permanent failure $code');
      } else if (now - queuedAt >= maxAgeSec) {
        bounces.add('${e.id}: gave up after ${attempts + 1} attempts');
      } else {
        still.add((e, queuedAt, attempts + 1, now + baseDelaySec * (1 << attempts.clamp(0, 10))));
      }
    }
    _pending
      ..clear()
      ..addAll(still);
  }

  int get pending => _pending.length;
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void main() {
  const me = 'me@mail.com', bob = 'bob@x.com', ann = 'ann@y.com';
  final box = Mailbox(me, contacts: {bob});
  const day = 86400;

  check(normalizeSubject('RE: re:  Fwd: Lunch?'), 'lunch?');

  // Threading by headers, then by subject with safeguards.
  box
    ..deliver(const Email(id: 'm1', from: bob, to: [me], subject: 'Lunch?', body: 'Friday at noon?', date: 0))
    ..deliver(
      const Email(id: 'm2', from: me, to: [bob], subject: 'Re: Lunch?', body: 'Sure', date: 100, inReplyTo: 'm1'),
    )
    ..deliver(
      const Email(
        id: 'm3',
        from: bob,
        to: [me],
        subject: 'RE: re: Lunch?',
        body: 'Great',
        date: 200,
        references: ['m1', 'm2'],
      ),
    )
    ..deliver(
      const Email(id: 'm4', from: bob, to: [me], subject: 'Re: Lunch?', body: 'Bringing ann', date: 300),
    ) // no headers
    ..deliver(const Email(id: 'm5', from: ann, to: [me], subject: 'Lunch?', body: 'Unrelated lunch idea', date: 400))
    ..deliver(
      const Email(id: 'm6', from: bob, to: [me], subject: 'Lunch?', body: 'New lunch next month', date: 45 * day),
    );
  check(box.threadView('m1'), ['Lunch?', 'Re: Lunch?', 'RE: re: Lunch?', 'Re: Lunch?']);
  check([box.threadView('m5').length, box.threadView('m6').length], [1, 1]); // different people / too late

  // Labels and unread counts.
  box.deliver(
    const Email(
      id: 'm7',
      from: bob,
      to: [me],
      subject: 'Slides',
      body: 'attached',
      date: 50 * day,
      attachments: ['deck.pdf'],
    ),
  );
  check([box.unreadCount('inbox'), box.labels['m2']], [6, '{sent}']);
  box
    ..markRead('m1')
    ..archive('m3')
    ..addLabel('m7', 'work');
  check([box.unreadCount('inbox'), box.unreadCount('work')], [4, 1]);

  // Search with operators (all terms must match), newest first.
  check(box.search('from:bob@x.com lunch'), ['Lunch?', 'Re: Lunch?', 'RE: re: Lunch?', 'Lunch?']);
  check(box.search('has:attachment label:work'), ['Slides']);
  check(box.search('subject:lunch label:inbox from:ann@y.com'), ['Lunch?']);
  check(box.search('label:inbox great'), '[]'); // m3 was archived

  // Spam rules.
  const scam = Email(
    id: 's1',
    from: 'prince@scam.biz',
    to: [me],
    subject: 'YOU ARE A WINNER',
    body: 'wire transfer now',
    date: 0,
    dkimPass: false,
  );
  check(spamScore(scam), 3 + 2 + 3 + 3);
  box.deliver(scam);
  check([box.labels['s1'], box.unreadCount('inbox')], ['{spam}', 4]);
  check(
    spamScore(
      const Email(id: 'ok', from: bob, to: [me], subject: 'WINNER of the raffle', body: 'you won', date: 0),
      contacts: {bob},
    ),
    3 - 5,
  );

  // Outbound: 4xx retries with backoff, 5xx bounces at once, endless 4xx bounces after 5 days.
  final queue = OutboundQueue();
  const a = Email(id: 'o1', from: me, to: ['x@slow.com'], subject: 'hi', body: '', date: 0);
  const b = Email(id: 'o2', from: me, to: ['nobody@gone.com'], subject: 'hi', body: '', date: 0);
  const c = Email(id: 'o3', from: me, to: ['x@down.com'], subject: 'hi', body: '', date: 0);
  queue
    ..enqueue(a, 0)
    ..enqueue(b, 0)
    ..enqueue(c, 0);
  var slowAttempts = 0;
  int transport(Email e) => switch (e.to.single) {
    'x@slow.com' => ++slowAttempts < 3 ? 421 : 250,
    'nobody@gone.com' => 550,
    _ => 451,
  };
  for (var t = 0; t <= 8 * day; t += 60) {
    queue.process(t, transport);
  }
  check(queue.delivered, ['o1 after 3 attempt(s)']);
  check(
    [queue.bounces.first, queue.bounces.last.startsWith('o3: gave up after'), queue.pending],
    ['o2: permanent failure 550', true, 0],
  );
}
```

## 5. Walkthrough

- `RE: re:  Fwd: Lunch?` normalizes to `lunch?`.
- m2 joins m1's thread through `In-Reply-To`, m3 through `References`. m4 has no headers but the same normalized subject within 30 days and the same participants, so it joins too. m5 (Ann, unrelated) and m6 (45 days later) start new threads.
- After m7 arrives, the inbox has 6 unread messages (m2 is in "sent" and is not unread). Reading m1 and archiving m3 bring it to 4; m7 is also unread under "work".
- `from:bob@x.com lunch` matches Bob's four lunch messages (newest first); `has:attachment label:work` finds the slides; m3 no longer matches `label:inbox`.
- The scam scores 11 (no DKIM 3, all-caps subject 2, "winner" 3, "wire transfer" 3) and goes to spam without touching the inbox count. Bob's raffle email scores -2 ("winner" +3, contact -5) and stays in the inbox.
- Outbound: the slow domain answers 421 twice and then accepts (3 attempts, at 0, 5 and 15 minutes). The `550` is bounced at once. The domain that keeps answering 451 is retried with doubling delays (capped at about 3.5 days) and bounced at the first attempt after 5 days.

## 6. Concurrency

- A user's mailbox is one partition; label changes and deliveries for that user are serialized (or use optimistic versions), so counters stay consistent with labels.
- The search index is updated asynchronously from a change log; reads may lag a moment behind delivery.
- Outbound workers claim queue entries with leases (see 19), so two workers do not deliver the same message; deliveries are idempotent by `Message-ID` on the receiving side in practice.

## 7. Extensibility

| Change | Where |
|---|---|
| Categories (promotions, social) | A classifier adding labels at delivery. |
| Filters ("if from X, label Y") | Rules evaluated in `deliver`. |
| Snooze | Remove `inbox` now; a scheduled job re-adds it (see 19). |
| Attachment dedup | Store attachments by content hash in a blob store (see 13). |
| IMAP | Map labels to folders; UIDs per label. |

## 8. Common mistakes in LLD rounds

- Threading only by subject (unrelated messages merge).
- Folders that copy or move messages.
- Unread counts recomputed by scanning the whole mailbox on every request at scale (keep counters per label).
- Retrying 5xx responses.

See [HLD.md](HLD.md) for SMTP pipelines, storage, spam and deliverability.
