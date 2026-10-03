# Proximity Service: Low-Level Design

## 1. Scope for the LLD round

- **Geohash**: encode, bounding box, the 8 **neighbors** (with longitude wrap-around at the antimeridian), and the **precision** to use for a given radius.
- **Geohash index**: business IDs keyed by full geohash in a sorted map; a cell lookup is a **prefix range scan** (exactly what `WHERE geohash LIKE 'abc%'` does on a B-tree).
- **Nearby search**: center cell + 8 neighbors, exact haversine filter, optional category, sorted by distance, limited.
- **Quadtree** as the alternative index: splits a node when it exceeds its capacity; rectangle query, then exact filter.
- Updates (a business moves) and validation of both indexes against brute force.

Out of scope: ranking by rating, caching, the business database (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `geohashEncode`, `geohashBounds`, `geohashNeighbors`, `precisionForRadius` | Geohash math. |
| `haversineKm` | Great-circle distance. |
| `Business` | ID, location, category. |
| `GeohashIndex` | Sorted map geohash -> IDs; add, remove, move, `nearby`. |
| `QuadTree` | Adaptive spatial partition; `insert`, `queryRect`, `nearby`. |

```text
GeohashIndex: SplayTreeMap<geohash(9 chars), Set<id>>  --prefix scan for each of 9 cells--> candidates --> exact filter
QuadTree: node(bounds, points | 4 children)            --rectangle overlap descent-------> candidates --> exact filter
```

## 3. Design decisions and why

- **Store the full-precision geohash once; query any precision by prefix.** One index serves every radius, and the same idea works in any database with ordered string indexes.
- **Precision from the radius:** the longest precision whose cell height and width (at this latitude) are both at least the radius. Then every point within the radius lies in the center cell or one of its 8 neighbors.
- **Neighbors computed geometrically** (move one cell height/width from the center and re-encode), with longitude wrapped. Simpler to get right than lookup tables.
- **Exact distance after the coarse filter:** cells are rectangles; the query is a circle.
- **Quadtree splits by count**, so dense areas get small cells and empty areas stay as one node. A depth cap stops infinite splitting when many points share a location.

## 4. The code

```dart
import 'dart:collection';
import 'dart:math';

// ---------- Geometry ----------

const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
const _kmPerDegLat = 111.2;

double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  double rad(double d) => d * pi / 180;
  final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
  final h = pow(sin(dLat / 2), 2) + cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(dLng / 2), 2);
  return 2 * 6371 * asin(sqrt(h));
}

String geohashEncode(double lat, double lng, int precision) {
  var latLo = -90.0, latHi = 90.0, lngLo = -180.0, lngHi = 180.0;
  final out = StringBuffer();
  var even = true, bits = 0, ch = 0;
  while (out.length < precision) {
    if (even) {
      final mid = (lngLo + lngHi) / 2;
      ch = ch * 2 + (lng >= mid ? 1 : 0);
      if (lng >= mid) {
        lngLo = mid;
      } else {
        lngHi = mid;
      }
    } else {
      final mid = (latLo + latHi) / 2;
      ch = ch * 2 + (lat >= mid ? 1 : 0);
      if (lat >= mid) {
        latLo = mid;
      } else {
        latHi = mid;
      }
    }
    even = !even;
    if (++bits == 5) {
      out.write(_base32[ch]);
      bits = 0;
      ch = 0;
    }
  }
  return out.toString();
}

({double minLat, double maxLat, double minLng, double maxLng}) geohashBounds(String hash) {
  var latLo = -90.0, latHi = 90.0, lngLo = -180.0, lngHi = 180.0;
  var even = true;
  for (final c in hash.split('')) {
    final v = _base32.indexOf(c);
    for (var bit = 4; bit >= 0; bit--) {
      final on = (v >> bit) & 1 == 1;
      if (even) {
        final mid = (lngLo + lngHi) / 2;
        if (on) {
          lngLo = mid;
        } else {
          lngHi = mid;
        }
      } else {
        final mid = (latLo + latHi) / 2;
        if (on) {
          latLo = mid;
        } else {
          latHi = mid;
        }
      }
      even = !even;
    }
  }
  return (minLat: latLo, maxLat: latHi, minLng: lngLo, maxLng: lngHi);
}

List<String> geohashNeighbors(String hash) {
  final b = geohashBounds(hash);
  final h = b.maxLat - b.minLat, w = b.maxLng - b.minLng;
  final cLat = (b.minLat + b.maxLat) / 2, cLng = (b.minLng + b.maxLng) / 2;
  final out = <String>[];
  for (final dLat in [-1, 0, 1]) {
    for (final dLng in [-1, 0, 1]) {
      if (dLat == 0 && dLng == 0) continue;
      final lat = cLat + dLat * h;
      if (lat < -90 || lat > 90) continue; // nothing beyond the poles
      final lng = ((cLng + dLng * w + 180) % 360 + 360) % 360 - 180; // wrap at the antimeridian
      out.add(geohashEncode(lat, lng, hash.length));
    }
  }
  return out;
}

/// Longest precision whose cell is at least [radiusKm] tall and wide at this latitude.
int precisionForRadius(double radiusKm, double lat) {
  for (var p = 9; p >= 1; p--) {
    final b = geohashBounds(geohashEncode(lat, 0, p));
    final heightKm = (b.maxLat - b.minLat) * _kmPerDegLat;
    final widthKm = (b.maxLng - b.minLng) * _kmPerDegLat * cos(lat * pi / 180);
    if (heightKm >= radiusKm && widthKm >= radiusKm) return p;
  }
  return 1;
}

// ---------- Businesses and indexes ----------

class Business {
  Business(this.id, this.lat, this.lng, this.category);
  final String id;
  double lat;
  double lng;
  final String category;
}

List<String> _finish(
  Iterable<Business> candidates,
  double lat,
  double lng,
  double radiusKm,
  String? category,
  int limit,
) {
  final hits = [
    for (final b in candidates)
      if ((category == null || b.category == category) && haversineKm(lat, lng, b.lat, b.lng) <= radiusKm)
        (b.id, haversineKm(lat, lng, b.lat, b.lng)),
  ]..sort((x, y) => x.$2 != y.$2 ? x.$2.compareTo(y.$2) : x.$1.compareTo(y.$1));
  return [for (final h in hits.take(limit)) h.$1];
}

class GeohashIndex {
  static const storedPrecision = 9;
  final _byHash = SplayTreeMap<String, Set<String>>();
  final businesses = <String, Business>{};
  final _hashOf = <String, String>{};

  void add(Business b) {
    final h = geohashEncode(b.lat, b.lng, storedPrecision);
    businesses[b.id] = b;
    _hashOf[b.id] = h;
    _byHash.putIfAbsent(h, () => {}).add(b.id);
  }

  void remove(String id) {
    final h = _hashOf.remove(id);
    businesses.remove(id);
    if (h == null) return;
    final set = _byHash[h]!..remove(id);
    if (set.isEmpty) _byHash.remove(h);
  }

  void move(String id, double lat, double lng) {
    final b = businesses[id]!;
    remove(id);
    add(
      b
        ..lat = lat
        ..lng = lng,
    );
  }

  /// All IDs whose geohash starts with [prefix]: an ordered range scan.
  Iterable<String> _prefixScan(String prefix) sync* {
    var key = _byHash.containsKey(prefix) ? prefix : _byHash.firstKeyAfter(prefix);
    while (key != null && key.startsWith(prefix)) {
      yield* _byHash[key]!;
      key = _byHash.firstKeyAfter(key);
    }
  }

  var cellsScanned = 0;

  List<String> nearby(double lat, double lng, double radiusKm, {String? category, int limit = 20}) {
    final p = precisionForRadius(radiusKm, lat);
    final center = geohashEncode(lat, lng, p);
    final cells = {center, ...geohashNeighbors(center)};
    cellsScanned = cells.length;
    final candidates = {for (final c in cells) ..._prefixScan(c)};
    return _finish(candidates.map((id) => businesses[id]!), lat, lng, radiusKm, category, limit);
  }
}

class QuadTree {
  QuadTree(this.minLat, this.minLng, this.maxLat, this.maxLng, {this.capacity = 8, this.depth = 0});

  final double minLat, minLng, maxLat, maxLng;
  final int capacity;
  final int depth;
  final points = <Business>[];
  List<QuadTree>? children;

  bool _contains(double lat, double lng) => lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;

  bool insert(Business b) {
    if (!_contains(b.lat, b.lng)) return false;
    if (children == null) {
      if (points.length < capacity || depth >= 24) {
        points.add(b);
        return true;
      }
      _split();
    }
    return children!.any((c) => c.insert(b));
  }

  void _split() {
    final midLat = (minLat + maxLat) / 2, midLng = (minLng + maxLng) / 2;
    QuadTree q(double a, double b, double c, double d) => QuadTree(a, b, c, d, capacity: capacity, depth: depth + 1);
    children = [
      q(minLat, minLng, midLat, midLng),
      q(minLat, midLng, midLat, maxLng),
      q(midLat, minLng, maxLat, midLng),
      q(midLat, midLng, maxLat, maxLng),
    ];
    for (final p in points) {
      children!.any((c) => c.insert(p));
    }
    points.clear();
  }

  void queryRect(double aLat, double aLng, double bLat, double bLng, List<Business> out) {
    if (bLat < minLat || aLat > maxLat || bLng < minLng || aLng > maxLng) return; // no overlap
    out.addAll(points.where((p) => p.lat >= aLat && p.lat <= bLat && p.lng >= aLng && p.lng <= bLng));
    for (final c in children ?? const <QuadTree>[]) {
      c.queryRect(aLat, aLng, bLat, bLng, out);
    }
  }

  int get leaves => children == null ? 1 : children!.fold(0, (s, c) => s + c.leaves);

  /// Bounding box of the circle, then the exact filter. (No antimeridian wrap in this simple version.)
  List<String> nearby(double lat, double lng, double radiusKm, {String? category, int limit = 20}) {
    final dLat = radiusKm / _kmPerDegLat, dLng = radiusKm / (_kmPerDegLat * cos(lat * pi / 180));
    final out = <Business>[];
    queryRect(lat - dLat, lng - dLng, lat + dLat, lng + dLng, out);
    return _finish(out, lat, lng, radiusKm, category, limit);
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void main() {
  // Geohash basics.
  check(geohashEncode(57.64911, 10.40744, 11), 'u4pruydqqvj'); // the classic reference value
  final box = geohashBounds('u4pruydqqvj');
  check(box.minLat <= 57.64911 && 57.64911 <= box.maxLat && box.minLng <= 10.40744 && 10.40744 <= box.maxLng, true);
  check(geohashNeighbors('gbsuv')..sort(), ['gbsus', 'gbsut', 'gbsuu', 'gbsuw', 'gbsuy', 'gbsvh', 'gbsvj', 'gbsvn']);
  check([precisionForRadius(0.5, 37.77), precisionForRadius(2, 37.77), precisionForRadius(10, 37.77)], [6, 5, 4]);

  // Random businesses in San Francisco; both indexes must match brute force on every query.
  final rng = Random(1);
  const categories = ['coffee', 'pizza', 'books'];
  final all = [
    for (var i = 0; i < 3000; i++)
      Business('b$i', 37.70 + rng.nextDouble() * 0.12, -122.52 + rng.nextDouble() * 0.16, categories[i % 3]),
  ];
  final geo = GeohashIndex();
  final tree = QuadTree(-90, -180, 90, 180);
  for (final b in all) {
    geo.add(b);
    tree.insert(b);
  }
  check(tree.leaves > 100, true); // the tree adapted to the dense area
  for (var q = 0; q < 200; q++) {
    final lat = 37.70 + rng.nextDouble() * 0.12, lng = -122.52 + rng.nextDouble() * 0.16;
    final radius = 0.3 + rng.nextDouble() * 4.7;
    final category = q.isEven ? null : categories[q % 3];
    final expected = _finish(all, lat, lng, radius, category, 25);
    final fromGeo = geo.nearby(lat, lng, radius, category: category, limit: 25);
    final fromTree = tree.nearby(lat, lng, radius, category: category, limit: 25);
    if ('$fromGeo' != '$expected' || '$fromTree' != '$expected') throw StateError('query $q differs');
  }
  print('ok: 200 random queries match brute force');
  check(geo.cellsScanned, 9);

  // Moving a business.
  final city = GeohashIndex()..add(Business('new-cafe', 37.7749, -122.4194, 'coffee'));
  check(city.nearby(37.7749, -122.4194, 0.05), ['new-cafe']);
  city.move('new-cafe', 37.8044, -122.2712); // across the bay
  check(
    [city.nearby(37.7749, -122.4194, 0.05), city.nearby(37.8044, -122.2712, 0.05)],
    <List<String>>[
      [],
      ['new-cafe'],
    ],
  );

  // Neighbors wrap across the antimeridian: a point 0.2 km away on the other side is found.
  final pacific = GeohashIndex()..add(Business('island', 0.0, -179.999, 'shop'));
  check(pacific.nearby(0.0, 179.999, 1), ['island']);
}
```

## 5. Walkthrough

- `u4pruydqqvj` is the standard published geohash for (57.64911, 10.40744); the bounding box contains the point.
- `gbsuv`'s eight neighbors are computed by stepping one cell height or width from its center and re-encoding.
- At latitude 37.77: a 0.5 km radius needs precision 6 (cells about 0.61 km tall and 0.97 km wide); 2 km needs precision 5; 10 km needs precision 4.
- 3,000 random businesses and 200 random queries (with and without a category filter): the geohash index and the quadtree return exactly the brute-force answer, sorted by distance. Each geohash query scans 9 cells.
- The quadtree has over 100 leaves, all around San Francisco, even though its root covers the whole world: it only splits where points are.
- Across the antimeridian, a business at longitude -179.999 is 0.22 km from a query at 179.999; the wrapped neighbor cell finds it.

## 6. Concurrency

- The read path is lock-free if the index is immutable: build a new index (or quadtree) in the background and swap the reference.
- With in-place updates, a read-write lock per index (updates are rare) or a concurrent sorted map for the geohash table.

## 7. Extensibility

| Change | Where |
|---|---|
| Expand when results are too few | Retry `nearby` with precision - 1 until `limit` is reached or a maximum radius. |
| Rank by rating and distance | Replace the sort in `_finish` with a scoring function. |
| Database-backed index | `_prefixScan` becomes `SELECT id FROM geo WHERE geohash >= ? AND geohash < ?`. |
| S2 / H3 cells | Same structure; the cell function and neighbor function change. |

## 8. Common mistakes in LLD rounds

- Searching only the center cell.
- Forgetting the longitude wrap and the shrinking width of cells away from the equator.
- Sorting all businesses by distance (O(n log n) per query).
- Quadtrees without a depth limit (identical points split forever).

See [HLD.md](HLD.md) for the service architecture, caching and scaling.
