# Architecture

## Module map

```text
lib/
  pqdga.dart                         # package entry → pqdga_base.dart
  src/
    pqdga_base.dart                  # public exports (classical + PQ)
    common/
      predictability.dart           # PredictabilityClass wire enum
      soc_features.dart             # DomainFeatures / BatchFeatures / SocFeatures + IOC helpers
      classical_soc_metadata.dart   # Classical playbook_flags / predictability builder
      hardness_scorecard.dart       # H1–H7 lab score emission
      multi_channel_codec.dart      # Multi-channel encodings (R8)
      flux_schedule.dart            # Fast-flux schedule metadata (R8)
    classical/
      dga_core.dart                  # abstract DGAAlgorithm
      dga_config.dart                # DGAConfig(algorithm, lengths, rotation)
      dga_result.dart                # DGAResult(domains, date, algorithm, seed, metadata)
      dga_generator.dart             # DGAGenerator + registry dispatch
      algorithms/
        conficker_dga.dart           # … one config class per family
        necurs_dga.dart
        …
        locky_dga.dart               # P0 set
        qakbot_dga.dart
        suppobox_dga.dart
        banjori_dga.dart
        ranbyus_dga.dart
        time_based_dga.dart
        dictionary_based_dga.dart
        arithmetic_dga.dart
        permutation_dga.dart
    post_quantum/
      pqdga_core.dart                # abstract PQDGAAlgorithm
      pqdga_config.dart              # PQDGAConfig (mirrors classical knobs)
      pqdga_result.dart              # PQDGAResult (predictable, secretBound, …)
      pqdga_generator.dart           # PQDGAGenerator + registry; core + extras + R9
      crypto/
        shake_xof.dart               # pqcrypto SHAKE128/256 wrapper
        kmac256.dart                 # NIST SP 800-185 KMAC256 (R9; PointyCastle cSHAKE)
        dns_label_codec.dart         # charset map + DNS validate (swissarmyknife Result)
        epoch_bucket.dart            # seedRotationDays buckets
      algorithms/
        quantum_resistant_pqdga.dart # R3 — hash-based QR baseline
        shared_secret_pqdga.dart     # R4 — ML-KEM ss → SHAKE
        signature_authenticated_pqdga.dart  # R5 — ML-DSA over domain
        identity_based_pqdga.dart    # R6
        hybrid_shared_secret_pqdga.dart     # R6 extra
        decentralized_pqdga.dart     # R6
        envelope_rendezvous_pqdga.dart      # R8 extra
        rate_limited_pqdga.dart             # R8 extra
        multi_recipient_pqdga.dart          # R8 wrap compartmentation
        kmac_shared_secret_pqdga.dart       # R9a
        hybrid_kmac_pqdga.dart              # R9b
        ratcheting_pqdga.dart               # R9c
        hierarchical_pqdga.dart             # R9d
        multi_party_pqdga.dart              # R9e (≠ multi-recipient)
        threshold_pqdga.dart                # R9f (≠ multi-recipient)
        authenticated_context_pqdga.dart    # R9g
```

Live status: [PROGRESS.md](PROGRESS.md).

## Classical flow

```text
DGAConfig(algorithm: SomeDGA(...))
        │
        ▼
DGAGenerator(config).generateDomains(date, count)
        │
        ▼
DGAGenerator.registry[algo.runtimeType](generator, date, count, algo)
        │
        ▼
DGAResult {
  domains, generationDate, algorithm, seed, metadata
}
```

### Marker + config pattern

- `DGAAlgorithm` is an empty abstract marker (`dga_core.dart`).
- Each family is a **const-friendly config class** with family-specific fields (TLDs, length bands, variants).
- Generation logic lives in private methods on `DGAGenerator` (uses `pointycastle` for MD5 and similar).

### Dispatch (R2)

`generateDomains` uses a **type registry** (`Map<Type, DGAHandler>`). Adding a family requires:

1. New algorithm file  
2. `_generateX` method + **one registry entry** in `DGAGenerator.registry`  
3. Export in `pqdga_base.dart`

## Post-quantum flow

```text
PQDGAConfig(algorithm: SomePqdga(...))
        │
        ▼
PQDGAGenerator(config).generateDomains(date, count)
        │
        ▼
PQDGAGenerator.registry[algo.runtimeType](...)
        │
        ▼
shared pipeline (see 03-post-quantum-design.md)
  epoch/campaign → [optional secret] → SHAKE256 XOF or KMAC256 → DNS labels
  → optional ML-DSA (domain or context) → PQDGAResult
```

All PQ **core**, extras, and **R9 binding ladder** are implemented (R3–R9). SOC feature helpers live in `common/soc_features.dart` (R7).

## Plug-in recipe (classical)

Keep new classical families consistent:

| Step | Action | Path |
| ---: | --- | --- |
| 1 | Add pure config `class FooDGA extends DGAAlgorithm` | `lib/src/classical/algorithms/foo_dga.dart` |
| 2 | Implement `_generateFoo` + **registry entry** | `lib/src/classical/dga_generator.dart` |
| 3 | Export | `lib/src/pqdga_base.dart` |
| 4 | Golden test: fixed UTC date (+ config) → fixed domains | `test/` |
| 5 | Tick PROGRESS + catalog row | `doc/PROGRESS.md`, `doc/02-classical-families.md` |
| 6 | Emit rich metadata via `ClassicalSocMetadata.build` / `.enrich` | charset, lengths, seed packing, PRNG, `predictability`, `playbook_flags`, `soc_lesson` |

Example config shape (existing Conficker):

```dart
class ConfickerDGA extends DGAAlgorithm {
  final List<String> tld;
  final int minDomainLength;
  final int maxDomainLength;
  // …
  const ConfickerDGA({ … });
}
```

## Plug-in recipe (PQ)

| Step | Action | Path |
| ---: | --- | --- |
| 1 | Add config with campaign/epoch/key material handles (**never** hard-code live secrets) | `lib/src/post_quantum/algorithms/*` |
| 2 | Implement handler + **registry entry** in `PQDGAGenerator` using `pqforge` / SHAKE / KMAC / `swissarmyknife` | `pqdga_generator.dart` |
| 3 | Return `PQDGAResult` with `predictable`, `secretBound`, kem/sig IOC metadata + playbook flags | `pqdga_result.dart` |
| 4 | Ephemeral keys in tests only | `test/` |
| 5 | Document SOC lesson | `doc/03-post-quantum-design.md` + PROGRESS |

Package roles: [04-package-utilization.md](04-package-utilization.md).

## Dispatch model (delivered in R2)

**Registry (chosen):**

```text
Map<Type, DGAHandler>   // classical
Map<Type, PQDGAHandler> // post-quantum
```

Handlers receive the generator instance (classical) or config (PQ) so private methods stay on the generator class without a central `if (algo is …)` ladder.

## Result contracts

### `DGAResult` (today)

| Field | Role |
| --- | --- |
| `domains` | Generated FQDNs |
| `generationDate` | Lab date used |
| `algorithm` | Human-readable family name |
| `seed` | Explainability string (e.g. packed date) |
| `metadata` | Analyst contract: `predictability`, `predictable`, `secret_bound`, `playbook_flags`, charset, PRNG, seed packing, `soc_lesson`, family extras |

### `PQDGAResult` (R2+)

| Field | Role |
| --- | --- |
| `predictable` | `true` if offline precompute works without secret |
| `secretBound` | `true` if ML-KEM ss / non-public seed required |
| `epoch` / campaign id | Bucket used (toy ids in lab) |
| `kemAlgorithm` / CT length | Network IOC template |
| `sigAlgorithm` / sig bytes | Anti-sinkhole lab artifact |
| `xof` | e.g. `SHAKE256` or `KMAC256` |
| `signatures` / `pubkeyFingerprint` | Optional detached verify material |
| `metadata` | Playbook flags, charset, IOC templates, `binding_mode` / `binding_ladder` (R9) |

## Exports

All public types are re-exported from `lib/src/pqdga_base.dart` via `package:pqdga/pqdga.dart`. New families must be added to the export list or they stay package-private to path imports only.
