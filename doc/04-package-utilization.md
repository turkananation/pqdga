# Package utilization

How `pqdga` should use third-party packages. Verified against local pub-cache (`pqforge` **0.3.0**, `swissarmyknife` **0.1.0**, direct `pqcrypto` **0.4.0** via override).

**Infra status:** [PROGRESS.md](PROGRESS.md) § Infra — `pqforge`, `pointycastle`, **`swissarmyknife`**, and direct **`pqcrypto` ^0.4** are in `pubspec.yaml`.

**Primitive preference (always):** **pqforge → pqcrypto → other**. Never reimplement NIST PQ (ML-KEM, ML-DSA, SLH-DSA, SHAKE) when those packages already ship it.

## Role split

| Package | Role in pqdga | Not for |
| --- | --- | --- |
| **`pqforge` ^0.3.0** | ML-KEM, ML-DSA, hybrid KEM, envelopes, profiles, key bundles | DNS label formatting |
| **`pqcrypto` ^0.4.0** (direct + override) | SHAKE128/256 XOF; **FIPS 205 SLH-DSA** (`SlhDsa` / `SlhDsaParams`) | App-level orchestration; prefer pqforge when it re-exports SLH-DSA |
| **`pointycastle` ^4.0.0** | Classical MD5/etc.; R9 **KMAC256** via `CSHAKEDigest` | ML-KEM / ML-DSA / SLH-DSA (use pqforge/pqcrypto) |
| **`swissarmyknife` ^0.1.0** | Epoch/cron, codecs, validators, Result/Either, rate limit, memoize, logging | **Crypto** |

---

## `pqforge` — API / usage matrix

Facade: `class PqForge` (`package:pqforge/pqforge.dart`).

| Concern | API (0.3.0) | PQ family use |
| --- | --- | --- |
| Profile + key bundle | `generateKeys({profile, keyId})` → `PqKeyBundle` | Lab operator/bot key setup |
| KEM keygen | `generateKemKeyPair({algorithm, seed})` | SharedSecret, Hybrid, Envelope |
| Sig keygen | `generateSignatureKeyPair` / `FromSeed` | SignatureAuthenticated, Identity |
| Encaps | `encapsulate(publicKey, {algorithm, nonce})` → `PqKemEncapsulation` | Establish/rotate `sharedSecret` |
| Decaps | `decapsulate(secretKey, ciphertext, {algorithm})` → `Uint8List` ss | Bot side of SharedSecret |
| Sign | `sign(secretKey, message, {algorithm, context})` | Auth domain\|\|epoch\|\|campaign |
| Verify | `verify(publicKey, message, signature, …)` | Bot gate before C2 trust |
| KEM-DEM envelope | `encrypt` / `assembleSealedEnvelope` / `sealToKemPublicKey` → `PqEnvelope` | EnvelopeRendezvous |
| Hybrid KEM | `PqForgeHybridKeyAgreement`, hybrid combiner exports | HybridSharedSecret |
| Hybrid sign | `PqForgeHybridSigner` (package export) | Optional hybrid authenticity |
| Combiner | `PqHybridCombiner` / cryptography extensions `deriveHybridSecretKey` | classical ‖ PQ → KDF material |
| Multi-recipient | `pqforge` multi-recipient service | Compartmented bot sets |
| Secure session | `PqForgeSecureSession` | **Post-rendezvous** lab phase only — not the DGA name generator itself |
| Algorithms | `PqKemAlgorithm`, `PqSignatureAlgorithm`, FIPS profiles | Metadata + IOC sizes |

### Lab rules for pqforge

- Tests/examples: **ephemeral** `generateKeys` / keypairs only.  
- Log **algorithm ids and lengths**, never shared secrets or signing keys.  
- Prefer explicit algorithm enums in metadata (`ML-KEM-768`, `ML-DSA-65`, etc.).

---

## `pqcrypto` — XOF expander + SLH-DSA

Transitive via `pqforge`. Primary symbols for domain expansion:

| API | Use |
| --- | --- |
| `Shake256.shake(input, length)` | One-shot expand to N bytes for labels |
| `Shake256.xof(input)` | Incremental squeeze for many domains |
| `Shake128.shake` / `.xof` | Alternate if profile requires |

**Preference:** call SHAKE through **pqcrypto** (or thin `ShakeXof`) rather than reimplementing Keccak. Direct dep is required because pqforge 0.3 does not re-export SHAKE/SLH-DSA cleanly.

**SLH-DSA (0.4+):** `SlhDsaCheckpointPqdga` calls `SlhDsa.generateKeyPair` / `sign` / `verify` with `SlhDsaParams` (default lab set `shake128f`). Size catalog `SlhDsaSizes` wraps those params — **no size-only simulation**. `dependency_overrides: pqcrypto: ^0.4.0` bridges pqforge’s `^0.3.1` pin until pqforge upgrades.

**Hybrid dual-sign:** `HybridAuthenticatedPqdga` uses `PqForgeHybridSigner` (ML-DSA + Ed25519). **Post-name AEAD:** `PostRendezvousSession` wraps `PqForgeSecureSession` — not a DGA family.

Pipeline sketch:

```text
ss || domain_sep || epoch || campaign || counter
        │
        ▼
   SHAKE256 XOF
        │
        ▼
  rejection-sample into charset → labels ≤ 63 octets; FQDN ≤ 253
```

---

## `swissarmyknife` — research plumbing (not crypto)

**Status:** **done** — `swissarmyknife: ^0.1.0` in `pubspec.yaml` (R3). Used for epoch/Result/DNS validation helpers; deeper harness utilities remain optional (PROGRESS open section).

Exports observed in 0.1.0 (non-exhaustive):

### Time / epoch

| Piece | Use in pqdga |
| --- | --- |
| `datetime_extensions` / `datetime_advanced_extensions` | Epoch buckets, week seeds, rotation windows |
| `duration_extra_extensions` | Seed rotation intervals |
| `time/` module (package layout) | Cron-like or scheduled buckets if needed |

Map Conficker-style weekly buckets and PQ `seedRotationDays` here — not ad-hoc int math scattered in generators.

### Codecs / bytes / strings

| Piece | Use |
| --- | --- |
| `uint8list_extensions` | Hex/base transforms of XOF output |
| `string_extensions` / `string_advanced_extensions` | Label assembly, case, stripping |
| `CodecPipeline` (`advanced/codec_pipeline.dart`) | bytes → charset → DNS label pipeline |
| `uri_extensions` | Optional URL-shaped rendezvous experiments |

### Validation

| Piece | Use |
| --- | --- |
| Validators / string checks (package validators + extensions) | DNS label rules: length ≤ 63, allowed charset, FQDN ≤ 253 |
| Reject path | Research “invalid DGA” mutants without emitting bad names in happy path |

### Functional / reliability

| Piece | Use |
| --- | --- |
| `Either` / `Option` (`functional/`) | Fail-closed encaps/sign — no partial domain lists on crypto failure |
| `Result`-style patterns via Either | Same |
| `Retry`, `RateLimiter`, `Throttler`, `Debouncer` (`async/`) | Simulated bot query cadence for detector training |
| `Memoize`, `TaskQueue` | Cache SHAKE blocks; bulk 50k/day family generation |
| `CircuitBreaker` | Lab harness resilience |

### Logging / config / harness

| Piece | Use |
| --- | --- |
| `logging/` | Structured events: algorithm, epoch, kem_id, sig_alg — SOC-friendly |
| Env/JSON helpers if present under `data/` / patterns | Load wordlists and **toy** campaign profiles |
| Benchmark utilities (if used) | Compare MD5 DGA vs SHAKE vs ML-KEM path cost |

### Explicit non-goals for swissarmyknife

- No ML-KEM/ML-DSA  
- No SHAKE implementation of record (use pqcrypto)  
- No replacing `pqforge` envelopes  

---

## `pointycastle` (classical + KMAC)

Already used in `DGAGenerator` for MD5 and related classical ops. Keep classical families on pointycastle unless a family needs something else. Do not use pointycastle for PQ KEMs/signatures.

**R9 KMAC256:** `lib/src/post_quantum/crypto/kmac256.dart` implements NIST SP 800-185 KMAC256 on PointyCastle `CSHAKEDigest` + `XofUtils` (`encode_string`, `bytepad`, `right_encode`). Goldens match NIST/BouncyCastle sample vectors. Prefer this lab helper over inventing a third XOF stack.

```text
KMAC256(K, X, L, S) =
  cSHAKE256(bytepad(encode_string(K), 136) || X || right_encode(L),
            L, N="KMAC", S)
```

Used by: `KmacSharedSecretPqdga`, `HybridKmacPqdga`, ratchet/hierarchy/multi-party/threshold key steps (default KDF).

---

## Dependency checklist (implementation phase)

| Action | File | PROGRESS |
| --- | --- | --- |
| Keep `pqforge: ^0.3.0` | `pubspec.yaml` | done |
| Keep `pointycastle: ^4.0.0` | `pubspec.yaml` | done |
| Add `swissarmyknife: ^0.1.0` | `pubspec.yaml` | **done** (R3) |
| Optionally add `pqcrypto` direct | `pubspec.yaml` | **done** (R3, SHAKE path) |
| Document any API drift vs 0.3.0 | this file | on upgrade |

---

## Example wiring (implemented)

```dart
// R5 — sign final domain
final sig = SignatureAuthenticatedPqdga.labEstablish();
// R9a — KMAC-bound shared secret
final kmac = KmacSharedSecretPqdga.labEstablish();
// R9g — authenticity on context, then derive
final authCtx = AuthenticatedContextPqdga.labEstablish();

final result = await PQDGAGenerator(
  PQDGAConfig(algorithm: kmac.algorithm),
).generateDomains(date, n);
// result.xof == 'KMAC256'; never log ss / sk / shares
```

Use fail-closed try/catch around encaps/sign so failures do not emit half-built domain lists.
