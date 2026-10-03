# Search Engine: Low-Level Design

## 1. Scope for the LLD round

- **Analysis:** tokenize (lowercase, split on non-alphanumerics), drop stopwords, light stemming (`engines` -> `engine`).
- **Inverted index** with positions: term -> sorted doc IDs -> positions; document lengths; deletes as tombstones.
- **Queries:** AND (all terms, by intersecting sorted postings, shortest list first), OR (any term), and **phrases** in quotes (positions must be consecutive).
- **Ranking with BM25** (term frequency saturation, inverse document frequency, length normalization).
- **Sharded search:** documents spread over shards; the coordinator gathers **global statistics** so scores are comparable, scatters the query, and merges the top k.

Out of scope: crawling, link analysis, learned ranking, compression (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `analyze` / `stem` | Text -> normalized terms (the same function for documents and queries). |
| `Query` | Parsed terms, phrase groups, AND/OR mode. |
| `CorpusStats` | Document count, average length, document frequency per term. |
| `InvertedIndex` | Postings, lengths, tombstones; candidate retrieval; phrase check; BM25; local stats. |
| `ShardedSearch` | Routes documents to shards; merges stats; scatter-gather top k. |

```text
ShardedSearch --has many--> InvertedIndex (term -> SplayTreeMap<docId, positions>)
      |   1. gather CorpusStats from every shard and merge them
      |   2. scatter query + global stats; each shard returns its local top k
      +-- 3. merge into the global top k
```

## 3. Design decisions and why

- **Same analyzer for documents and queries:** otherwise `Engines` in a query would never match `engine` in the index.
- **Postings sorted by doc ID** (a `SplayTreeMap`), so intersection is a merge of sorted lists; starting from the shortest list bounds the work by the rarest term.
- **Positions stored per posting** to support phrases without re-reading documents.
- **BM25 instead of raw term counts:** repeated terms help with diminishing returns (`k1`), long documents are not favored just for being long (`b`), and rare terms weigh more (`idf`).
- **Statistics are a parameter of scoring.** A single index uses its own; a sharded search passes global ones. This makes the "per-shard IDF" problem visible and fixable.
- **Tombstones for deletes:** removing a document from every postings list is expensive; real engines mark it deleted and purge during segment merges.

## 4. The code

```dart
import 'dart:collection';
import 'dart:math';

// ---------- Analysis ----------

const stopwords = {'a', 'an', 'and', 'are', 'by', 'for', 'in', 'is', 'of', 'on', 'or', 'the', 'to', 'with', 'about'};

/// Deliberately small suffix stripping (a real system uses Porter/Snowball or lemmatization).
String stem(String w) {
  if (w.length > 4 && w.endsWith('ies')) return '${w.substring(0, w.length - 3)}y';
  if (w.length > 5 && w.endsWith('ing')) return w.substring(0, w.length - 3);
  if (w.length > 4 && w.endsWith('ed')) return w.substring(0, w.length - 2);
  if (w.length > 3 && w.endsWith('s') && !w.endsWith('ss')) return w.substring(0, w.length - 1);
  return w;
}

List<String> analyze(String text) => [
  for (final raw in text.toLowerCase().split(RegExp(r'[^a-z0-9]+')))
    if (raw.isNotEmpty && !stopwords.contains(raw)) stem(raw),
];

class Query {
  Query(String text, {this.matchAll = true})
    : phrases = [for (final m in RegExp(r'"([^"]+)"').allMatches(text)) analyze(m[1]!)],
      terms = analyze(text.replaceAll('"', ' ')).toSet().toList();
  final List<String> terms;
  final List<List<String>> phrases;
  final bool matchAll;
}

// ---------- Index ----------

class CorpusStats {
  CorpusStats(this.documents, this.totalLength, this.docFreq);
  final int documents;
  final int totalLength;
  final Map<String, int> docFreq;
  double get avgLength => documents == 0 ? 0 : totalLength / documents;

  static CorpusStats merge(Iterable<CorpusStats> parts) {
    final df = <String, int>{};
    var n = 0, len = 0;
    for (final p in parts) {
      n += p.documents;
      len += p.totalLength;
      p.docFreq.forEach((t, c) => df[t] = (df[t] ?? 0) + c);
    }
    return CorpusStats(n, len, df);
  }
}

class InvertedIndex {
  static const k1 = 1.2, b = 0.75;

  final _postings = <String, SplayTreeMap<int, List<int>>>{};
  final _length = <int, int>{};
  final _deleted = <int>{};

  void add(int docId, String text) {
    final terms = analyze(text);
    _length[docId] = terms.length;
    _deleted.remove(docId);
    for (var pos = 0; pos < terms.length; pos++) {
      _postings.putIfAbsent(terms[pos], SplayTreeMap.new).putIfAbsent(docId, () => []).add(pos);
    }
  }

  void delete(int docId) => _deleted.add(docId);

  Iterable<int> _docs(String term) => (_postings[term]?.keys ?? const <int>[]).where((d) => !_deleted.contains(d));

  CorpusStats stats(Iterable<String> terms) => CorpusStats(
    _length.length - _deleted.length,
    _length.entries.where((e) => !_deleted.contains(e.key)).fold(0, (s, e) => s + e.value),
    {for (final t in terms) t: _docs(t).length},
  );

  /// Intersection of sorted postings, shortest list first.
  List<int> _all(List<String> terms) {
    if (terms.isEmpty) return [];
    final lists = [for (final t in terms) _docs(t).toList()]..sort((x, y) => x.length.compareTo(y.length));
    var result = lists.first;
    for (final next in lists.skip(1)) {
      final merged = <int>[];
      var i = 0, j = 0;
      while (i < result.length && j < next.length) {
        if (result[i] == next[j]) {
          merged.add(result[i]);
          i++;
          j++;
        } else if (result[i] < next[j]) {
          i++;
        } else {
          j++;
        }
      }
      result = merged;
    }
    return result;
  }

  bool _hasPhrase(int docId, List<String> phrase) {
    final first = _postings[phrase.first]?[docId] ?? const <int>[];
    return first.any(
      (p) => [
        for (var i = 1; i < phrase.length; i++) i,
      ].every((i) => _postings[phrase[i]]?[docId]?.contains(p + i) ?? false),
    );
  }

  double bm25(int docId, List<String> terms, CorpusStats s) {
    var score = 0.0;
    for (final t in terms) {
      final tf = _postings[t]?[docId]?.length ?? 0;
      if (tf == 0) continue;
      final df = s.docFreq[t] ?? 0;
      final idf = log(1 + (s.documents - df + 0.5) / (df + 0.5));
      score += idf * tf * (k1 + 1) / (tf + k1 * (1 - b + b * _length[docId]! / s.avgLength));
    }
    return score;
  }

  /// Top [k] (docId, score), best first; ties by doc ID. [globalStats] overrides this shard's own statistics.
  List<(int, double)> search(Query q, {int k = 10, CorpusStats? globalStats}) {
    final candidates = q.matchAll ? _all(q.terms) : {for (final t in q.terms) ..._docs(t)}.toList();
    final s = globalStats ?? stats(q.terms);
    final scored = [
      for (final d in candidates)
        if (q.phrases.every((p) => _hasPhrase(d, p))) (d, bm25(d, q.terms, s)),
    ]..sort((x, y) => x.$2 != y.$2 ? y.$2.compareTo(x.$2) : x.$1.compareTo(y.$1));
    return scored.take(k).toList();
  }
}

// ---------- Sharding ----------

class ShardedSearch {
  ShardedSearch(int shardCount) : shards = List.generate(shardCount, (_) => InvertedIndex());
  final List<InvertedIndex> shards;

  void add(int docId, String text) => shards[docId % shards.length].add(docId, text);

  List<(int, double)> search(Query q, {int k = 10, bool useGlobalStats = true}) {
    final global = CorpusStats.merge([for (final s in shards) s.stats(q.terms)]); // gather phase
    final merged = [
      for (final s in shards) ...s.search(q, k: k, globalStats: useGlobalStats ? global : null), // scatter phase
    ]..sort((x, y) => x.$2 != y.$2 ? y.$2.compareTo(x.$2) : x.$1.compareTo(y.$1));
    return merged.take(k).toList();
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

List<int> ids(List<(int, double)> results) => [for (final r in results) r.$1];
List<int> sortedIds(List<(int, double)> results) => ids(results)..sort();

void main() {
  check(analyze('The Search Engines are ranking pages, quickly!'), ['search', 'engine', 'rank', 'page', 'quickly']);

  const docs = {
    1: 'The search engine indexes web pages',
    2: 'Search engines rank pages by relevance; search quality matters',
    3: 'A cooking blog about pasta',
    4: 'Engine repair for old cars',
    5: 'Web search engine ranking with BM25 and page quality',
  };
  final index = InvertedIndex();
  docs.forEach(index.add);

  // AND vs OR retrieval.
  check(sortedIds(index.search(Query('search engine'))), [1, 2, 5]);
  check(sortedIds(index.search(Query('search engine', matchAll: false))), [1, 2, 4, 5]);
  check(ids(index.search(Query('pasta recipes'))), []);

  // Phrases need consecutive positions.
  check(ids(index.search(Query('"page quality"'))), [5]);
  check(sortedIds(index.search(Query('"search engine"'))), [1, 2, 5]);
  check(ids(index.search(Query('"engine search"'))), []);

  // BM25 properties on controlled documents.
  final small = InvertedIndex()
    ..add(10, 'apple fruit tree')
    ..add(11, 'apple apple tree') // same length, higher term frequency
    ..add(12, 'cherry fruit tree')
    ..add(13, 'banana fruit tree');
  check(ids(small.search(Query('apple'))), [11, 10]);
  final orResults = small.search(Query('apple cherry', matchAll: false));
  check(ids(orResults), [12, 11, 10]); // one rare 'cherry' beats two common 'apple's
  final s = small.stats(['apple', 'cherry']);
  check(small.bm25(12, ['cherry'], s) > small.bm25(10, ['apple'], s), true); // rarer term (df 1 vs 2) weighs more
  final longDoc = InvertedIndex()
    ..add(20, 'apple tree')
    ..add(21, 'apple tree with many other unrelated words in this long sentence')
    ..add(22, 'nothing here');
  check(ids(longDoc.search(Query('apple'))), [20, 21]); // length normalization

  // Deletes are tombstones: hidden from results and statistics.
  index.delete(5);
  check(ids(index.search(Query('"page quality"'))), []);
  check(index.stats(['search']).docFreq['search'], 2);

  // Sharded search with global statistics equals the single index exactly.
  final single = InvertedIndex();
  final sharded = ShardedSearch(3);
  final corpus = {
    for (var i = 0; i < 60; i++)
      i: [
        'search',
        if (i % 2 == 0) 'engine',
        if (i % 3 == 0) 'ranking',
        if (i % 7 == 0) 'quality',
        for (var j = 0; j < i % 5; j++) 'filler',
      ].join(' '),
  };
  corpus.forEach(single.add);
  corpus.forEach(sharded.add);
  for (final text in ['search engine', 'ranking quality', 'engine quality']) {
    final q = Query(text, matchAll: false);
    final expected = single.search(q, k: 5);
    final actual = sharded.search(q, k: 5);
    if ('$expected' != '$actual') throw StateError('sharded results differ for "$text"');
  }
  print('ok: sharded results match the single index');
  final q = Query('ranking quality', matchAll: false);
  check('${sharded.search(q, k: 5, useGlobalStats: false)}' == '${single.search(q, k: 5)}', false); // local IDF skews
}
```

## 5. Walkthrough

- Analysis turns `Engines` into `engine` and `ranking` into `rank`, and drops `the` and `are`.
- `search engine` (AND) matches 1, 2 and 5; doc 4 has only `engine`, so it appears only in OR mode.
- `"page quality"` matches only doc 5 (doc 2 has `search quality`). `"engine search"` matches nothing because the order is wrong.
- BM25: doc 11 (`apple` twice) beats doc 10 at equal length. For `apple cherry` in OR mode, doc 12 wins: `cherry` appears in 1 of 4 documents (idf = ln(1 + 3.5/1.5) ≈ 1.20) while `apple` appears in 2 (idf = ln 2 ≈ 0.69), and saturation means two `apple`s score only 1.375 times one. A short document with `apple` beats a long one.
- After deleting doc 5, the phrase disappears and `search` has a document frequency of 2.
- Sixty generated documents over 3 shards: with global statistics the sharded top 5 equals the single index exactly. With per-shard statistics, the scores (and so possibly the order) differ.

## 6. Concurrency

- Serving indexes are immutable segments; new documents go into a new in-memory segment that is periodically sealed and merged. Readers never lock.
- Deletes flip bits in a per-segment tombstone bitmap (atomic swap of the bitmap reference).
- Scatter-gather runs shard requests in parallel with a deadline; late shards are dropped (partial results) or hedged to another replica.

## 7. Extensibility

| Change | Where |
|---|---|
| Field weights (title vs body) | Separate postings per field; sum weighted BM25 scores (BM25F). |
| Proximity boost | Use positions to reward terms close together. |
| Static quality (PageRank) | Add a per-document prior to the score. |
| Compression | Delta-encode doc IDs and positions; variable-byte codes. |
| Synonyms / spelling | Expand query terms before retrieval. |

## 8. Common mistakes in LLD rounds

- Analyzing documents and queries differently.
- Intersecting postings with nested loops (O(n x m)) instead of a sorted merge.
- Ranking by term counts only (long documents and common words win).
- Ignoring deletes and updates.
- Per-shard statistics treated as if they were global.

See [HLD.md](HLD.md) for the indexing pipeline, partitioning and serving architecture.
