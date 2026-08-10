# PQDGA - Post Quantum Domain Generation Algorithms

Defensive-research Dart library for **classical DGA reproduction** and **post-quantum rendezvous design**.

> **Ethics / authorized use only**  
> This package is a **lab kit for SOC, IR, and security research**. It is not operational C2 software.  
> Do not use it to run real campaigns, sinkhole third-party infrastructure without authorization, or ship live operator secrets.  
> Details: [doc/08-ethics-lab-use.md](doc/08-ethics-lab-use.md).

## What it is

- **Classical path:** config objects (`DGAAlgorithm`) + registry-dispatched `DGAGenerator` produce deterministic domain lists and analyst metadata for known malware-style and generic families (Conficker, Necurs, Locky, QakBot, dictionary/arithmetic generators, research generics, and more).
- **Post-quantum path:** `PQDGAGenerator` + `PQDGAResult` with full core families, PQ extras, an **R9 cryptographic binding research ladder** (KMAC, hybrid-KMAC, ratchet, hierarchy, multi-party, threshold, authenticated context), plus post-R9 hooks: **real FIPS 205 SLH-DSA** checkpoints (`pqcrypto`), lexical secret-bound labels, and hybrid dual-sign authenticity (`PqForgeHybridSigner`). Primitive order: **pqforge → pqcrypto → other** (never reimplement NIST PQ already in those libs). Built on [`pqforge`](https://pub.dev/packages/pqforge), [`pqcrypto`](https://pub.dev/packages/pqcrypto) (SHAKE + SLH-DSA), [`pointycastle`](https://pub.dev/packages/pointycastle) (classical + KMAC256/cSHAKE), and [`swissarmyknife`](https://pub.dev/packages/swissarmyknife) for epoching, codecs, validation — **not** crypto.

**Research framing:** standardized primitives (ML-KEM, ML-DSA, SHAKE, KMAC) composed into **secret-/group-/evolution-bound deterministic namespace constructions**. Not a claim of a new PQ primitive or “world’s first PQ DGA.”

## Research documentation

| Entry | Description |
| --- | --- |
| **[doc/README.md](doc/README.md)** | Full document index |
| **[doc/PROGRESS.md](doc/PROGRESS.md)** | Living checklist — what is done vs pending |
| [doc/00-overview.md](doc/00-overview.md) | Mission and product outputs |
| [doc/07-implementation-roadmap.md](doc/07-implementation-roadmap.md) | Build order (R0–R9) |

**Update `doc/PROGRESS.md` in the same change as every code deliverable.**

## Features (current)

- Classical malware-style DGAs: Conficker, Necurs, Pushdo, Rovnix, CryptoLocker, Bamital, Tinba, Murofet, Simda, Matsnu
- Classical P0–P2 families (Locky, QakBot, Ramnit, Emotet-era, Kraken, …) with golden tests
- Classical generics + research generics: time/dictionary/arithmetic/permutation; Markov, IDN, oracle-seed, multi-channel, fast-flux, nested labels
- Registry dispatch (classical + PQ)
- `DGAResult` / `PQDGAResult` with SOC metadata (`predictable`, `secretBound`, playbook flags, IOC templates, `soc_lesson`)
- **Every classical family** emits full analyst metadata via `ClassicalSocMetadata` + `SocFeatures.iocTemplateFromDga`
- **QuantumResistant** SHAKE256 — teaches **PQ hash ≠ secret** (public seed remains precomputable)
- **SharedSecret** ML-KEM → SHAKE — offline precompute fails without ss; KEM CT-length IOCs
- **SignatureAuthenticated** ML-DSA over domain‖epoch‖campaign; Identity, Hybrid, Decentralized
- PQ extras: EnvelopeRendezvous, RateLimited, MultiRecipient (**wrap** compartmentation)
- **R9 binding ladder:** KMAC-SharedSecret, Hybrid-KMAC, Ratcheting, Hierarchical, MultiParty, Threshold, AuthenticatedContext
- **Post-R9 extras:** LexicalSharedSecret, SlhDsaCheckpoint (real `pqcrypto.SlhDsa`), HybridAuthenticated (`PqForgeHybridSigner`), plus `PostRendezvousSession` AEAD lab helper
- `SocFeatures` per-domain / batch feature extraction; `HardnessScorecard` H1–H7 lab ratings

## Getting started

```bash
dart pub get
```

Dependencies: `pointycastle`, `pqforge`, `pqcrypto` ^0.4 (direct + override for SLH-DSA while pqforge pins 0.3.x), `swissarmyknife`.

## Usage

```dart
import 'package:pqdga/pqdga.dart';

Future<void> main() async {
  // Classical
  final classical = await DGAGenerator(
    DGAConfig(algorithm: const ConfickerDGA()),
  ).generateDomains(DateTime.utc(2024, 1, 1), 5);
  print(classical.domains);

  // Post-quantum baseline (public seed — still sinkhole-precomputable)
  final pq = await PQDGAGenerator(
    PQDGAConfig(
      algorithm: const QuantumResistantPqdga(campaignId: 'toy-campaign'),
      minDomainLength: 8,
      maxDomainLength: 12,
    ),
  ).generateDomains(DateTime.utc(2024, 6, 15), 5);
  print(pq.domains);
  print('predictable=${pq.predictable} secretBound=${pq.secretBound}');

  // R9a — KMAC-bound shared secret (lab ephemeral keys)
  final kmac = KmacSharedSecretPqdga.labEstablish(campaignId: 'toy-campaign');
  final bound = await PQDGAGenerator(
    PQDGAConfig(
      algorithm: kmac.algorithm,
      minDomainLength: 8,
      maxDomainLength: 12,
    ),
  ).generateDomains(DateTime.utc(2024, 6, 15), 3);
  print('KMAC secretBound=${bound.secretBound} xof=${bound.xof}');
}
```

Longer samples: [`example/`](example/).

## Additional information

- Architecture and plug-in recipe: [doc/01-architecture.md](doc/01-architecture.md)
- Classical catalog: [doc/02-classical-families.md](doc/02-classical-families.md)
- PQ design + R9 ladder: [doc/03-post-quantum-design.md](doc/03-post-quantum-design.md)
- SOC detect/mitigate: [doc/05-soc-detection-mitigation.md](doc/05-soc-detection-mitigation.md)
- Adversarial hardness: [doc/06-adversarial-hardness.md](doc/06-adversarial-hardness.md)
