# Design Twitter

**Difficulty:** Medium | **Category:** Heap / Design | **Pattern:** Per-user timelines + k-way merge with a heap | **Source:** LeetCode 355; NeetCode 150

## The problem

Implement a simplified Twitter:

- `postTweet(userId, tweetId)`
- `getNewsFeed(userId)`: the 10 most recent tweet ids posted by the user or anyone they follow, most recent first.
- `follow(followerId, followeeId)`, `unfollow(followerId, followeeId)`.

## Step 1: Data model

- A global **clock** that increases on every post, so "most recent" is a number comparison.
- For each user, their tweets in posting order: a list of `(time, tweetId)`. Appending keeps it sorted by time.
- For each user, the set of users they follow.

`postTweet`, `follow`, `unfollow` are O(1).

## Step 2: The feed is a k-way merge

The feed merges several sorted lists (the user's and each followee's timelines) and takes the first 10 in **descending** time. That is Merge k Sorted Lists (neetcode 11), stopped after 10 items:

1. Push the **newest** tweet of each source into a max-heap (by time), remembering which user and index it came from.
2. Pop the newest overall; add its tweet to the feed; push that user's **next older** tweet.
3. Stop after 10 tweets or when the heap is empty.

Only `F + 10` heap operations happen (F = number of sources), no matter how many tweets each user has.

## Step 3: Simpler alternative

Collect every tweet of every source, sort by time, take 10: O(T log T) for T total tweets. Fine for small data; the heap merge is the scalable answer and the one interviewers look for.

## Step 4: The code

<!-- CODE:START -->

Full source: [`design_twitter.dart`](design_twitter.dart) (run it with `dart run`).

```dart
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
```

<!-- CODE:END -->

### Walkthrough

- `_time++` gives each tweet a unique, increasing timestamp.
- `sources = {userId, ...?_following[userId]}`: the user always sees their own tweets; `...?` spreads a possibly-null set.
- Heap entries are records `(time, tweetId, user, index)`; the comparator orders by time descending.
- `follow` ignores following yourself (the user is always included anyway).

## Step 5: Dry run

User 1 posts 5 (time 0). User 1 follows 2. User 2 posts 6 (time 1). `getNewsFeed(1)`:

| step | heap | pop | feed |
|---|---|---|---|
| init | (1, 6, user 2), (0, 5, user 1) | | |
| 1 | | tweet 6 | [6] |
| 2 | | tweet 5 | [6, 5] |

After `unfollow(1, 2)`, the feed is `[5]`.

## Complexity

- `postTweet`, `follow`, `unfollow`: **O(1)**.
- `getNewsFeed`: **O(F + 10 log F)** time, O(F) space.

## Edge cases

- User with no tweets and no followees: `[]`.
- Unfollowing someone not followed: no-op.
- Following yourself: ignored.

## Common mistakes

- Merging all tweets of all followees every time (O(T log T)).
- Forgetting the user's own tweets.
- Using list positions as timestamps (they are per user, not global).

## Follow-ups you should be ready for

1. **Scale (the system design version).** Fan-out on write (push tweets into followers' precomputed feeds) versus fan-out on read (this merge), and the hybrid used for celebrity accounts.
2. **Pagination.** Return a cursor (the last time seen) and resume the merge from there.
3. **Memory.** Keep only the most recent N tweets per user if feeds never look further back.

## What to remember

A feed is a k-way merge of sorted per-user timelines: a heap of each source's newest item, stopping after the first 10.
