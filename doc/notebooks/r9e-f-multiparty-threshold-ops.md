# R9e/f — Multi-party vs threshold ops cost

## Question

What is the **operational** difference between:

- **MultiParty** — all n independent secrets required online, and
- **Threshold (lab)** — any k of n shares combine,

and how do both differ from **MultiRecipient** KEM-wrap compartmentation?

## Method

1. MultiParty: generate with full secret set; drop one → fail closed / empty.
2. Threshold lab: deal n shares, combine any k → binding key; k−1 insufficient.
3. Record online parties, sync assumptions, failure modes.

## Lab API

```dart
final exp = await BindingAnalysis.multiPartyVsThresholdOps();
// exp distinguishes n-of-n vs k-of-n lab costs
```

## Observation (lab)

| Construction | Online requirement | Resilience | Notes |
| --- | --- | --- | --- |
| MultiParty | all n | low | joint binding; any missing party blocks |
| Threshold lab | any k of n | higher | **not production TSS** |
| MultiRecipient | 1 of N wraps | per-recipient | ciphertext wrap ≠ joint derive |

## Interpretation (claim-disciplined)

- Ops cost is a **playbook** dimension (who must be online, rotation pain),
  not a hardness proof.
- **Never conflate** MultiRecipient wrap with MultiParty/Threshold joint keys.
- R9f remains **lab k-of-n** — not production threshold signature/secret sharing.

## Open

- [ ] Production TSS integration (intentionally out of productization scope).
