# Implementation roadmap

Documentation phase (**R0**) gates coding. Execute phases in order for research ROI.  
Canonical checkmarks: [PROGRESS.md](PROGRESS.md). Designs: [02](02-classical-families.md), [03](03-post-quantum-design.md), [04](04-package-utilization.md), [05](05-soc-detection-mitigation.md).

## Phase overview

| ID | Phase | Primary PROGRESS sections | Status |
| --- | --- | --- | --- |
| **R0** | Documentation (`/doc` + root README) | Docs (this phase) | **done** (2026-08-08) |
| **R1** | Classical P0 families | Classical — P0 | **done** (2026-08-08) |
| **R2** | Dispatch refactor + `PQDGAResult` | Architecture / quality; PQ — core (`PQDGAResult`) | **done** (2026-08-08) |
| **R3** | QuantumResistant (SHAKE) | PQ — QuantumResistant + `PQDGAGenerator` | **done** (2026-08-08) |
| **R4** | SharedSecret (ML-KEM) | PQ — SharedSecret; Infra swissarmyknife as needed | **done** (2026-08-08) |
| **R5** | SignatureAuthenticated (ML-DSA) | PQ — SignatureAuthenticated | **done** (2026-08-09) |
| **R6** | Identity + Hybrid + Decentralized (+ extras start) | PQ core remaining + PQ extras | **done** (2026-08-09) |
| **R7** | SOC polish | SOC artifacts; IOC templates in examples | **done** (2026-08-09) |
| **R8** | Research generics | Research generics; optional P1/P2 classical | **done** (2026-08-09) |
| **R9** | Cryptographic binding research ladder | PQ — binding ladder R9a–R9g | **done** (2026-08-09) |

---

## R0 — Documentation

**Deliverables:** full `doc/*` tree, PROGRESS baseline matching repo, ethics banner on root README.  
**Exit:** all Docs checklist items `[x]`; no claim that PQ generation is implemented.  
**This phase does not modify `lib/**`.**

## R1 — Classical P0

**Status:** **done** (2026-08-08).  
**Families:** Locky, QakBot, Suppobox-style, Banjori, Ranbyus.  
**Per family DoD:** config + generator path + export + golden test + metadata + catalog/PROGRESS tick ([01-architecture](01-architecture.md) recipe).  
**Delivered:** five algorithm configs under `lib/src/classical/algorithms/`, dispatch in `dga_generator.dart`, exports, `test/pqdga_test.dart` goldens (+ Suppobox wordlist fixture), catalog/PROGRESS updates.  
**Why first:** high-frequency real families, distinct SOC features, low dependency on PQ stack.

## R2 — Dispatch refactor + `PQDGAResult`

**Status:** **done** (2026-08-08).

| Work | Notes |
| --- | --- |
| Replace or wrap `if (algo is …)` ladder | `DGAGenerator.registry` + `PQDGAGenerator.registry` |
| Introduce `PQDGAResult` | `lib/src/post_quantum/pqdga_result.dart` |
| Skeleton `PQDGAGenerator` | Registry dispatch (later phases filled all handlers) |
| Align classical metadata keys | `PredictabilityClass` wire names on P0 families |

**PROGRESS:** Architecture / quality dispatch item; PQ `PQDGAResult`; generator partial→implemented for QR in R3.

## R3 — QuantumResistant (SHAKE)

**Status:** **done** (2026-08-08).

| Work | Notes |
| --- | --- |
| Implement SHAKE256 expand path | `ShakeXof` → `pqcrypto` SHAKE ([04](04-package-utilization.md)) |
| Public-seed mode default for lesson | `predictable=true`, `secretBound=false` |
| Golden vectors + SOC lesson in examples | “PQ hash ≠ secret” |
| Optional: add `swissarmyknife` for label validate/codec | `swissarmyknife` + direct `pqcrypto` in pubspec |

**Exit:** QuantumResistant DoD met; generator no longer empty. **Delivered.**

## R4 — SharedSecret (ML-KEM)

**Status:** **done** (2026-08-08).

| Work | Notes |
| --- | --- |
| `PqForge` encaps/decaps → ss → SHAKE → labels | Never log ss; `labEstablish` helper |
| Rotation via `seedRotationDays` | Epoch buckets (`EpochBucket`) |
| `predictable=false`, `secretBound=true` | IOC: kem id + CT length on `PQDGAResult` |
| Fail-closed on generate errors | No partial domain lists returned |

**Main hardness jump** for blue-team P4 playbooks. **Delivered.**

## R5 — SignatureAuthenticated (ML-DSA)

**Status:** **done** (2026-08-09).

| Work | Notes |
| --- | --- |
| Sign canonical domain\|\|epoch\|\|campaign | `PqForge.sign` / `verify` |
| Detached sig + pubkey fingerprint in result | Lab verify drills |
| Flags `requires_signature` | Playbook P5 |
| `labEstablish` + golden domains + verify tests | Ephemeral ML-DSA-65 keys only |

**Delivered:** config + generator path, SOC/P5 metadata, example verify drill.

## R6 — Identity, Hybrid, Decentralized, extras

**Status:** **done** for core three + Hybrid + extras (2026-08-09).

| Order | Item | Status |
| --- | --- | --- |
| 1 | IdentityBased (vk namespace ± sign) | **done** |
| 2 | HybridSharedSecret (`PqForgeCombiner`) | **done** |
| 3 | Decentralized encodings (base32 / abstract ids) | **done** |
| 4 | EnvelopeRendezvous, rate-limited, multi-recipient | **done** (2026-08-09) |

## R7 — SOC polish

**Status:** **done** (2026-08-09).

| Work | Notes |
| --- | --- |
| Per-domain feature helper | `SocFeatures.forDomain` — length, entropy, ratios, TLD, IDN |
| Batch features | `forBatch` / `fromDgaResult` / `fromPqdgaResult` |
| Predictability on results | PQ fields + classical metadata; batch surfaces wire names |
| Examples print IOC templates beside domains | example uses `iocTemplateFromPqdga` + per-domain features |
| Notebook-oriented docs pass | `05-soc-detection-mitigation.md` + architecture pointer |

## R8 — Research generics (+ optional classical P1/P2)

**Status:** **done** (2026-08-09).

| Work | Notes |
| --- | --- |
| Markov / n-gram LM DGA | `MarkovDGA` + lexical SOC flag |
| Homoglyph / IDN / punycode | `IdnDGA` + `xn--` goldens |
| Seed-from-public-oracle | `OracleSeedDGA` (`oracle-seeded`) |
| Multi-channel rendezvous | `MultiChannelDGA` + `MultiChannelCodec` |
| Fast-flux schedule coupling | `FastFluxDGA` + `FluxSchedule` metadata |
| Nested / wildcard labels | `NestedLabelDGA` |
| Classical P1 | Ramnit, Nymaim, Shiotob, Pykspa, Vawtrak, Emotet |
| Classical P2 | Kraken, Torpig, CoreBot, DirCrypt, Proslikefan |
| PQ extras | EnvelopeRendezvous, RateLimited, MultiRecipient |
| Pre-P0 golden coverage | All baseline malware-style + generics pinned |

**Delivered:** full registry wiring, goldens in `test/pqdga_test.dart`, PROGRESS/docs aligned.

## R9 — Cryptographic binding research ladder

**Status:** **done** (2026-08-09).

Does **not** renumber historical R0–R8. Adds constructions that bind deterministic namespaces to progressively richer crypto material. Framing: **research constructions**, not a new PQ primitive. Do **not** claim “world’s first PQ DGA.”

| ID | Construction | Research question | Status |
| --- | --- | --- | --- |
| **R9a** | `KmacSharedSecretPqdga` | Cleaner domain separation than raw SHAKE for secret-bound names? | **done** |
| **R9b** | `HybridKmacPqdga` | Transition-period properties when classical + PQ material required **and** expand is KMAC | **done** |
| **R9c** | `RatchetingPqdga` | Can later epoch material reconstruct earlier names after delete? | **done** |
| **R9d** | `HierarchicalPqdga` | Delegation / compartment / revoke / rotate per subtree | **done** |
| **R9e** | `MultiPartyPqdga` | Namespace requires ≥2 independent secrets (≠ multi-recipient wrap) | **done** |
| **R9f** | `ThresholdPqdga` | k-of-n resilience vs sync/ops cost (lab shares; not live TSS) | **done** |
| **R9g** | `AuthenticatedContextPqdga` | What does **authenticity** add vs **confidentiality**? | **done** |

**Infra:** lab `Kmac256` (NIST SP 800-185 on PointyCastle `CSHAKEDigest`) under `lib/src/post_quantum/crypto/kmac256.dart`.

**Naming discipline:**

| Construction | Description |
| --- | --- |
| QuantumResistant (project R3) | Quantum-resistant **hash-based** / PQ-hardened — not a NIST PQC KEM/sig algorithm DGA |
| SharedSecret (project R4) | **ML-KEM-bound** secret generation (true NIST PQC KEM use) |
| MultiRecipient | One DEM key **wrapped** for N recipients — **not** multi-party or threshold derivation |
| MultiParty / Threshold | Joint / k-of-n **derivation** of the namespace binding key |

**Email ladder map** (external R3–R13 IDs ≠ project R0–R8): see [03-post-quantum-design.md](03-post-quantum-design.md) § R9.

**Delivered:** configs + generator paths + exports + goldens/property tests for R9a–R9g.

---

## Dependency timing

| Dependency | When |
| --- | --- |
| `pointycastle` | classical + R9 KMAC256 via `CSHAKEDigest` |
| `pqforge` | already (use from R3+) |
| `swissarmyknife` | added (R3; epoch, codec, validate, rate limit, Either) |
| direct `pqcrypto` | added (R3; SHAKE path) |

**Do not add swissarmyknife in R0** unless required for doc accuracy (not required).

## Definition of phase complete

A phase is complete only when:

1. All listed PROGRESS boxes for that phase are `[x]` under full DoD.  
2. Tests exist for new generators (golden or property).  
3. No document claims unfinished PQ families are implemented.  
4. PROGRESS summary counts recomputed.

## Next coding PR

**Roadmap complete (R0–R9).** Further work is maintenance / corpus expansion / analysis only.

Canonical backlog: [PROGRESS.md](PROGRESS.md) § **Open / deferred (post R9)**.

Post-R9 polish already delivered (2026-08-09): classical SOC metadata/IOC parity for all families, `HardnessScorecard`, overview/doc hygiene, example IOC+hardness lines.

Still optional:

1. Literature-perfect re-keys for P1/P2 against external corpuses.  
2. Binding-ladder **analysis** papers/notebooks (do not claim FS/threshold security without threat model).  
3. Keep PROGRESS in sync with any new families.  
4. Prefer small PRs for detector-notebook integrations.  
5. Do **not** rush PQRP productization; keep lab framing.
