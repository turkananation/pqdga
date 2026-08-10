# R9c — Delete-forward / ratcheting

## Question

If an operator advances a ratchet epoch and **deletes** the prior epoch key,
can the later key reconstruct earlier domain names in this lab construction?

## Method

1. Establish root secret → epoch 0 key (`RatchetingPqdga.labEstablish`).
2. Advance to epoch 1; generate domains at both epochs.
3. Attempt reconstruction of epoch-0 names using only epoch-1 material.
4. Record whether reconstruction succeeds.

## Lab API

```dart
final exp = await BindingAnalysis.ratchetDeleteForward();
// exp['later_key_reconstructs_earlier_names'] == false
// exp['claims_forward_secrecy'] == false
```

## Observation (lab)

Later epoch keys **do not** reproduce earlier names when epoch index is bound
into expand. Domain lists for epoch 0 and epoch 1 differ.

## Interpretation (claim-disciplined)

- **No forward-secrecy claim.** Observation under lab assumptions ≠ FS proof.
  A full threat model (state compromise, transcript, side channels, rollback)
  is required before any FS language.
- Pedagogical value: delete-forward drills for SOC “what if operator rotates
  and drops prior seed material?”

## Open

- [ ] Formal FS claim under an explicit threat model (stays open by design).
