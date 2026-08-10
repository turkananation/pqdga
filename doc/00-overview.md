# Overview — defensive DGA research lab

## Mission

`pqdga` is a **defensive research** Dart package that:

1. **Reproduces classical malware-style DGAs** so analysts can train detectors, build golden vectors, and practice sinkhole/RPZ playbooks.
2. **Models harder post-quantum rendezvous** (via `pqforge` ML-KEM/ML-DSA/hybrid, `pqcrypto` SHAKE + FIPS 205 SLH-DSA, PointyCastle KMAC/cSHAKE, and `swissarmyknife` plumbing) so blue teams know what breaks when adversaries adopt secret-/sig-bound name generation. Primitive order: **pqforge → pqcrypto → other**.
3. Emits **analyst-ready artifacts** — not domains alone: metadata, predictability class, playbook flags, IOC templates, SOC feature vectors, and hardness scorecards (H1–H7).

Authorized lab use only. No operational C2. See [08-ethics-lab-use.md](08-ethics-lab-use.md).

## Dual framing

| Lens | Goal | Primary docs |
| --- | --- | --- |
| **SOC / blue team** | Detect, mitigate, sinkhole, extract config, shift to behavior when precompute fails | [05-soc-detection-mitigation.md](05-soc-detection-mitigation.md), family catalogs |
| **Adversarial hardness** | Make offline prediction, sinkholing, and hijack **super hard** without secrets/keys | [06-adversarial-hardness.md](06-adversarial-hardness.md), [03-post-quantum-design.md](03-post-quantum-design.md) |

Every hardness feature is paired with a blue-team counter in docs and result metadata (`playbook_flags`, `HardnessScorecard` counters).

## Product outputs

| Output | Description |
| --- | --- |
| Domain lists | Deterministic (when seed is known) FQDNs for fixed date/campaign |
| `DGAResult` | Classical domains + algorithm id + seed explainability + **full SOC metadata** |
| `PQDGAResult` | PQ domains + `predictable` / `secretBound` + kem/sig/xof fields + metadata |
| Feature hooks | `SocFeatures.forDomain` / `forBatch` / `fromDgaResult` / `fromPqdgaResult` |
| Predictability class | `trivial` → `config-seeded` → `oracle-seeded` → `secret-seeded` (+ PQ flags) |
| IOC templates | `SocFeatures.iocTemplateFromDga` / `iocTemplateFromPqdga` (charset, PRNG, CT/sig sizes, …) |
| Hardness scorecard | `HardnessScorecard` H1–H7 + counter tags (lab design ratings, not proofs) |
| Playbooks | Precompute+sinkhole vs lexical vs behavioral/registration/EDR paths (P1–P7) |

## Current baseline (snapshot)

| Area | State |
| --- | --- |
| Classical malware-style families | **Done** — Conficker, Necurs, Pushdo, Rovnix, CryptoLocker, Bamital, Tinba, Murofet, Simda, Matsnu |
| Classical generics | **Done** — time-based, dictionary, arithmetic, permutation |
| Classical P0 | **Done** — Locky, QakBot, Suppobox-style, Banjori, Ranbyus |
| Classical P1/P2 | **Done** — Ramnit…Emotet; Kraken…Proslikefan |
| Research generics | **Done** — Markov, IDN, oracle-seed, multi-channel, fast-flux, nested labels |
| Classical SOC metadata / IOC | **Done** — every classical family emits `predictability`, `playbook_flags`, `soc_lesson`, charset/PRNG/seed packing; `iocTemplateFromDga` |
| PQ core | **Done** — `PQDGAGenerator` + `PQDGAResult` + QuantumResistant, SharedSecret, SignatureAuthenticated, IdentityBased, Decentralized |
| PQ extras | **Done** — HybridSharedSecret, EnvelopeRendezvous, RateLimited, MultiRecipient (wrap ≠ multi-party) |
| PQ binding ladder (R9) | **Done** — KMAC256 helper + R9a–R9g constructions |
| Dependencies | `pqforge`, `pointycastle`, `swissarmyknife`, direct `pqcrypto` ^0.4 (SLH-DSA + SHAKE; override vs pqforge 0.3 pin) |
| Post-R9 extras | LexicalSharedSecret, SlhDsaCheckpoint (real FIPS 205), HybridAuthenticated, PostRendezvousSession |
| SOC code artifacts | **Done** — `SocFeatures`, classical metadata helper, hardness scorecard |
| This `/doc` tree | Full design set R0–R9 + post-roadmap open section in PROGRESS |

Live checkmarks and post-R9 backlog: [PROGRESS.md](PROGRESS.md).

## Architecture in one line

Config objects extending `DGAAlgorithm` / `PQDGAAlgorithm` → central registry dispatch → `DGAResult` / `PQDGAResult` with SOC metadata, IOC templates, and optional hardness scorecards.

Details: [01-architecture.md](01-architecture.md).

## Research framing (novelty discipline)

- **Not** a new PQ primitive (ML-KEM, ML-DSA, SHAKE, KMAC are standardized).
- **Yes** a construction research program: deterministic namespaces bound to secrets, authenticity, groups, hierarchy, and evolving key material.
- Prefer: *evaluate predictability, sync, rotation, and observability of secret-/group-bound deterministic namespaces.*
- Do **not** claim “world’s first PQ DGA.”

## Implementation status

Roadmap phases **R0–R9 are complete**. Remaining work is maintenance, optional corpus fidelity, analysis notebooks, and explicitly deferred extras — tracked only in [PROGRESS.md](PROGRESS.md) § Open / deferred. Build history: [07-implementation-roadmap.md](07-implementation-roadmap.md).
