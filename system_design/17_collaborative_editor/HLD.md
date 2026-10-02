# Collaborative Editor (Google Docs / Notion / Figma multiplayer): High-Level Design

**Asked at:** Google, Microsoft, Atlassian, Notion, Figma, Dropbox. **Core topics:** concurrent edits without locks, Operational Transformation (OT) vs CRDTs, a central ordering server per document, WebSockets, operation logs and snapshots, presence, offline editing.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Content? | Rich text documents (start with plain text; formatting is attributes on ranges). |
| Concurrent editors per document? | Typically a few, up to ~100. |
| Latency? | Local edits appear instantly; others see them within ~100-500 ms. |
| Offline? | Short disconnects must not lose edits; long offline editing is a follow-up. |
| History? | Version history and named versions. |
| Scale? | 100 M documents, 10 M daily active users, ~1 M documents open at once. |

## 2. Requirements

**Functional:** multiple users edit the same document simultaneously; everyone converges to the same content; see collaborators' cursors and selections; comments; version history.

**Non-functional:** convergence (all replicas end identical), intention preservation (an insert lands where the user meant it), low latency (optimistic local apply), durability (no acknowledged edit lost), availability.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Open documents | ~1 M concurrently | each needs an owner process holding state |
| Operations | 1 M docs x ~1 op/s while active (typing is bursty, batched per ~100 ms) | **~1 M ops/s** fleet-wide |
| Connections | ~10 M users online at peak, 1-2 tabs | **~10-20 M WebSockets** |
| Storage | ops are tiny (~50 B) but numerous: snapshots + recent op log | **TBs**, mostly snapshots and history |

## 4. The core problem

Alice and Bob both see `"abc"`. Alice inserts `X` at position 0; Bob deletes position 2 (`c`). If each blindly applies the other's operation, Bob ends with `"Xab"` but Alice, who already has `"Xabc"`, applies "delete 2", removes `b`, and ends with `"Xac"`. They diverge. The fix is to **transform** Bob's operation against Alice's: on Alice's side, delete at 2 becomes delete at 3, and both reach `"Xab"`. Two families of solutions:

| | Operational Transformation (OT) | CRDTs (e.g. RGA, Yjs, Automerge) |
|---|---|---|
| Idea | Positions are indexes; transform concurrent ops against each other | Every character gets a unique, ordered ID; ops refer to IDs, not indexes, so they commute |
| Needs a server? | Practical OT uses a central server that orders ops (Google Docs, Jupiter model) | No: peer-to-peer and offline-first friendly |
| Metadata | Small (ops only) | Per-character IDs and tombstones; larger memory |
| Complexity | Transform functions are subtle; easy with a central server | Data structure is subtle; merge is automatic |
| Used by | Google Docs, older Office Online | Figma-like (custom), Notion-like, Yjs-based editors, Apple Notes |

**Recommendation:** with a server in the loop anyway (permissions, persistence), OT with a central server per document is simple and proven. Mention CRDTs as the choice for offline-first or peer-to-peer.

## 5. Architecture

```text
 browsers --WebSocket--> edge / gateway --(route by document ID)--> Document session server (owns doc D)
                                                                     | in-memory doc + revision + recent ops
                                                                     | transform incoming op, assign revision,
                                                                     | ack sender, broadcast to others
                                                                     v
                                                    op log (append-only, per document) + snapshots every N ops
                                                     (Bigtable / Cassandra / Postgres)
 presence (cursors, selections): ephemeral, broadcast through the same session, never persisted
 document metadata, permissions, comments: regular services + DB
```

- **One owner per open document** (a session server chosen by consistent hashing on the document ID, registered in a lease-based directory). All edits of a document flow through that single process, which gives a total order: the revision number.
- On first open, the owner loads the latest snapshot and replays ops after it.

## 6. Deep dive: the OT protocol (client and server)

- **Client:** applies its own edits immediately; sends one op at a time (the "in-flight" op) tagged with the server revision it is based on; queues further local ops in a buffer until the ack arrives.
- **Server:** transforms the incoming op against every op committed since the client's base revision, applies it, appends it to the log with the next revision, acks the sender, broadcasts to the others.
- **Client on receiving a remote op:** transforms it against its in-flight and buffered ops (and transforms those against it), then applies it. Everyone converges.

## 7. Deep dive: persistence, history and recovery

- The op log is the source of truth; snapshots every few hundred ops (or on idle) bound recovery time.
- Version history = snapshots + ops; "restore version" creates new ops that turn the current document into the old one (history is never rewritten).
- If the session server dies, a new owner loads snapshot + log; clients reconnect and resend their unacknowledged op with its base revision. The server deduplicates by (client ID, client sequence).

## 8. Deep dive: presence

Cursor positions are indexes too, so they are transformed by remote ops exactly like inserts. Presence messages are throttled (e.g. 10/s), ephemeral, and dropped on disconnect.

## 9. Scaling and failure modes

| Concern | Answer |
|---|---|
| Very popular document (1,000 viewers) | Separate viewers (read-only fan-out via a broadcast tier) from editors. |
| Session server failure | Lease expires, another server takes ownership, clients reconnect and resend unacked ops. |
| Hot shard of the op log | Partition by document ID; one document's log is small and append-only. |
| Long offline editing | OT with long-diverged histories is expensive; CRDT-based sync handles it better. |
| Large documents | Split into blocks (Notion) or pages; ops address a block, limiting transform work. |

## 10. What interviewers look for

- Recognizing why naive "apply remote ops" fails, with a concrete example.
- OT vs CRDT, with a reasoned choice.
- A single ordering point per document, and how ownership moves on failure.
- Optimistic local application with in-flight and buffered ops.
- Snapshots + op log for persistence and history.

## 11. Common mistakes

- Locking the document or paragraph while someone types.
- Last-writer-wins on the whole document.
- Broadcasting raw ops without transformation or ordering.
- Persisting every keystroke as a full document copy.

## 12. Follow-ups

1. **Rich text:** formatting as attribute ops on ranges (bold 5..12), transformed like deletes and inserts.
2. **Comments anchored to text:** anchors move with transforms; orphaned comments when text is deleted.
3. **Undo:** per-user undo inverts the user's own ops, transformed against later remote ops.
4. **Access control:** checked at the session server on every op.

See [LLD.md](LLD.md) for the OT transform functions, the server and client state machines, and a randomized convergence test.
