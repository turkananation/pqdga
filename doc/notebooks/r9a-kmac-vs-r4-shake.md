# R9a — KMAC256 vs R4 SHAKE256 expand

## Question

Does binding the **same** ML-KEM shared secret under KMAC256 produce a
different domain namespace than SHAKE256 expand (R4 `SharedSecretPqdga`)?

## Method

1. Fix `ss` (32 bytes lab fixture).
2. Generate N domains with `KmacSharedSecretPqdga` (KMAC256).
3. Generate N domains with `SharedSecretPqdga` (SHAKE256) under matching
   campaign/epoch packing.
4. Compare sets / ordered lists.

## Lab API

```dart
final exp = await BindingAnalysis.kmacVsShake(count: 5);
// exp['outputs_differ'] == true
// exp['kmac_domains'] / exp['shake_domains']
```

Full suite: `BindingAnalysis.runAll()` → `experiments.kmac_vs_shake`.

## Observation (lab)

Outputs **differ**. Same secret + campaign does **not** imply interchangeable
precompute lists across KDF choices.

## Interpretation (claim-disciplined)

- This is a **construction delta** (domain separation via KDF / customization),
  not a security proof that KMAC is “stronger” than SHAKE for DGA expand.
- SOC lesson: detectors and sinkhole precompute must track **expand path**
  (`xof` / `binding_mode`), not only “secret-bound”.

## Hardness notes

- H1 remains high when `ss` is unknown (both paths).
- Switching KDF does not by itself raise H2 (no signature requirement).
