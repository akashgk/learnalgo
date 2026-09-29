# Set Matrix Zeroes

**Difficulty:** Medium | **Category:** Arrays (matrix) | **Pattern:** In-place marker storage | **Source:** LeetCode 73; Striver A2Z

## The problem

Given an `m x n` integer matrix, if a cell is 0, set its **entire row and column** to 0. Do it in place. The target is O(1) extra space.

```
1 1 1        1 0 1
1 0 1   ->   0 0 0
1 1 1        1 0 1
```

### Clarifying questions to ask

| Question | Why it matters |
|---|---|
| Only original zeros spread, right? | Yes. Zeros you write must not spread further. This is the trap. |
| Space target? | O(m + n) is easy; O(1) is the real question. |

## Step 1: Work an example by hand

The naive in-place approach: scan, and when you see a 0, zero its row and column immediately. On the example, the 0 at (1,1) zeros row 1 and column 1. Continuing the scan, you reach (1,2), which is now 0, and zero column 2 as well. Wrong: that zero was **written by us**, not original.

So we need to **first record** which rows and columns contain an original zero, **then** write.

## Step 2: Brute force with extra space

Two boolean arrays: `zeroRow[m]` and `zeroCol[n]`. Pass 1 fills them. Pass 2 sets `m[r][c] = 0` if `zeroRow[r] || zeroCol[c]`. O(mn) time, **O(m + n)** space. This is a perfectly good first answer. Say it, then improve.

## Step 3: Optimize to O(1) space

**Where can we store `m + n` booleans for free?** In the matrix itself. Use the **first row** as `zeroCol` and the **first column** as `zeroRow`: when `m[r][c] == 0`, set `m[r][0] = 0` and `m[0][c] = 0`.

Is it safe to overwrite those cells? A marker cell `m[0][c]` is set to 0 only when column `c` contains a zero, in which case `m[0][c]` would become 0 in the final answer anyway. Same for `m[r][0]`. So the markers never destroy information we need **for the inner cells**.

**The one conflict:** the first row and first column are themselves part of the matrix. After marking, `m[0][0] = 0` could mean "row 0 has a zero" or "column 0 has a zero", and `m[0][c] = 0` no longer tells us whether row 0 **originally** had a zero. Fix: before marking, record two booleans, `firstRowZero` and `firstColZero`. That is O(1) extra space.

Order of operations matters:

1. Record `firstRowZero` and `firstColZero`.
2. Mark using inner cells only (`r >= 1`, `c >= 1`).
3. Fill inner cells from the markers.
4. Zero the first row and first column last, if their flags say so. (Doing this earlier would wipe the markers.)

## Step 4: The code

<!-- CODE:START -->

Full source: [`set_matrix_zeroes.dart`](set_matrix_zeroes.dart) (run it with `dart run`).

```dart
// Set Matrix Zeroes: if a cell is 0, set its whole row and column to 0, in place.
// Use the first row and first column as marker storage. O(m*n) time, O(1) extra space.

void setZeroes(List<List<int>> m) {
  final rows = m.length, cols = m[0].length;
  // The first row and column are about to be overwritten with markers,
  // so remember separately whether they themselves must become zero.
  var firstRowZero = false, firstColZero = false;
  for (var c = 0; c < cols; c++) {
    if (m[0][c] == 0) firstRowZero = true;
  }
  for (var r = 0; r < rows; r++) {
    if (m[r][0] == 0) firstColZero = true;
  }
  // Mark: a zero at (r, c) sets m[r][0] and m[0][c] to 0.
  for (var r = 1; r < rows; r++) {
    for (var c = 1; c < cols; c++) {
      if (m[r][c] == 0) {
        m[r][0] = 0;
        m[0][c] = 0;
      }
    }
  }
  // Fill the inner cells from the markers.
  for (var r = 1; r < rows; r++) {
    for (var c = 1; c < cols; c++) {
      if (m[r][0] == 0 || m[0][c] == 0) m[r][c] = 0;
    }
  }
  // Finally the marker row and column themselves.
  if (firstRowZero) {
    for (var c = 0; c < cols; c++) {
      m[0][c] = 0;
    }
  }
  if (firstColZero) {
    for (var r = 0; r < rows; r++) {
      m[r][0] = 0;
    }
  }
}
```

<!-- CODE:END -->

### Walkthrough

- The first two loops only **read**; nothing is modified until both flags are known.
- The marking loop starts at 1 in both dimensions; zeros in row 0 or column 0 are already covered by the flags.
- The fill loop also starts at 1: it must not overwrite markers that later inner cells still read. (It only reads row 0 and column 0 and writes inner cells, so this is safe in any order.)
- The first row and column are handled last.

## Step 5: Dry run

`[[0,1,2,0],[3,4,5,2],[1,3,1,5]]`:

| Step | Matrix | Note |
|---|---|---|
| flags | unchanged | `firstRowZero = true` (row 0 has zeros), `firstColZero = true` (m[0][0] = 0) |
| mark | unchanged | no zeros in inner cells |
| fill inner | `[[0,1,2,0],[3,4,5,0],[1,3,1,0]]` | inner (r, c) is zeroed when m[r][0] = 0 or m[0][c] = 0; only m[0][3] is 0, so column 3's inner cells become 0 |
| first row | `[0,0,0,0]` | `firstRowZero` |
| first col | column 0 all 0 | `firstColZero` |

Final: `[[0,0,0,0],[0,4,5,0],[0,3,1,0]]`.

## Complexity

- Time: **O(mn)**. A constant number of passes.
- Space: **O(1)** extra (two booleans).

## Edge cases

- Single row or single column: the inner loops do nothing; the flags do all the work.
- Zero only at `m[0][0]`: both flags true, first row and column zeroed, nothing else.
- No zeros: nothing changes.

## Common mistakes

- Zeroing immediately during the scan (spreads written zeros).
- Using only `m[0][0]` as the flag for both row 0 and column 0: it cannot hold two independent bits. You need at least one extra variable.
- Zeroing the first row or column before filling the inner cells, which destroys the markers.

## Follow-ups you should be ready for

1. **Game of Life (LeetCode 289)** uses the same "encode extra state in the matrix" trick: store the next state in a spare bit.
2. **What if the matrix is huge and sparse?** Store only the coordinates of zeros (sets of rows and columns).
3. **Streaming rows.** You cannot know future zeros in a column, so you need at least O(n) memory for column flags.

## What to remember

When extra space is not allowed, look for storage inside the input that you are going to overwrite anyway. Then protect the one piece of information that the reuse destroys (here, the first row and column's own state).
