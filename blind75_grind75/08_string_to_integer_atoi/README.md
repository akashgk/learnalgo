# String to Integer (atoi)

**Difficulty:** Medium | **Category:** Strings | **Pattern:** Careful parsing state machine with overflow clamping | **Source:** LeetCode 8; Grind 75

## The problem

Implement C's `atoi`:

1. Skip leading spaces.
2. Read an optional `+` or `-`.
3. Read digits until the first non-digit (ignore everything after it).
4. No digits read: return 0.
5. Clamp to the 32-bit range: below `-2^31` returns `-2^31`, above `2^31 - 1` returns `2^31 - 1`.

```
"42"              ->  42
"   -042"         ->  -42
"1337c0d3"        ->  1337
"words and 987"   ->  0
"-91283472332"    ->  -2147483648
```

This problem is about **precision in following a spec**, not about a clever algorithm. Interviewers watch whether you handle every rule.

## Step 1: List the cases before coding

| Input feature | Rule |
|---|---|
| Leading spaces | skip (only spaces, not other whitespace) |
| `+` or `-` | at most one, only right after the spaces |
| Leading zeros | allowed (`"0042"` is 42) |
| First non-digit | stop |
| Overflow | clamp, do not wrap |

## Step 2: Overflow without a bigger type

Accumulate the **magnitude** as a non-negative number. Before `result = result * 10 + d`, check whether it would exceed `2^31 - 1`:

```
result * 10 + d > MAX   <=>   result > (MAX - d) / 10   (integer division)
```

If so, the true value is out of range: return `MAX` for a positive sign and `MIN` for a negative one. For negatives, the magnitude limit is really `2^31`, one more than `MAX`; but any magnitude above `MAX` clamps to `MIN` for a negative sign anyway (`-2^31` is exactly `MIN`), so one check covers both signs.

## Step 3: The code

<!-- CODE:START -->

Full source: [`string_to_integer_atoi.dart`](string_to_integer_atoi.dart) (run it with `dart run`).

```dart
// String to Integer (atoi): skip leading spaces, read an optional sign, read digits until the first
// non-digit, and clamp to the 32-bit range [-2^31, 2^31 - 1]. No digits read means 0.
// Overflow is checked before each multiply-by-10, as in 32-bit arithmetic. O(n) time.

const _max = 2147483647, _min = -2147483648;

int myAtoi(String s) {
  var i = 0;
  while (i < s.length && s[i] == ' ') {
    i++;
  }
  var sign = 1;
  if (i < s.length && (s[i] == '+' || s[i] == '-')) {
    if (s[i] == '-') sign = -1;
    i++;
  }
  var result = 0; // accumulated as a non-negative magnitude
  while (i < s.length) {
    final d = s.codeUnitAt(i) - 48;
    if (d < 0 || d > 9) break; // first non-digit ends the number
    // result * 10 + d > 2^31 - 1 ?  (for negatives the limit is 2^31, handled by the clamp)
    if (result > (_max - d) ~/ 10) return sign == 1 ? _max : _min;
    result = result * 10 + d;
    i++;
  }
  return sign * result;
}
```

<!-- CODE:END -->

### Walkthrough

- Three phases, each a simple loop or check: spaces, sign, digits.
- `d < 0 || d > 9` detects a non-digit from the code unit.
- The overflow check runs before every update.

## Step 4: Dry run

`"   -042"`:

| phase | position | state |
|---|---|---|
| spaces | 0..2 | skipped |
| sign | 3 `-` | sign = -1 |
| digit `0` | 4 | result 0 |
| digit `4` | 5 | result 4 |
| digit `2` | 6 | result 42 |
| end | | return **-42** |

`"2147483648"`: after 9 digits, `result = 214748364`; the last digit 8 gives `(2147483647 - 8) ~/ 10 = 214748363 < 214748364`: overflow, return **2147483647**.

## Complexity

- Time: **O(n)**.
- Space: **O(1)**.

## Edge cases

- Empty string, only spaces, only a sign: 0.
- `"+-12"`: the second sign is a non-digit: 0.
- `"-2147483648"`: exactly MIN (clamping gives the right value).

## Common mistakes

- Skipping spaces anywhere, not just at the start (`"4 2"` is 4).
- Accepting multiple signs.
- Checking overflow after multiplying (too late in 32-bit languages).
- Using a library parse that throws on trailing letters.

## Follow-ups you should be ready for

1. **Valid Number (LeetCode 65).** A full state machine for decimals and exponents.
2. **Reverse Integer.** The same overflow check; neetcode 60.
3. **Write it as a finite state machine.** States: start, signed, in-number, end. Some interviewers ask for this formulation.

## What to remember

Spec-following problems are won by listing every rule first. For overflow, check `result > (MAX - d) / 10` before pushing a digit.
