# One Edit

**Difficulty:** Medium | **Category:** Strings | **Pattern:** Two pointers with a single allowed mismatch

## The problem

Return whether two strings are **at most one edit** apart, where an edit is inserting one character, deleting one character, or replacing one character. Equal strings are zero edits apart, so they return true.

```
"hello", "hollo"  ->  true    (replace)
"hello", "helo"   ->  true    (delete)
"a", "ab"         ->  true    (insert at the end)
"abc", "cba"      ->  false
"ab", "abcd"      ->  false   (length differs by 2)
```

## Step 1: The general tool is too heavy

Levenshtein distance (medium 31) answers the question in O(n * m) time. But we only need to know whether the distance is 0 or 1, and that has a linear-time answer.

## Step 2: Case analysis by length

- Lengths differ by **more than 1**: impossible, false.
- **Equal lengths:** only a replacement can help, so there must be at most one position where they differ.
- Lengths differ by **exactly 1**: only an insertion/deletion can help. Walk both strings; at the first mismatch, skip one character in the **longer** string, then the rest must match exactly.

## Step 3: One loop for both cases

Let `a` be the longer (or equal-length) string and `b` the other. Walk with pointers `i` (in `a`) and `j` (in `b`):

- Characters match: advance both.
- Mismatch:
  - if this is the second mismatch: false;
  - equal lengths: treat it as a replacement: advance both;
  - otherwise: treat it as a deletion from `a`: advance only `i`.

If the loop ends, the answer is true. A trailing extra character in the longer string (like `"ab"` vs `"a"`) never causes a mismatch inside the loop, which is correct: it is the one allowed insertion.

## Step 4: The code

<!-- CODE:START -->

Full source: [`one_edit.dart`](one_edit.dart) (run it with `dart run`).

```dart
// One Edit: are two strings at most one insert/delete/replace apart?
// Walk both with two pointers; on the first mismatch, skip according to the length difference.
// O(n) time, O(1) space.

bool oneEdit(String stringOne, String stringTwo) {
  final (a, b) = stringOne.length >= stringTwo.length ? (stringOne, stringTwo) : (stringTwo, stringOne);
  if (a.length - b.length > 1) return false;
  var i = 0, j = 0;
  var edited = false;
  while (i < a.length && j < b.length) {
    if (a[i] != b[j]) {
      if (edited) return false;
      edited = true;
      if (a.length == b.length) j++; // replace: advance both; otherwise delete from longer
    } else {
      j++;
    }
    i++;
  }
  return true;
}
```

<!-- CODE:END -->

### Walkthrough

- `final (a, b) = ...` puts the longer string first.
- `if (a.length - b.length > 1) return false;`
- `edited` records whether the single allowed edit has been used.
- On a mismatch with equal lengths, `j++` together with the `i++` at the end of the loop body advances both (replacement). With different lengths, only `i` advances (skip a character of the longer string).

## Step 5: Dry run: "hello" vs "helo"

`a = "hello"`, `b = "helo"`:

| i | j | a[i] | b[j] | action |
|---|---|---|---|---|
| 0 | 0 | h | h | match, advance both |
| 1 | 1 | e | e | match |
| 2 | 2 | l | l | match |
| 3 | 3 | l | o | mismatch #1: lengths differ, advance i only |
| 4 | 3 | o | o | match |

Loop ends: true.

## Complexity

- **Time: O(n)**.
- **Space: O(1)**.

## Common mistakes

- Treating a length difference of 1 like a replacement (advancing both pointers).
- Forgetting that equal strings are allowed here.
- Advancing the pointer of the shorter string on a length mismatch.

## Follow-ups

1. **One Edit Distance (LeetCode #161):** requires **exactly** one edit, so equal strings return false.
2. **Cracking the Coding Interview 1.5 ("One Away"):** identical to this problem.
3. **At most k edits:** use the banded Levenshtein DP (only cells within k of the diagonal): O(n * k).

## What to remember

When only a tiny number of differences is allowed, do a single linear walk and count mismatches, choosing how to skip based on the length difference.
