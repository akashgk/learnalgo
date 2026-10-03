# ATM System: High-Level Design

**Asked at:** Amazon, Microsoft, Goldman Sachs, JPMorgan, Visa, Uber (mostly as an LLD/state-machine question). **Core topics:** the HLD side is the ATM network: terminal, acquirer/switch, card network, issuing bank; authorization messages, reversals on timeouts, idempotency, offline behavior, security (PIN encryption, HSMs), cash management.

Ask which round this is; most "design an ATM" questions want the class design in [LLD.md](LLD.md).

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Whose ATMs, whose cards? | A bank's ATMs that accept its own cards and other banks' cards through a card network. |
| Transactions? | Balance inquiry, cash withdrawal, deposit (follow-up), PIN change (follow-up). |
| Scale? | 10,000 ATMs; ~2 M transactions/day; peaks at lunch and paydays. |
| Correctness? | Never debit without dispensing (or reverse it); never dispense without a debit. |
| Security? | PINs never travel or rest in clear text. |

## 2. Requirements

**Functional:** card + PIN authentication, balance inquiry, withdrawal with limits, receipts, card retention after repeated wrong PINs, reversal when dispensing fails.

**Non-functional:** strong consistency for account balances, idempotent and auditable messages, high availability of the authorization path, tamper resistance, operation during partial network failure (with strict limits).

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Transactions | 2 M/day | **~25/s** avg, ~200/s peak |
| Messages | ~3 per withdrawal (auth, completion, sometimes reversal) | small; latency matters more than throughput |

## 4. Architecture

```text
 ATM terminal (card reader, encrypting PIN pad, dispenser, journal printer)
   --encrypted messages (ISO 8583-style) over a private network-->
 ATM switch / acquirer (the bank operating the ATM): routing, idempotency, stand-in limits
   |-- own customers --> core banking (accounts, holds, ledger)
   |-- other banks' cards --> card network (Visa/Mastercard/local) --> issuing bank authorization
 HSM (hardware security module): PIN translation and verification; keys never leave it
 Monitoring: cash levels, device faults, fraud signals --> cash logistics, field engineers
```

## 5. Deep dive: the withdrawal message flow

1. ATM sends an **authorization request** with a unique transaction ID, the encrypted PIN block and the amount.
2. The issuer verifies the PIN (in its HSM), checks balance and limits, places a hold/debit, replies approve/decline.
3. ATM dispenses; on success sends a **completion**; on a dispenser fault (or a timeout waiting for the response) sends a **reversal** with the same transaction ID.
4. Reversals and retries are **idempotent** by transaction ID; the issuer releases the hold exactly once.

Ambiguity is the hard part: if the ATM never gets the response, it must not dispense, and it must send a reversal in case the debit happened.

## 6. Deep dive: security

- The PIN pad encrypts the PIN immediately (PIN block with a device key). Only HSMs can decrypt or translate it between key zones (ATM key -> network key -> issuer key).
- Card authentication via the chip (EMV cryptograms) defeats cloned magnetic stripes.
- Message authentication codes on messages; device keys rotated; physical tamper detection.

## 7. Deep dive: cash management

- The dispenser has cassettes of fixed denominations with counts; the ATM must find a combination of available notes (limited counts make greedy insufficient in general).
- Telemetry reports cash levels; logistics plans refills; the ATM refuses amounts it cannot dispense before contacting the bank.

## 8. Failure modes

| Failure | Behavior |
|---|---|
| No response from issuer | Do not dispense; send reversal; show "unable to complete". |
| Dispenser jam after approval | Reversal with the same transaction ID; journal records it for reconciliation. |
| Network to the issuer down | Stand-in processing by the acquirer with low limits, or decline. |
| Duplicate messages | Idempotent by transaction ID at the switch and issuer. |
| End-of-day mismatch | Reconcile the ATM journal, switch logs and issuer ledger. |

## 9. What interviewers look for

- A clear transaction flow with authorization, completion and reversal.
- Idempotency and handling of ambiguous outcomes.
- PIN security with HSMs (no plain PINs anywhere).
- Cash dispensing constraints and limits.

## 10. Common mistakes

- Debiting after dispensing (cash out, no debit if the network fails in between).
- Retrying a withdrawal with a new transaction ID.
- Sending or storing the PIN in plain text.
- Greedy note selection that fails with limited cassettes.

## 11. Follow-ups

1. **Deposits:** note validation, envelope-free deposits, holds until verification.
2. **Cardless withdrawal:** one-time codes from the mobile app.
3. **Fraud:** skimming detection, velocity checks across ATMs.

See [LLD.md](LLD.md) for the ATM state machine, PIN attempts and card retention, a bank interface with idempotent debit and reversal, bounded-note dispensing, and daily limits.
