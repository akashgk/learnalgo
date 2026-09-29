# Semordnilap

**Difficulty:** Easy | **Category:** Strings | **Pattern:** Hash set lookup

## The problem

Given a list of unique strings, return all pairs of **different** words that are reverses of each other ("semordnilap" is "palindromes" spelled backward). Each pair appears once, in any order.

```
["diaper", "abc", "test", "cba", "repaid"]  ->  [["diaper", "repaid"], ["abc", "cba"]]
["aaa", "bbb"]                              ->  []   (palindromes do not pair with themselves)
```

## Step 1: Work an example by hand

Take `"diaper"`. The only word it can pair with is its reverse, `"repaid"`. Is `"repaid"` in the list? Yes: pair found. Take `"abc"`: its reverse `"cba"` is in the list: pair. `"test"` reversed is `"tset"`: not in the list.

For each word, there is exactly **one** candidate partner, and you just need to know whether it exists. Existence checks are hash set lookups.

## Step 2: Brute force

Compare every pair of words, reversing one: O(n^2 * m) where m is the word length.

## Step 3: Optimize

1. Put all words in a hash set.
2. For each word, compute its reverse and look it up: O(m) to reverse and hash.
3. Avoid reporting a pair twice: when you find `(diaper, repaid)`, you will later reach `repaid` and find `diaper`. Remove both words from the set when a pair is recorded.
4. Skip palindromes: `"aaa"` reversed is itself, and a word may not pair with itself.

## Step 4: The code

<!-- CODE:START -->

Full source: [`semordnilap.dart`](semordnilap.dart) (run it with `dart run`).

```dart
// Semordnilap: pairs of distinct words where one is the reverse of the other.
// Hash set lookups; remove matched words so each pair is reported once. O(n * m) time, O(n * m) space.

List<List<String>> semordnilap(List<String> words) {
  final remaining = words.toSet();
  final pairs = <List<String>>[];
  for (final word in words) {
    final reversed = word.split('').reversed.join();
    if (reversed != word && remaining.contains(word) && remaining.contains(reversed)) {
      pairs.add([word, reversed]);
      remaining
        ..remove(word)
        ..remove(reversed);
    }
  }
  return pairs;
}
```

<!-- CODE:END -->

### Walkthrough

- `final remaining = words.toSet();` holds words that are still unpaired.
- `word.split('').reversed.join()` reverses the word.
- The condition checks: not a palindrome, the word is still unpaired, and its reverse is still unpaired.
- `remaining..remove(word)..remove(reversed)` removes both so the pair is not reported again.

## Step 5: Dry run

`["diaper", "abc", "test", "cba", "repaid"]`:

| word | reverse | in remaining? | pairs | remaining after |
|---|---|---|---|---|
| diaper | repaid | yes | [diaper, repaid] | {abc, test, cba} |
| abc | cba | yes | + [abc, cba] | {test} |
| test | tset | no | | {test} |
| cba | abc | word not in remaining | | {test} |
| repaid | diaper | word not in remaining | | {test} |

## Complexity

- **Time: O(n * m)**: n words, each reversed and hashed in O(m).
- **Space: O(n * m)** for the set and the output.

## Common mistakes

- Reporting each pair twice.
- Pairing a palindrome with itself.
- Using a list for lookups (`list.contains` is O(n), making the whole thing O(n^2 * m)).

## Follow-ups

1. **Palindrome Pairs (LeetCode #336, hard):** find pairs whose **concatenation** is a palindrome. For each word, split it at every position; if one part is a palindrome, look up the reverse of the other part. A trie makes it faster.
2. **Case-insensitive matching:** normalize to lowercase before inserting and looking up.

## What to remember

When each item has exactly one possible partner, compute the partner and look it up in a hash set. Remove matched items to avoid double counting.
