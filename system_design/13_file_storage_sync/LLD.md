# File Storage and Sync: Low-Level Design

## 1. Scope for the LLD round

- **Chunkers** behind one interface: fixed-size, and content-defined (a rolling hash picks boundaries, so inserting bytes does not shift every later chunk).
- **Block store**, content-addressed: `missing(hashes)`; `put(bytes)` computes the hash itself and stores each block once.
- **Metadata server** per namespace: an append-only **journal** with sequence numbers, latest revision per path, `commit(path, blocks, baseRev)` with optimistic concurrency, deletes, history, `changesSince(cursor)`.
- **Sync client**: local files, upload only missing blocks, commit, pull by cursor, and on conflict save a **conflicted copy** instead of losing data.
- Restoring an old version without uploading anything.

Out of scope: notifications transport, sharing, encryption (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Chunker` (interface) | `split(bytes)` into chunks: `FixedSizeChunker`, `ContentDefinedChunker`. |
| `blockHash` | Content address of a chunk (stand-in for SHA-256). |
| `BlockStore` | Hash -> bytes; reports which hashes it lacks; counts stored bytes. |
| `JournalEntry` | One change: sequence, path, revision, block list, deleted flag, device. |
| `MetadataServer` | Journal, latest state, commit with `baseRev`, history, `changesSince`. |
| `CommitResult` (sealed) | `Committed(rev)` or `Conflict(currentRev)`. |
| `SyncClient` | A device: local files, known revisions, cursor; `push`, `pull`, conflict handling. |

```text
SyncClient --uses--> Chunker (interface) <-- FixedSizeChunker, ContentDefinedChunker
     |     --uses--> BlockStore          (1) missing? (2) put
     |     --uses--> MetadataServer      (3) commit(baseRev) -> Committed | Conflict
     +-- cursor -------------------------(4) changesSince(cursor) -> entries, then fetch blocks
```

## 3. Design decisions and why

- **Content addressing gives dedup for free.** The same chunk in two files, two versions or two users has one hash and is stored once.
- **Blocks before commit.** `commit` rejects block lists that reference unknown hashes, so metadata never points at missing data.
- **`baseRev` on commit** (optimistic concurrency): the server accepts only if the path is still at the revision the client edited.
- **Conflicted copy, not last-writer-wins.** The loser's content is committed under a new name; both versions survive.
- **Journal + cursor** as the only sync mechanism: a device that was offline for a minute or a month runs the same code.
- **Chunker as a strategy**, so the classic fixed-vs-content-defined trade-off can be measured in a test.

## 4. The code

```dart
import 'dart:math';

// ---------- Hashing and chunking ----------

/// 64-bit content address from two 32-bit FNV-1a passes. Production uses SHA-256.
String blockHash(List<int> bytes) {
  int fnv(int seed) {
    var h = seed;
    for (final b in bytes) {
      h = ((h ^ b) * 0x01000193) & 0xFFFFFFFF;
    }
    return h;
  }

  return fnv(0x811C9DC5).toRadixString(16).padLeft(8, '0') + fnv(0x01234567).toRadixString(16).padLeft(8, '0');
}

abstract interface class Chunker {
  List<List<int>> split(List<int> data);
}

class FixedSizeChunker implements Chunker {
  FixedSizeChunker(this.size);
  final int size;

  @override
  List<List<int>> split(List<int> data) => [
    for (var i = 0; i < data.length; i += size) data.sublist(i, min(i + size, data.length)),
  ];
}

/// Gear-hash content-defined chunking: a boundary where the rolling hash's low bits are zero,
/// bounded by a minimum and maximum chunk size. Boundaries depend on nearby content, not on offsets.
class ContentDefinedChunker implements Chunker {
  ContentDefinedChunker({this.minSize = 256, this.averageSize = 1024, this.maxSize = 4096}) : _mask = averageSize - 1 {
    final rng = Random(42);
    _gear = List.generate(256, (_) => rng.nextInt(1 << 32));
  }

  final int minSize;
  final int averageSize; // power of two
  final int maxSize;
  final int _mask;
  late final List<int> _gear;

  @override
  List<List<int>> split(List<int> data) {
    final chunks = <List<int>>[];
    var start = 0, h = 0;
    for (var i = 0; i < data.length; i++) {
      h = ((h << 1) + _gear[data[i]]) & 0xFFFFFFFF;
      final len = i - start + 1;
      if ((len >= minSize && (h & _mask) == 0) || len >= maxSize) {
        chunks.add(data.sublist(start, i + 1));
        start = i + 1;
        h = 0;
      }
    }
    if (start < data.length) chunks.add(data.sublist(start));
    return chunks;
  }
}

// ---------- Block store ----------

class BlockStore {
  final _blocks = <String, List<int>>{};
  var bytesReceived = 0;

  List<String> missing(Iterable<String> hashes) => hashes.where((h) => !_blocks.containsKey(h)).toSet().toList();

  String put(List<int> bytes) {
    final hash = blockHash(bytes); // the server computes the address itself; it never trusts the client's
    bytesReceived += bytes.length;
    _blocks.putIfAbsent(hash, () => List.unmodifiable(bytes));
    return hash;
  }

  List<int> get(String hash) => _blocks[hash]!;
  bool has(String hash) => _blocks.containsKey(hash);
  int get uniqueBlocks => _blocks.length;
}

// ---------- Metadata server ----------

class JournalEntry {
  const JournalEntry(this.seq, this.path, this.rev, this.blocks, this.deleted, this.device);
  final int seq;
  final String path;
  final int rev;
  final List<String> blocks;
  final bool deleted;
  final String device;
}

sealed class CommitResult {}

class Committed extends CommitResult {
  Committed(this.rev);
  final int rev;
}

class Conflict extends CommitResult {
  Conflict(this.currentRev);
  final int currentRev;
}

class MissingBlocksException implements Exception {
  MissingBlocksException(this.hashes);
  final List<String> hashes;
}

class MetadataServer {
  MetadataServer(this.blocks);
  final BlockStore blocks;
  final journal = <JournalEntry>[];
  final _latest = <String, JournalEntry>{};

  int revOf(String path) => _latest[path]?.rev ?? 0;
  bool exists(String path) => _latest[path] != null && !_latest[path]!.deleted;

  CommitResult commit(String path, List<String> blockList, {required int baseRev, required String device}) =>
      _append(path, blockList, baseRev: baseRev, device: device, deleted: false);

  CommitResult delete(String path, {required int baseRev, required String device}) =>
      _append(path, const [], baseRev: baseRev, device: device, deleted: true);

  CommitResult _append(
    String path,
    List<String> blockList, {
    required int baseRev,
    required String device,
    required bool deleted,
  }) {
    final missing = blockList.where((h) => !blocks.has(h)).toList();
    if (missing.isNotEmpty) throw MissingBlocksException(missing);
    if (baseRev != revOf(path)) return Conflict(revOf(path)); // someone else changed it first
    final entry = JournalEntry(
      journal.length + 1,
      path,
      revOf(path) + 1,
      List.unmodifiable(blockList),
      deleted,
      device,
    );
    journal.add(entry);
    _latest[path] = entry;
    return Committed(entry.rev);
  }

  /// Every change after [cursor], in order; the new cursor is the last sequence returned.
  (List<JournalEntry>, int) changesSince(int cursor) => (journal.sublist(cursor), journal.length);

  List<JournalEntry> history(String path) => journal.where((e) => e.path == path).toList();
}

// ---------- Client ----------

class SyncClient {
  SyncClient(this.device, this.server, this.chunker);
  final String device;
  final MetadataServer server;
  final Chunker chunker;

  final files = <String, List<int>>{}; // local file system
  final _knownRev = <String, int>{};
  var _cursor = 0;
  var chunksUploaded = 0;
  final log = <String>[];

  void write(String path, List<int> bytes) => files[path] = bytes;

  void push(String path) {
    final bytes = files[path];
    final baseRev = _knownRev[path] ?? 0;
    final CommitResult result;
    if (bytes == null) {
      result = server.delete(path, baseRev: baseRev, device: device);
    } else {
      final chunks = chunker.split(bytes);
      final hashes = [for (final c in chunks) blockHash(c)];
      final missing = server.blocks.missing(hashes).toSet();
      for (final c in chunks) {
        if (missing.remove(blockHash(c))) {
          server.blocks.put(c);
          chunksUploaded++;
        }
      }
      result = server.commit(path, hashes, baseRev: baseRev, device: device);
    }
    switch (result) {
      case Committed(:final rev):
        _knownRev[path] = rev;
        log.add('committed $path rev $rev');
      case Conflict():
        // Keep our edit under a new name, then take the server's version of the original path.
        final copy = '$path ($device conflicted copy)';
        if (bytes != null) {
          files[copy] = bytes;
          push(copy);
        }
        log.add('conflict on $path, saved $copy');
        pull();
    }
  }

  void pull() {
    final (entries, cursor) = server.changesSince(_cursor);
    for (final e in entries) {
      if ((_knownRev[e.path] ?? 0) >= e.rev) continue; // our own change, already applied
      if (e.deleted) {
        files.remove(e.path);
      } else {
        files[e.path] = [for (final h in e.blocks) ...server.blocks.get(h)];
      }
      _knownRev[e.path] = e.rev;
    }
    _cursor = cursor;
  }

  /// Restore an old revision: commit its block list again. No bytes are uploaded.
  void restore(String path, int rev) {
    final old = server.history(path).firstWhere((e) => e.rev == rev);
    final result = server.commit(path, old.blocks, baseRev: _knownRev[path] ?? 0, device: device);
    if (result is Committed) {
      _knownRev[path] = result.rev;
      files[path] = [for (final h in old.blocks) ...server.blocks.get(h)];
    }
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

List<int> text(String s) => s.codeUnits;
String asText(List<int>? b) => b == null ? '<none>' : String.fromCharCodes(b);

void main() {
  final store = BlockStore();
  final server = MetadataServer(store);
  final chunker = FixedSizeChunker(4);
  final laptop = SyncClient('laptop', server, chunker);
  final phone = SyncClient('phone', server, chunker);

  // Create and sync: 12 bytes -> 3 chunks.
  laptop
    ..write('notes.txt', text('aaaabbbbcccc'))
    ..push('notes.txt');
  check(laptop.chunksUploaded, 3);
  phone.pull();
  check(asText(phone.files['notes.txt']), 'aaaabbbbcccc');

  // Delta upload: change one chunk, upload one chunk.
  laptop
    ..write('notes.txt', text('aaaaBBBBcccc'))
    ..push('notes.txt');
  check(laptop.chunksUploaded, 4);

  // Dedup: identical content under another name uploads nothing.
  phone.pull();
  phone
    ..write('copy.txt', text('aaaaBBBBcccc'))
    ..push('copy.txt');
  check([phone.chunksUploaded, store.uniqueBlocks], [0, 4]);

  // A commit that references unknown blocks is rejected (blocks must be uploaded first).
  try {
    server.commit('x', ['deadbeefdeadbeef'], baseRev: 0, device: 'evil');
    throw StateError('should fail');
  } on MissingBlocksException catch (e) {
    check(e.hashes, ['deadbeefdeadbeef']);
  }

  // Conflict: both edit rev 2 offline; laptop wins the race, phone keeps its edit as a conflicted copy.
  laptop.write('notes.txt', text('aaaaBBBBlap!'));
  phone.write('notes.txt', text('aaaaBBBBpho!'));
  laptop.push('notes.txt');
  phone.push('notes.txt');
  check(phone.log.last, 'conflict on notes.txt, saved notes.txt (phone conflicted copy)');
  check(asText(phone.files['notes.txt']), 'aaaaBBBBlap!'); // took the winner
  check(asText(phone.files['notes.txt (phone conflicted copy)']), 'aaaaBBBBpho!');
  laptop.pull();
  check(asText(laptop.files['notes.txt (phone conflicted copy)']), 'aaaaBBBBpho!'); // nothing was lost

  // Delete propagates; history and restore (no upload needed).
  phone
    ..files.remove('copy.txt')
    ..push('copy.txt');
  laptop.pull();
  check(laptop.files.containsKey('copy.txt'), false);
  check(server.history('notes.txt').map((e) => '${e.rev}:${e.device}'), '(1:laptop, 2:laptop, 3:laptop)');
  final before = laptop.chunksUploaded;
  laptop.restore('notes.txt', 1);
  phone.pull();
  check([asText(phone.files['notes.txt']), laptop.chunksUploaded - before], ['aaaabbbbcccc', 0]);

  // Fixed vs content-defined chunking when one byte is inserted at the front.
  final rng = Random(1);
  final data = List.generate(64 * 1024, (_) => rng.nextInt(256));
  final shifted = [7, ...data];
  double reused(Chunker c) {
    final original = c.split(data).map(blockHash).toSet();
    final after = c.split(shifted).map(blockHash).toList();
    return after.where(original.contains).length / after.length;
  }

  final fixedReuse = reused(FixedSizeChunker(1024));
  final cdcReuse = reused(ContentDefinedChunker());
  check(fixedReuse, 0.0); // every boundary moved
  check(cdcReuse > 0.9, true); // only the first chunk changed
  final cdcSizes = ContentDefinedChunker().split(data).map((c) => c.length);
  check(cdcSizes.every((s) => s <= 4096) && cdcSizes.fold(0, (a, b) => a + b) == data.length, true);
}
```

## 5. Walkthrough

- The first push uploads 3 chunks. Changing `bbbb` to `BBBB` produces one new hash, so only one chunk goes up (4 in total).
- `copy.txt` has the same content, so `missing` returns nothing: zero bytes uploaded, still 4 unique blocks on the server.
- Both devices start from rev 2. The laptop commits rev 3; the phone's commit with `baseRev: 2` gets `Conflict(3)`. The phone saves its text as `notes.txt (phone conflicted copy)`, pushes that, and pulls the laptop's version. The laptop then pulls and sees both.
- History shows the three revisions; restoring rev 1 commits its old block list as rev 4 and uploads nothing.
- Inserting one byte at the front shifts every fixed-size boundary (0% of chunks reused). With content-defined chunking, boundaries depend on the bytes around them, so after the first chunk they realign and almost all chunks are reused.

## 6. Concurrency

- `commit` is the critical section: check `baseRev`, append to the journal, update latest, all in one transaction on the namespace's shard (`UPDATE files SET rev = rev + 1 ... WHERE path = ? AND rev = ?` plus the journal insert).
- Journal sequence numbers per namespace must be gap-free and ordered: a per-namespace counter in the same transaction.
- Block uploads need no coordination: the same content always gets the same key, and `putIfAbsent` makes concurrent uploads of one block harmless.
- The client must snapshot the file while chunking (a file edited mid-upload would otherwise produce a block list that matches no real version).

## 7. Extensibility

| Change | Where |
|---|---|
| Real hashes | `blockHash` uses SHA-256; nothing else changes. |
| Large files | Upload missing blocks in parallel; resumable per block. |
| Shared folders | One `MetadataServer` journal per namespace; a user's view mounts several. |
| Selective sync | The client filters which paths `pull` materializes. |
| Garbage collection | Reference counts on blocks, decremented when versions expire. |

## 8. Common mistakes in LLD rounds

- One `File` object holding its bytes, re-uploaded on every change.
- Committing metadata before blocks.
- Last-writer-wins on conflicts.
- Sync by comparing whole directory listings instead of a journal cursor.
- Trusting client-supplied hashes without verification.

See [HLD.md](HLD.md) for the services, notifications and durability.
