# Valid IP Addresses

**Difficulty:** Medium | **Category:** Strings | **Pattern:** Bounded enumeration with validation

## The problem

Given a string of digits, return every valid **IPv4 address** that can be formed by inserting exactly three dots. An IPv4 address has four parts; each part is an integer from 0 to 255 **without leading zeros** (`"0"` is fine; `"00"`, `"01"`, `"010"` are not).

```
"1921680"  ->  ["1.9.216.80", "1.92.16.80", "1.92.168.0", "19.2.16.80", "19.2.168.0",
                "19.21.6.80", "19.21.68.0", "19.216.8.0", "192.1.6.80", "192.1.68.0", "192.16.8.0"]
"0000"     ->  ["0.0.0.0"]
```

## Step 1: How many candidates are there?

Each part has 1 to 3 digits. Choosing the lengths of the first three parts fixes the fourth. So there are at most `3 * 3 * 3 = 27` ways to place the dots, **regardless of the input length**. That is the key insight for the complexity: the answer is O(1).

Also, any valid address has between 4 and 12 digits, so longer inputs have no answers.

## Step 2: The algorithm

Three nested loops choose where the three dots go (after 1, 2, or 3 digits each). For each split, validate all four parts. Validate each part as soon as it is chosen, so invalid prefixes are skipped early (pruning).

**Part validation:**

1. length between 1 and 3;
2. no leading zero unless the part is exactly `"0"`;
3. numeric value <= 255.

## Step 3: The code

<!-- CODE:START -->

Full source: [`valid_ip_addresses.dart`](valid_ip_addresses.dart) (run it with `dart run`).

```dart
// Valid IP Addresses: insert three dots into a digit string to make valid IPv4 addresses.
// Each part is 0..255 with no leading zeros. At most 3 * 3 * 3 splits: O(1) time and space
// (input length is at most 12 for any valid answer).

List<String> validIPAddresses(String string) {
  bool valid(String part) {
    if (part.isEmpty || part.length > 3) return false;
    if (part.length > 1 && part.startsWith('0')) return false;
    return int.parse(part) <= 255;
  }

  final result = <String>[];
  final n = string.length;
  for (var i = 1; i < 4 && i < n; i++) {
    final a = string.substring(0, i);
    if (!valid(a)) continue;
    for (var j = i + 1; j < i + 4 && j < n; j++) {
      final b = string.substring(i, j);
      if (!valid(b)) continue;
      for (var k = j + 1; k < j + 4 && k < n; k++) {
        final c = string.substring(j, k), d = string.substring(k);
        if (valid(c) && valid(d)) result.add('$a.$b.$c.$d');
      }
    }
  }
  return result;
}
```

<!-- CODE:END -->

### Walkthrough

- `valid(part)` implements the three rules. The length check comes first, which also guarantees `int.parse` never sees a huge number.
- `i`, `j`, `k` are the positions of the three dots. Each loop limits the part to at most 3 digits (`< i + 4`) and leaves at least one digit for the next part (`< n`).
- `continue` skips a whole subtree of splits when a prefix part is invalid.
- `d = string.substring(k)` is the fourth part.

## Step 4: Dry run (a few splits of "1921680")

| a | b | c | d | valid? |
|---|---|---|---|---|
| 1 | 9 | 2 | 1680 | no (d has 4 digits) |
| 1 | 9 | 216 | 80 | **yes** |
| 1 | 92 | 168 | 0 | **yes** |
| 19 | 216 | 8 | 0 | **yes** |
| 1921 | | | | never tried (a is at most 3 digits) |

## Complexity

- **Time: O(1)**: at most 27 splits, each validated in constant time (parts have at most 3 digits).
- **Space: O(1)**: at most 27 results.

Interviewers often check whether you can explain why this is O(1) and not O(n^3). Say: "bounded by 3^3 splits because each part is at most 3 digits".

## Common mistakes

- Accepting leading zeros (`"01"`).
- Accepting `"256"`.
- Allowing empty parts.

## Follow-ups

1. **Restore IP Addresses (LeetCode #93):** identical.
2. **k parts instead of 4:** use backtracking with a `parts` list; prune when the remaining digits cannot fill the remaining parts (fewer than 1 each or more than 3 each).
3. **Validate IP Address (#468):** validate a given IPv4 or IPv6 string.

## What to remember

When each piece has a small fixed maximum size, enumeration is bounded by a constant. Validate each piece as early as possible to prune.
