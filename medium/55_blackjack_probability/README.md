# Blackjack Probability

**Difficulty:** Medium | **Category:** Recursion | **Pattern:** Probability DP with memoization

## The problem

A dealer draws cards with values 1 to 10, each equally likely (the deck is infinite). The dealer **must keep drawing** while their hand total is below `target - 4`, and **stops** as soon as it is at least `target - 4`. The dealer **busts** if the total exceeds `target`. Given `target` and the dealer's starting hand, return the probability that the dealer busts, rounded to 3 decimal places.

```
target = 21, startingHand = 15  ->  0.45
```

With target 21: the dealer draws while below 17 and busts above 21.

## Step 1: Work an example by hand

From 15, the next card is 1..10:

- 1 -> 16: still below 17, draw again (need to recurse).
- 2 -> 17, 3 -> 18, 4 -> 19, 5 -> 20, 6 -> 21: stop, no bust.
- 7..10 -> 22..25: bust.

So `P(15) = (P(16) + 0 + 0 + 0 + 0 + 0 + 1 + 1 + 1 + 1) / 10`. And `P(16)` = from 16: cards 1..5 give 17..21 (no bust), 6..10 give 22..26 (bust): `P(16) = 5/10 = 0.5`. So `P(15) = (0.5 + 4) / 10 = 0.45`.

## Step 2: The recursion

Let `P(h)` = probability of busting starting from total `h`:

```
P(h) = 1                                if h > target        (busted)
P(h) = 0                                if target - 4 <= h <= target   (dealer stands)
P(h) = (P(h+1) + P(h+2) + ... + P(h+10)) / 10   otherwise
```

## Step 3: Memoization

Many different card sequences reach the same total (2 then 3, or 3 then 2, or 5). The probability from a total does not depend on how you got there, so compute each `P(h)` once and cache it. There are only about `target` distinct totals.

## Step 4: The code

<!-- CODE:START -->

Full source: [`blackjack_probability.dart`](blackjack_probability.dart) (run it with `dart run`).

```dart
// Blackjack Probability: draw cards 1..10 uniformly (infinite deck). Stop once hand >= target - 4.
// Bust if hand > target. Return P(bust) rounded to 3 decimals.
// Memoized recursion over hand values. O(target) states * 10 = O(target) time and space.

double blackjackProbability(int target, int startingHand) {
  final memo = <int, double>{};

  double bust(int hand) {
    if (hand > target) return 1;
    if (hand >= target - 4) return 0;
    return memo[hand] ??= [for (var card = 1; card <= 10; card++) bust(hand + card)].reduce((a, b) => a + b) / 10;
  }

  return (bust(startingHand) * 1000).round() / 1000;
}
```

<!-- CODE:END -->

### Walkthrough

- `bust(hand)` implements the three cases.
- `memo[hand] ??= ...` caches the recursive case.
- The recursive case builds the list of the 10 outcomes, sums them, and divides by 10.
- Rounding happens **once**, at the end: `(p * 1000).round() / 1000`. Rounding intermediate values would accumulate error.

## Complexity

- **Time: O(target)**: about `target` distinct states, each summing 10 values.
- **Space: O(target)** for the memo and the recursion depth.

## Common mistakes

- Off-by-one in the stopping rule (the dealer stands at exactly `target - 4`).
- Rounding intermediate results.
- Forgetting memoization: the call tree grows exponentially with the distance to the target.

## Follow-ups

1. **New 21 Game (LeetCode #837):** similar process; with large parameters, replace the 10-term sum by a sliding window sum (Staircase Traversal) to get O(n).
2. **Expected number of cards drawn:** same recursion structure with `E(h) = 1 + average of E(h + card)`.
3. **Bottom-up version:** compute `P` from high totals down to the starting hand.

## What to remember

Probability over a process with repeated states is a DP over states: the probability from a state is the average over next states, and each state is solved once.
