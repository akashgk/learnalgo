# Chat System (WhatsApp / Messenger / Slack DMs): High-Level Design

**Asked at:** Meta, Amazon, Microsoft, Uber, Atlassian. **Core topics:** persistent connections (WebSocket), message routing between servers, ordering, delivery guarantees and receipts, offline delivery, presence, group fan-out.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| 1:1, groups, or both? | Both; groups up to 500 members. |
| Platforms? | Mobile and web; a user may be online on several devices. |
| Features? | Send text, delivery and read receipts, online/last-seen presence, history sync, push notifications when offline. Media via links to blob storage. |
| Scale? | 500 M daily active users, ~40 messages sent per user per day. |
| Message retention? | Stored on the server until delivered to all devices, plus history for multi-device sync (assume kept). |
| End-to-end encryption? | Mention it; the server routes opaque ciphertext. Out of scope for the core design. |
| Ordering? | Messages within one conversation appear in the same order for everyone. |

## 2. Requirements

**Functional:** send a message to a user or group; receive it in real time when online; receive it later when offline (plus a push notification); see sent / delivered / read status; see presence; load conversation history.

**Non-functional:**

- **Low latency:** < ~200 ms end to end for online users in the same region.
- **No message loss** once the server acknowledged it; no duplicates shown to the user.
- **Per-conversation ordering.**
- **High availability;** a dropped connection reconnects and catches up.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Messages/day | 500 M x 40 | **20 B/day** |
| Messages/s | 20 B / 86,400 | **~230K/s** avg, ~700K/s peak |
| Concurrent connections | ~30% of DAU online at peak | **~150 M WebSocket connections** |
| Connection servers | ~500K connections per tuned server (memory-bound, ~10-20 KB each) | **~300+ servers**, more for headroom |
| Storage | 20 B x ~200 B (text + metadata) | **~4 TB/day**, ~1.5 PB/year |
| Fan-out writes for groups | average group delivery ~ several recipients | more delivery events than messages; plan for ~1 M deliveries/s |

Conclusions: connection handling is a big fleet of its own; the message store is write-heavy and huge (wide-column store); routing between connection servers needs a lookup of "which server holds user X".

## 4. API

Over a persistent **WebSocket** (fallback: long polling):

```text
client -> server  send      { clientMsgId, conversationId, body }
server -> client  ack       { clientMsgId, messageId, seq, serverTs }        (message stored: "sent")
server -> client  message   { messageId, conversationId, seq, sender, body }
client -> server  delivered { conversationId, upToSeq }                      (device received)
client -> server  read      { conversationId, upToSeq }
server -> client  receipt   { conversationId, userId, status, upToSeq }
client -> server  sync      { conversationId, afterSeq }                    (catch up after reconnect)
heartbeat ping/pong every ~30 s
```

REST for the rest: `GET /conversations/{id}/messages?beforeSeq=&limit=`, group management, media upload (returns a URL).

## 5. Data model

```text
messages        partition key: conversation_id   clustering key: seq (descending)
                columns: message_id, sender_id, body, created_at
                -> one partition read loads a page of history in order (Cassandra / HBase / ScyllaDB)

conversations   conversation_id, type (direct/group), members, last_seq
user_inbox      partition key: user_id    -> conversation_id, last_read_seq, last_delivered_seq, unread_count
sessions        user_id -> [(device_id, connection_server_id)]   (Redis, with TTL refreshed by heartbeats)
```

**Why a wide-column store:** append-heavy writes at 230K/s, reads are "latest N messages of a conversation" which is one partition range scan. A 1:1 conversation ID can be `min(userA, userB):max(userA, userB)`.

**Partition hot spots:** a busy group's partition grows without bound; bucket by time (`conversation_id + month`) to cap partition size.

## 6. Architecture

```text
 clients ==WebSocket==> L4 load balancer ==> Chat (connection) servers  <--->  Session registry (Redis)
                                               |        ^                          user -> server
                                               |        | deliver to local socket
                                    publish    v        |
                                         Message service ------------> Message store (Cassandra)
                                               |   assigns seq,        conversation partitions
                                               |   persists, fans out
                                               v
                                   Kafka (per-server delivery topics / or direct RPC)
                                               |
                                               +--> recipient not online --> Push notification service --> APNs / FCM
                                               +--> Presence service (heartbeats, last seen)
```

**Send path:**

1. Client sends `{clientMsgId, conversationId, body}` over its socket to chat server S1.
2. The message service assigns the next `seq` for the conversation, stores the message, and acknowledges to the sender (`sent`, one grey tick).
3. For each recipient device: look up its connection server in the session registry; forward to that server (direct RPC or its Kafka topic), which writes to the socket.
4. If the recipient has no online device: increment unread, send a push notification. The message waits in the store.
5. The recipient device acknowledges `delivered`; the sender gets a receipt (two ticks). Same for `read`.

## 7. Deep dive: ordering and sequence numbers

- Clocks differ across servers, so timestamps cannot order messages. Use a **per-conversation sequence number** assigned at one place: the owner of the conversation's partition (a single-writer per conversation, chosen by consistent hashing), or an atomic counter (`INCR conv:{id}:seq` in Redis, or a conditional update of `last_seq`).
- Clients display by `seq`. Gaps tell the client it missed something and should `sync`.
- Global ordering across conversations is not needed and would not scale.

## 8. Deep dive: delivery guarantees

- **At-least-once delivery + idempotent display = effectively once.** The server retries delivery until the device acknowledges; the client deduplicates by `messageId` (or `clientMsgId` for its own sends).
- The sender retries a send with the **same `clientMsgId`** if it got no ack; the server deduplicates it (unique index on `(conversation_id, client_msg_id)` or a short-lived cache), so a retry does not create a second message.
- **Offline catch-up:** on reconnect, the client sends `sync(afterSeq = last seq it has)` per conversation (or one call using the inbox's `last_delivered_seq` values). This also fixes anything lost while a connection silently died.
- **Receipts as watermarks:** "delivered/read up to seq N" instead of per-message receipts: far fewer events.

## 9. Deep dive: groups

- Small groups (≤ a few hundred): **fan-out on write** to each member's devices, as in 1:1. The message is stored once (in the conversation partition); only delivery events fan out.
- Very large channels (thousands+, Slack/Discord style): do not push to everyone; push a lightweight "conversation updated" signal to online members, and they fetch.
- Group read receipts: aggregate ("read by 12") rather than streaming every member's receipt to everyone.

## 10. Deep dive: presence

- A user is online while a heartbeat arrives every ~30 s; the presence service stores `user -> last_seen` with a TTL.
- Fan-out of presence changes is expensive (a user with 500 contacts going online triggers 500 events). Only send presence to users who **currently have the chat open** with that person (subscribe on open), and debounce flapping connections.

## 11. Scaling and failure modes

| Concern | Answer |
|---|---|
| Chat server dies | Its clients reconnect (with jittered backoff) to another server, re-register sessions, and `sync`. Nothing is lost because messages are stored before the ack. |
| Session registry stale | Delivery to a dead server fails; fall back to push notification and rely on `sync` at reconnect. |
| Thundering herd after an outage | Jittered reconnect, rate-limited sync, server-side admission control. |
| Hot group | Partition storage by time bucket; batch deliveries per chat server (one RPC carries all local recipients). |
| Multi-region | Users connect to the nearest region; a conversation has a home region that assigns seq; cross-region delivery through replication queues. |
| Message store | Replication factor 3, quorum writes, so the ack means durable. |

## 12. What interviewers look for

- WebSockets and a session registry to route between connection servers.
- Storing before acknowledging; at-least-once delivery with client deduplication.
- Per-conversation sequence numbers (not timestamps) for ordering, and seq-based sync for offline catch-up.
- Separate handling of small groups vs huge channels, and presence fan-out limits.

## 13. Common mistakes

- HTTP polling for real-time delivery at this scale.
- Ordering by client or server timestamps.
- Claiming exactly-once delivery without explaining deduplication.
- Deleting messages from the server on delivery when multi-device sync is required.
- Broadcasting presence changes to every contact.

## 14. Follow-ups

1. **End-to-end encryption:** Signal protocol; the server stores ciphertext; groups use sender keys. Server-side search becomes impossible.
2. **Media:** client uploads to blob storage via a pre-signed URL; the message carries the URL and a thumbnail.
3. **Message edits and deletes:** new events in the same conversation stream (`edit seq 41`), applied by clients.
4. **Search:** index messages asynchronously into Elasticsearch per user (only without E2E encryption).

See [LLD.md](LLD.md) for the classes: conversations, sequence numbers, delivery state machine, offline inbox and receipts.
