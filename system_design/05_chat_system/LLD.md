# Chat System: Low-Level Design

## 1. Scope for the LLD round

- Users with **multiple devices**; devices connect and disconnect.
- **Direct** (1:1) and **group** conversations.
- `send` with a client-generated ID: retries never create duplicates.
- **Per-conversation sequence numbers** for ordering.
- Status per message: **sent -> delivered -> read**, tracked as per-member watermarks; status never goes backwards.
- Real-time delivery to online devices (including the sender's other devices), a **push notification** for members with no online device, and **sync** to catch up after reconnecting.
- Unread counts.

Out of scope: networking, storage engines, encryption (see HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Message` | Immutable: ID, conversation, seq, sender, body, client message ID, time. |
| `Conversation` | Members, messages in seq order, next seq, dedup index of client IDs, per-member watermarks. |
| `MemberState` | `deliveredUpTo` and `readUpTo` for one member; only moves forward. |
| `MessageStatus` (enum) | `sent`, `delivered`, `read` (ordered). |
| `ChatEvent` (sealed) | `NewMessageEvent`, `ReceiptEvent`: what is pushed to devices. |
| `DeviceConnection` (interface) | Observer: receives events. A WebSocket in production, a recording fake in tests. |
| `PushNotifier` (interface) | Called when a member has no online device. |
| `ChatService` | Facade: connect, conversations, send, receipts, sync, unread, status. |

```text
ChatService --has many--> Conversation --has many--> Message
     |                          |
     |                          +--per member--> MemberState (watermarks)
     +--online devices--> DeviceConnection (observer) <-- WebSocketConnection / RecordingDevice
     +--uses--> PushNotifier
     +--uses--> Clock
```

## 3. Design decisions and why

- **Sequence numbers, not timestamps,** order messages. The conversation is the single writer of its own counter.
- **Watermarks instead of per-message receipts.** "Bob has read up to seq 57" is one integer per member, not one row per message per member. A message's status for one member is derived: `seq <= readUpTo` means read. Watermarks only increase, which makes duplicate or out-of-order receipts harmless.
- **Read implies delivered:** marking read also raises the delivered watermark.
- **Idempotent send:** `(conversationId, clientMsgId)` maps to the existing message. The sender retries safely after a timeout.
- **Store first, then deliver.** The message is in the conversation before any device sees it; delivery can fail and be repaired by `sync`.
- **Sender's status = minimum over the other members** (delivered to everyone = two ticks). Group UIs often show "delivered to 3 of 5" instead; both are derivable from watermarks.
- **Observer for devices** keeps the service independent of transport.
- **Sealed event classes** so a device handler can switch over event types exhaustively.

## 4. The code

```dart
// ---------- Time ----------

abstract interface class Clock {
  DateTime now();
}

class FakeClock implements Clock {
  FakeClock(this._now);
  DateTime _now;
  @override
  DateTime now() => _now = _now.add(const Duration(milliseconds: 1));
}

// ---------- Domain ----------

enum MessageStatus { sent, delivered, read }

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.seq,
    required this.senderId,
    required this.body,
    required this.clientMsgId,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final int seq;
  final String senderId;
  final String body;
  final String clientMsgId;
  final DateTime createdAt;

  @override
  String toString() => '#$seq $senderId: $body';
}

class MemberState {
  int deliveredUpTo = 0;
  int readUpTo = 0;

  MessageStatus statusOf(int seq) => seq <= readUpTo
      ? MessageStatus.read
      : seq <= deliveredUpTo
      ? MessageStatus.delivered
      : MessageStatus.sent;
}

enum ConversationType { direct, group }

class Conversation {
  Conversation({required this.id, required this.type, required Set<String> members, this.name})
    : members = Set.unmodifiable(members),
      _state = {for (final m in members) m: MemberState()};

  final String id;
  final ConversationType type;
  final Set<String> members;
  final String? name;
  final List<Message> messages = [];
  final Map<String, MemberState> _state;
  final Map<String, Message> _byClientId = {};

  int get lastSeq => messages.length; // seq starts at 1 and has no gaps
  MemberState stateOf(String userId) => _state[userId]!;
}

// ---------- Events and ports ----------

sealed class ChatEvent {}

class NewMessageEvent extends ChatEvent {
  NewMessageEvent(this.message);
  final Message message;
}

class ReceiptEvent extends ChatEvent {
  ReceiptEvent(this.conversationId, this.userId, this.status, this.upToSeq);
  final String conversationId;
  final String userId;
  final MessageStatus status;
  final int upToSeq;
}

abstract interface class DeviceConnection {
  void deliver(ChatEvent event);
}

abstract interface class PushNotifier {
  void notify(String userId, Message message);
}

class UnknownConversationException implements Exception {
  UnknownConversationException(this.conversationId);
  final String conversationId;
}

class NotAMemberException implements Exception {
  NotAMemberException(this.userId, this.conversationId);
  final String userId;
  final String conversationId;
}

// ---------- Service ----------

class ChatService {
  ChatService({required Clock clock, required PushNotifier pushNotifier}) : _clock = clock, _push = pushNotifier;

  final Clock _clock;
  final PushNotifier _push;
  final _conversations = <String, Conversation>{};
  final _devices = <String, Map<String, DeviceConnection>>{}; // userId -> deviceId -> connection
  var _nextMessageId = 1;
  var _nextGroupId = 1;

  // --- connections ---

  void connect(String userId, String deviceId, DeviceConnection connection) =>
      _devices.putIfAbsent(userId, () => {})[deviceId] = connection;

  void disconnect(String userId, String deviceId) {
    final devices = _devices[userId];
    devices?.remove(deviceId);
    if (devices != null && devices.isEmpty) _devices.remove(userId);
  }

  bool isOnline(String userId) => _devices.containsKey(userId);

  // --- conversations ---

  /// The same pair always maps to the same conversation, whoever starts it.
  Conversation direct(String a, String b) {
    final id = a.compareTo(b) < 0 ? 'dm:$a:$b' : 'dm:$b:$a';
    return _conversations.putIfAbsent(id, () => Conversation(id: id, type: ConversationType.direct, members: {a, b}));
  }

  Conversation createGroup(String name, Set<String> members) {
    final id = 'g${_nextGroupId++}';
    return _conversations[id] = Conversation(id: id, type: ConversationType.group, members: members, name: name);
  }

  Conversation _get(String conversationId, String userId) {
    final c = _conversations[conversationId];
    if (c == null) throw UnknownConversationException(conversationId);
    if (!c.members.contains(userId)) throw NotAMemberException(userId, conversationId);
    return c;
  }

  // --- messages ---

  Message send(String senderId, String conversationId, String clientMsgId, String body) {
    final c = _get(conversationId, senderId);
    final existing = c._byClientId[clientMsgId];
    if (existing != null) return existing; // retry of a message we already stored

    final message = Message(
      id: 'm${_nextMessageId++}',
      conversationId: c.id,
      seq: c.lastSeq + 1,
      senderId: senderId,
      body: body,
      clientMsgId: clientMsgId,
      createdAt: _clock.now(),
    );
    c.messages.add(message); // store before delivering
    c._byClientId[clientMsgId] = message;
    final sender = c.stateOf(senderId); // the sender has obviously seen their own message
    sender
      ..deliveredUpTo = message.seq
      ..readUpTo = message.seq;

    for (final member in c.members) {
      final devices = _devices[member];
      if (devices == null) {
        if (member != senderId) _push.notify(member, message);
        continue;
      }
      for (final device in devices.values) {
        device.deliver(NewMessageEvent(message)); // includes the sender's other devices
      }
    }
    return message;
  }

  void markDelivered(String userId, String conversationId, int upToSeq) =>
      _advance(userId, conversationId, upToSeq, MessageStatus.delivered);

  void markRead(String userId, String conversationId, int upToSeq) =>
      _advance(userId, conversationId, upToSeq, MessageStatus.read);

  void _advance(String userId, String conversationId, int upToSeq, MessageStatus status) {
    final c = _get(conversationId, userId);
    final s = c.stateOf(userId);
    final seq = upToSeq > c.lastSeq ? c.lastSeq : upToSeq; // cannot acknowledge the future
    final before = (s.deliveredUpTo, s.readUpTo);
    if (seq > s.deliveredUpTo) s.deliveredUpTo = seq; // read implies delivered
    if (status == MessageStatus.read && seq > s.readUpTo) s.readUpTo = seq;
    if ((s.deliveredUpTo, s.readUpTo) == before) return; // stale or duplicate receipt: no event

    final event = ReceiptEvent(c.id, userId, status, seq);
    for (final member in c.members.where((m) => m != userId)) {
      for (final device in (_devices[member] ?? const <String, DeviceConnection>{}).values) {
        device.deliver(event);
      }
    }
  }

  /// Catch up after reconnecting: everything after the last seq the device has.
  List<Message> sync(String userId, String conversationId, int afterSeq) {
    final c = _get(conversationId, userId);
    return c.messages.sublist(afterSeq.clamp(0, c.lastSeq));
  }

  /// Messages from others that the user has not read. O(unread); production keeps a counter per inbox row.
  int unreadCount(String userId, String conversationId) {
    final c = _get(conversationId, userId);
    return c.messages.skip(c.stateOf(userId).readUpTo).where((m) => m.senderId != userId).length;
  }

  /// What the sender sees: the lowest status across all other members.
  MessageStatus statusForSender(Message m) {
    final c = _conversations[m.conversationId]!;
    return c.members
        .where((u) => u != m.senderId)
        .map((u) => c.stateOf(u).statusOf(m.seq))
        .reduce((a, b) => a.index < b.index ? a : b);
  }
}

// ---------- Test doubles ----------

class RecordingDevice implements DeviceConnection {
  final events = <ChatEvent>[];
  @override
  void deliver(ChatEvent event) => events.add(event);

  List<String> get texts => [
    for (final e in events)
      switch (e) {
        NewMessageEvent(:final message) => '$message',
        ReceiptEvent(:final userId, :final status, :final upToSeq) => '$userId ${status.name} <=$upToSeq',
      },
  ];
}

class RecordingPush implements PushNotifier {
  final sent = <String>[];
  @override
  void notify(String userId, Message message) => sent.add('$userId <- ${message.body}');
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
  final push = RecordingPush();
  final chat = ChatService(clock: FakeClock(DateTime.utc(2025)), pushNotifier: push);
  final alicePhone = RecordingDevice(), aliceLaptop = RecordingDevice(), bobPhone = RecordingDevice();
  chat
    ..connect('alice', 'phone', alicePhone)
    ..connect('alice', 'laptop', aliceLaptop)
    ..connect('bob', 'phone', bobPhone);

  // Direct conversation: same ID regardless of who starts it.
  final dm = chat.direct('alice', 'bob');
  check(identical(dm, chat.direct('bob', 'alice')), true);

  // Send, real-time delivery, and idempotent retry.
  final m1 = chat.send('alice', dm.id, 'c-1', 'hi bob');
  check(bobPhone.texts, ['#1 alice: hi bob']);
  check(aliceLaptop.texts, ['#1 alice: hi bob']); // sender's other device stays in sync
  final retry = chat.send('alice', dm.id, 'c-1', 'hi bob');
  check([identical(retry, m1), dm.lastSeq, bobPhone.events.length], [true, 1, 1]);
  check(chat.statusForSender(m1), MessageStatus.sent);

  // Receipts move status forward and notify the other side; stale receipts are ignored.
  chat.markDelivered('bob', dm.id, 1);
  check(chat.statusForSender(m1), MessageStatus.delivered);
  check(alicePhone.texts.last, 'bob delivered <=1');
  final m2 = chat.send('alice', dm.id, 'c-2', 'lunch?');
  chat.markRead('bob', dm.id, 2); // read implies delivered
  check([chat.statusForSender(m1), chat.statusForSender(m2)], [MessageStatus.read, MessageStatus.read]);
  final eventsBefore = alicePhone.events.length;
  chat.markDelivered('bob', dm.id, 1); // late, duplicate receipt
  check([chat.statusForSender(m2), alicePhone.events.length], [MessageStatus.read, eventsBefore]);
  chat.markRead('bob', dm.id, 99); // clamped to the last seq
  check(dm.stateOf('bob').readUpTo, 2);

  // Offline member: push notification, unread count, then sync on reconnect.
  chat.disconnect('bob', 'phone');
  check(chat.isOnline('bob'), false);
  chat.send('alice', dm.id, 'c-3', 'are you there?');
  chat.send('alice', dm.id, 'c-4', 'ping');
  check(push.sent, ['bob <- are you there?', 'bob <- ping']);
  check(chat.unreadCount('bob', dm.id), 2);
  check(chat.unreadCount('alice', dm.id), 0); // own messages are never unread
  final bobTablet = RecordingDevice();
  chat.connect('bob', 'tablet', bobTablet);
  check(chat.sync('bob', dm.id, 2), ['#3 alice: are you there?', '#4 alice: ping']);
  check(chat.sync('bob', dm.id, 4), []);

  // Group: status is the minimum over members; offline members get pushes.
  final group = chat.createGroup('trip', {'alice', 'bob', 'carol'});
  final g1 = chat.send('bob', group.id, 'b-1', 'tickets booked');
  check(bobTablet.texts.last, '#1 bob: tickets booked');
  check(push.sent.last, 'carol <- tickets booked');
  chat.markDelivered('alice', group.id, 1);
  check(chat.statusForSender(g1), MessageStatus.sent); // carol has not received it
  chat.markRead('carol', group.id, 1);
  check(chat.statusForSender(g1), MessageStatus.delivered); // alice delivered, carol read -> min is delivered
  chat.markRead('alice', group.id, 1);
  check(chat.statusForSender(g1), MessageStatus.read);

  // Access control.
  expectThrows<NotAMemberException>(() => chat.send('carol', dm.id, 'x', 'sneaky'));
  expectThrows<UnknownConversationException>(() => chat.sync('alice', 'nope', 0));
}
```

## 5. Walkthrough

- `direct('bob', 'alice')` sorts the pair, so both users land in `dm:alice:bob`.
- The retry with `c-1` returns the stored message: no new seq, no second event to Bob. This is what makes client retries safe.
- Bob's late `markDelivered(1)` after `markRead(2)` changes nothing (watermarks only rise), so no event is sent.
- While Bob is offline, both messages trigger push notifications. His new tablet asks for everything after seq 2 (the last seq the client has) and receives exactly messages 3 and 4.
- In the group, after Alice is `delivered` and Carol is `read`, Bob sees `delivered`: the weakest status among members.

## 6. Concurrency

- **Seq assignment** must be atomic per conversation: a lock per conversation (striped locks), a single-threaded actor per conversation, or an atomic counter in the store. Two senders must never get the same seq.
- The **dedup check and the insert** must be one atomic step (unique constraint on `(conversation_id, client_msg_id)` in the database).
- Watermark updates are `max` operations: commutative and idempotent, so they can be applied with compare-and-set or `UPDATE ... SET read_up_to = GREATEST(read_up_to, ?)`.
- Delivery to sockets happens outside the conversation lock, so a slow device cannot block senders.

## 7. Extensibility

| Change | Where |
|---|---|
| Edit / delete message | New event types appended to the conversation stream with their own seq. |
| Typing indicators | Ephemeral `ChatEvent`, never stored. |
| Per-device delivery tracking | `MemberState` per device instead of per user. |
| Mute a conversation | Check a per-member setting before calling `PushNotifier`. |
| Large channels | Replace per-device push of the full message with a "conversation updated" event and pull. |

## 8. Common mistakes in LLD rounds

- Storing a status field on `Message` (which member's status?).
- Per-message, per-recipient receipt objects (works, but much heavier than watermarks).
- Allowing status to go backwards on a late receipt.
- Not deduplicating retries.
- Forgetting the sender's other devices.

See [HLD.md](HLD.md) for connection servers, routing, storage and presence.
