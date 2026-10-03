# Email Service (Gmail / Outlook.com): High-Level Design

**Asked at:** Google, Microsoft, Yahoo, Proton, Amazon (SES). **Core topics:** SMTP inbound and outbound pipelines, spam and authentication (SPF, DKIM, DMARC), mailbox storage (metadata vs bodies vs attachments), labels and threading, per-user search indexes, client sync and push, delivery retries and bounces, quotas.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Users? | 1 B mailboxes, 300 M DAU. |
| Traffic? | ~100 B messages/day received (most is spam), ~10 B delivered to inboxes; ~2 B sent by users. |
| Features? | Send/receive, threads (conversations), labels/folders, search, attachments, spam filtering, push to clients, IMAP/POP for third-party clients. |
| Storage? | 15 GB quota per user; messages kept until deleted. |
| Latency? | New mail visible within seconds; search in < 1 s. |

## 2. Requirements

**Functional:** receive mail from the internet, filter spam/malware, store, organize (labels, threads), search, send with retries and bounce handling, sync to devices.

**Non-functional:** never lose accepted mail (durability), high availability, strong per-user consistency (a label change is seen everywhere), privacy/security, massive storage efficiency.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Inbound SMTP | 100 B/day | **~1.2 M connections/messages per second** to filter |
| Stored mail | 10 B/day x ~75 KB average (with attachments) | **~750 TB/day** before dedup/compression |
| Total storage | 1 B users x ~5 GB used | **~5 EB**: tiered storage, attachment dedup, compression |
| Search index | per-user inverted indexes | roughly 10-30% of text size |

## 4. Architecture

```text
 Internet MTAs --SMTP--> inbound edge (connection-level reputation, rate limits, TLS)
     --> authentication checks (SPF, DKIM signatures, DMARC policy) --> spam/malware classifiers
     --> recipient lookup --> mailbox write path:
            message body + attachments --> blob storage (content-addressed attachments, dedup)
            metadata (headers, labels, thread ID, flags) --> mailbox DB (Bigtable/Spanner style, keyed by user)
            per-user search index update (async, see 22)
            push notification --> devices (IDLE / push channel)
 Clients (web/mobile/IMAP) --> mailbox API: list by label, read thread, modify labels, search
 Send path: compose --> outbound queue --> DKIM-sign --> MX lookup --> deliver via SMTP
            temporary failure (4xx) --> retry with backoff for days; permanent (5xx) --> bounce message to sender
```

## 5. Deep dives

- **Mailbox model:** Gmail uses **labels** (a message can have many; "Inbox" and "Archive" are just presence/absence of the Inbox label) rather than exclusive folders. Unread counts per label maintained as counters.
- **Threading:** use `Message-ID`, `In-Reply-To` and `References` headers to attach replies to their conversation; fall back to normalized subject (strip `Re:`, `Fwd:`) within a time window.
- **Storage:** small hot metadata (fast DB, per-user partition) separated from large immutable bodies/attachments (blob store, deduplicated by content hash, compressed, tiered to cold storage).
- **Search:** per-user inverted index (privacy and simple sharding by user), supporting operators (`from:`, `to:`, `subject:`, `has:attachment`, `label:`).
- **Spam:** connection reputation, SPF/DKIM/DMARC results, content classifiers, user feedback ("report spam") as training data.
- **Outbound deliverability:** dedicated IP pools, DKIM signing, rate limiting per destination domain, bounce/complaint handling.

## 6. Failure modes

| Failure | Behavior |
|---|---|
| Storage write fails during inbound SMTP | Do not acknowledge (`250 OK`) until durably stored; the sender retries (SMTP's built-in reliability). |
| Recipient domain down (outbound) | Queue and retry with backoff up to ~5 days; warn the sender; then bounce. |
| Search indexer behind | Search may miss the newest mail briefly; the mailbox listing is unaffected. |
| Spam wave | Reputation-based throttling at the edge before expensive content filtering. |

## 7. What interviewers look for

- Separate inbound, storage, and outbound paths; acknowledging SMTP only after durable storage.
- Metadata vs blob separation; attachment dedup.
- Labels and threading model.
- Per-user search, spam/authentication layers, retries and bounces.

## 8. Common mistakes

- Storing whole messages (with attachments) in the metadata database.
- Treating folders as physical locations (moving data on every archive).
- Retrying permanent failures; not bouncing.
- A global search index across all users (privacy and scale problems).

## 9. Follow-ups

1. **Encryption at rest and end-to-end** (Proton style): server cannot search; client-side search.
2. **Smart features:** categories (promotions/social), smart replies.
3. **Large attachments:** links to cloud storage instead of MIME attachments.

See [LLD.md](LLD.md) for messages and threading, labels and unread counts, a per-user search index with operators, simple spam rules, and an outbound queue with retries and bounces.
