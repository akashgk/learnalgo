// Design Twitter: postTweet, getNewsFeed (10 most recent tweets from the user and followees),
// follow, unfollow. Each user keeps their own tweets in time order; the feed is a k-way merge of
// those lists with a max-heap, stopping after 10. getNewsFeed: O(F + 10 log F) for F followees.

class Twitter {
  var _time = 0; // global clock: larger means more recent
  final _tweets = <int, List<(int, int)>>{}; // user -> [(time, tweetId)] in increasing time
  final _following = <int, Set<int>>{}; // user -> followees

  void postTweet(int userId, int tweetId) {
    _tweets.putIfAbsent(userId, () => []).add((_time++, tweetId));
  }

  List<int> getNewsFeed(int userId) {
    final sources = {userId, ...?_following[userId]};
    // Heap entries: (time, tweetId, user, index in that user's list). Most recent on top.
    final heap = _MinHeap<(int, int, int, int)>((a, b) => b.$1.compareTo(a.$1));
    for (final u in sources) {
      final list = _tweets[u];
      if (list != null && list.isNotEmpty) {
        final i = list.length - 1; // each user's most recent tweet
        heap.push((list[i].$1, list[i].$2, u, i));
      }
    }
    final feed = <int>[];
    while (heap.length > 0 && feed.length < 10) {
      final (_, tweetId, u, i) = heap.pop();
      feed.add(tweetId);
      if (i > 0) {
        final prev = _tweets[u]![i - 1]; // that user's next most recent tweet
        heap.push((prev.$1, prev.$2, u, i - 1));
      }
    }
    return feed;
  }

  void follow(int followerId, int followeeId) {
    if (followerId != followeeId) _following.putIfAbsent(followerId, () => {}).add(followeeId);
  }

  void unfollow(int followerId, int followeeId) {
    _following[followerId]?.remove(followeeId);
  }
}

class _MinHeap<T> {
  _MinHeap(this._compare);
  final int Function(T, T) _compare;
  final _items = <T>[];

  int get length => _items.length;

  void push(T item) {
    _items.add(item);
    var i = _items.length - 1;
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (_compare(_items[parent], _items[i]) <= 0) break;
      _swap(i, parent);
      i = parent;
    }
  }

  T pop() {
    final top = _items.first;
    final last = _items.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = last;
      var i = 0;
      while (true) {
        final l = 2 * i + 1, r = l + 1;
        var m = i;
        if (l < _items.length && _compare(_items[l], _items[m]) < 0) m = l;
        if (r < _items.length && _compare(_items[r], _items[m]) < 0) m = r;
        if (m == i) break;
        _swap(i, m);
        i = m;
      }
    }
    return top;
  }

  void _swap(int i, int j) {
    final t = _items[i];
    _items[i] = _items[j];
    _items[j] = t;
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final t = Twitter();
  t.postTweet(1, 5);
  check(t.getNewsFeed(1), [5]);
  t.follow(1, 2);
  t.postTweet(2, 6);
  check(t.getNewsFeed(1), [6, 5]); // most recent first
  t.unfollow(1, 2);
  check(t.getNewsFeed(1), [5]);
  // Only the 10 most recent.
  final u = Twitter();
  for (var i = 1; i <= 12; i++) {
    u.postTweet(i.isEven ? 1 : 2, i);
  }
  u.follow(1, 2);
  check(u.getNewsFeed(1), [12, 11, 10, 9, 8, 7, 6, 5, 4, 3]);
  u.follow(1, 1); // following yourself is ignored
  check(u.getNewsFeed(3), []);
}
