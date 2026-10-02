# File Storage and Sync (Dropbox / Google Drive): High-Level Design

**Asked at:** Dropbox, Google, Microsoft, Amazon, Box. **Core topics:** chunking and block-level deduplication, separating metadata from content, sync protocol with cursors, change notifications, conflict resolution, versioning.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Features? | Upload, download, automatic sync across a user's devices, sharing folders, version history, offline edits. |
| File sizes? | Up to tens of GB; most files small. |
| Scale? | 100 M daily active users, ~3 devices each; 1 B file changes/day. |
| Consistency? | A user's devices converge; edits are never silently lost (conflicts become separate copies). |
| Real-time? | Changes reach other online devices within seconds. |
| Collaboration? | Whole-file sync, not real-time co-editing (see 17 Collaborative Editor). |

## 2. Requirements

**Functional:** upload/download; sync changes to all devices; resume interrupted transfers; share; restore previous versions; delete and undelete.

**Non-functional:**

- **Durability is paramount:** never lose a file (11 nines-style storage).
- **Bandwidth efficiency:** transfer only changed parts; never upload content the server already has.
- **Fast sync** notifications; works offline and reconciles later.
- **Scalable** metadata at billions of files.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| File changes | 1 B/day | **~12K commits/s** avg |
| Upload volume | 1 B changes x ~100 KB changed data (after chunk dedup) | **~100 TB/day** new blocks |
| Total storage | 500 M users x ~10 GB used average | **~5 EB** logical; much less physical after dedup |
| Metadata rows | 500 M users x ~5,000 files x a few versions | **~10 T** version/block references: sharded heavily |
| Notification connections | 100 M users x 3 devices online-ish | **~100 M+ long-lived connections** |

## 4. Core idea: split metadata from blocks

```text
file "report.docx" rev 7  ==  [ block a1f3..., block 9c2e..., block 77b0... ]   (metadata: small, transactional)
block 9c2e... == 4 MB of bytes, content-addressed by SHA-256                     (blocks: huge, immutable)
```

- Files are split into **chunks** (fixed 4 MB, or content-defined chunking so an insertion does not shift every later boundary).
- Each chunk is stored once, keyed by its **hash** (content addressing). Identical chunks across versions, files or users are stored once: **deduplication**.
- A file version is just a list of block hashes. A new version that changes 1 byte uploads one block and writes a new list.

## 5. API

```text
POST /blocks/check   { hashes[] }            -> { missing[] }           (client uploads only these)
PUT  /blocks/{hash}  (bytes)                  -> 201                     (server verifies the hash)
POST /files/commit   { path, blocks[], baseRev } -> { rev } | 409 { currentRev }
GET  /changes?cursor=...                      -> { entries[], cursor, hasMore }
GET  /changes/longpoll?cursor=...             -> { changes: true/false }  (blocks up to ~60 s)
GET  /blocks/{hash}                           -> bytes (via CDN / signed URL)
GET  /files/history?path=   POST /files/restore { path, rev }
```

## 6. Data model

```text
namespaces(id, owner)                                    -- a user's root, or a shared folder
journal(namespace_id, seq, path, rev, blocks[], size, deleted, device_id, ts)
        PK (namespace_id, seq): an append-only log of every change, the source of truth for sync
files_latest(namespace_id, path) -> rev, blocks, ...     -- materialized latest state
blocks(hash) -> storage location, size, refcount         -- in a big KV store
Block bytes: object storage (S3-like), erasure-coded, multi-region
```

Metadata in sharded MySQL / a strongly consistent store, sharded by **namespace**, so all changes of one folder tree commit on one shard with a single sequence.

## 7. Architecture

```text
 desktop/mobile client (watcher, chunker, local DB of synced state)
     |  1. check which blocks the server lacks   2. upload missing blocks   3. commit metadata
     v
  API gateway --> Block service --> object storage (blocks, immutable, deduplicated)
             --> Metadata service --> metadata DB (journal per namespace, sharded)
                         |
                         +--> change event --> Notification service --(long poll / WebSocket)--> other devices
                                                                                   4. fetch /changes since cursor
                                                                                   5. download missing blocks
```

Upload order matters: **blocks first, then the metadata commit**. The commit fails if any referenced block is missing, so metadata never points at absent data.

## 8. Deep dive: sync protocol

- Every namespace has a monotonically increasing **journal sequence**. A device stores the last sequence it applied: its **cursor**.
- Catching up = `GET /changes?cursor=N`: everything after N, in order. Works identically after seconds or months offline.
- Notifications only say "something changed" (long poll returns early); the device then pulls by cursor. The notification carries no data, so losing one is harmless: the next poll or reconnect fetches everything.

## 9. Deep dive: conflicts

- Each commit carries `baseRev`: the revision the client edited. If the server's latest revision differs, the commit is rejected (optimistic concurrency).
- Dropbox's answer: keep both. The losing device saves its version as **"report (Alice's conflicted copy 2025-01-02).docx"** and commits that; then it pulls the winner. No data is lost; the user merges.
- Deletes vs edits: an edit wins over a concurrent delete (the file reappears) to avoid losing work.

## 10. Deep dive: durability and versioning

- Blocks are immutable; versions only add references. Restoring a version = committing its old block list (no upload).
- Erasure coding across zones/regions (cheaper than 3 full copies) with background integrity scrubbing (re-hash and repair).
- Garbage collection: blocks with zero references after the retention window are deleted; reference counting plus periodic mark-and-sweep to correct drift.

## 11. Failure modes

| Failure | Behavior |
|---|---|
| Upload interrupted | Blocks already uploaded are kept; the client re-checks missing blocks and continues. |
| Commit succeeds but response lost | Client retries; the commit is idempotent (same path, same blocks, same base) or detected via the journal. |
| Notification service down | Devices fall back to periodic polling by cursor. |
| Two devices edit offline | Conflicted copy, as above. |
| Hash collision | SHA-256: treat as impossible in practice; verify hashes on upload so corruption is caught. |

## 12. What interviewers look for

- Chunking + content-addressed dedup + delta uploads.
- Metadata and block storage separated, with blocks-before-commit ordering.
- A cursor-based change journal and notification-then-pull sync.
- A concrete conflict policy that never loses data.

## 13. Common mistakes

- Uploading whole files on every change.
- Notifications that carry the data (lost messages = lost changes).
- Last-writer-wins that silently discards an edit.
- Storing file bytes in the metadata database.

## 14. Follow-ups

1. **Sharing:** a shared folder is its own namespace mounted in several users' trees; permissions per namespace.
2. **LAN sync:** devices on the same network exchange blocks directly.
3. **Large-file performance:** parallel block uploads; content-defined chunking for files edited in the middle.
4. **Client-side encryption:** dedup only within one user (convergent encryption leaks equality).

See [LLD.md](LLD.md) for chunkers (fixed and content-defined), the block store, the journal with cursors, and conflict handling.
