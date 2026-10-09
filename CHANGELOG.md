## 0.2.0

### Fixed

**The package did not compile.** Commit 3d9ba80 ("Use eported libraries and drop
external libraries", 2026-08-11) replaced
`import 'package:pqcrypto/pqcrypto.dart'` with `import 'package:pqforge/pqforge.dart'`
across the SLH-DSA checkpoint path and `shake_xof.dart`.

That commit was right about one thing and wrong about another:

- **Right:** `pqforge` does export its own vocabulary — `PqKemAlgorithm`,
  `PqSignatureAlgorithm`, `PqSlhDsaAlgorithm`, `PqKemPrimitives`,
  `PqSignaturePrimitives`. Importing `pqforge` instead of reaching into
  `pqcrypto/src/` is the correct layering for that.
- **Wrong:** `pqforge` does **not** re-export `pqcrypto`'s implementation types.
  Its barrel says so explicitly: "Lattice primitives and PointyCastle types are
  **not** re-exported from this library. Import `package:pqcrypto/pqcrypto.dart`
  ... when you need those APIs directly."

So `SlhDsa`, `SlhDsaParams`, `Shake128` and `Shake256` were undefined, and
`dart analyze` reported 38 issues including 20+ hard errors. Verified against
the live package: importing only `package:pqforge/pqforge.dart` leaves all five
symbols undefined, while `PqKemAlgorithm`, `PqSlhDsaAlgorithm`,
`PqKemPrimitives` and `PqSignaturePrimitives` do resolve.

Restores `import 'package:pqcrypto/pqcrypto.dart'` in the four affected files
and declares `pqcrypto: ^0.4.2` as a direct dependency, since `pqdga` calls the
FIPS 205 implementation directly and that call is real. `pqforge` stays
imported wherever its own vocabulary is the right layer.

`dart analyze` now reports **no issues**, and the full suite runs: 91 tests pass.

### Added

- `SharedSecretLabSession.dispose()` — wipes `kemSecretKey` and `sharedSecret`.
- `IdentityBasedLabSession.dispose()` — wipes `signatureSecretKey`.

Both classes hold live private key material in public fields and documented it
as "do not log", but neither offered any way to clear it. `kemPublicKey`,
`kemCiphertext` and `identityPublicKey` are deliberately **not** wiped: they are
public artifacts.

### Changed

- Replaced the two hand-rolled wipes
  (`sessionKey.fillRange(0, sessionKey.length, 0)` and the equivalent in
  `MultiRecipientPqdga`) with `secureZero` from `package:zeroize`.
  `fillRange(0, n, 0)` is exactly the loop that can be optimised away: it carries
  no `@pragma('vm:never-inline')` and no opaque read anchor, so Dead Store
  Elimination can drop the writes in an AOT build. `secureZero` is
  `vm:never-inline` and anchors the writes, so it survives.
- Added `package:zeroize` as a dependency (pure Dart, one transitive dependency).

Best-effort erasure, not a memory-erasure guarantee: pure Dart cannot stop the GC
from copying a buffer and has no `mlock` equivalent.

### Added

- **`LabKeySink`** — an optional sink that receives generated key material as a
  lab session is established. `SharedSecretPqdga.labEstablish` and
  `IdentityBasedPqdga.labEstablish` take a `keySink` argument; every key they
  generate is handed over with its name, algorithm, and whether it is secret.

  ```dart
  final session = SharedSecretPqdga.labEstablish(
    keySink: CallbackLabKeySink(
      (key) => keystore.put(metadataFor(key), key.bytes, unlock),
      (count) => print('stored $count keys'),
    ),
  );
  ```

  Two implementations: `InMemoryLabKeySink` for a caller that wants to inspect
  the keys, and `CallbackLabKeySink` as the integration seam.

  Passing no sink changes nothing and writes nothing anywhere.

- **No filesystem sink, deliberately.** pqdga does not write key bytes to disk
  and offers no API that does. A plaintext key file is a worse custody story
  than not persisting at all, because it looks durable while being unprotected.
  **Custody belongs to `pqkeystore`**: wire `CallbackLabKeySink` to
  `PqKeystore.put` and the key is sealed by the selected provider before it
  touches storage. The sink is handed the session's own buffers, so it must copy
  if it needs to keep them — and `dispose()` still reaches the original.

  The absence is asserted: `test/lab_key_sink_test.dart` has no filesystem test,
  because there is nothing to test.

- 7 tests for the seam, including that a throwing callback aborts establishment
  rather than silently losing a key, and that a sink receives the same buffer
  the session later wipes.

### Note

- **pubspec `description` shortened to 153 characters.** It was 271, outside
  pub.dev's 20-180 scoring window. The full framing of the research programme
  remains in `README.md` and `doc/00-overview.md`; the description now says what
  the package is for.

### Note

`0.1.1` is published on pub.dev from a commit where this package did not
compile. Consider a `0.1.2` yank or an explicit note; this PR does not do it.

## 0.1.1

- Use exported `pqforge` SHAKE256 instead of direct import from `pqcrypto` (R3).

## 0.1.0

- Initial version.
- Added defensive-research documentation under `doc/` (overview, architecture, classical catalog, PQ design, package utilization, SOC playbooks, adversarial hardness, implementation roadmap, ethics) and living progress tracker `doc/PROGRESS.md`.
- Root `README.md` points to `doc/` with authorized-use banner.
- **R1 classical P0:** Locky, QakBot, Suppobox-style, Banjori, Ranbyus configs + generator paths, public exports, SOC metadata, and golden tests (`test/pqdga_test.dart`, Suppobox wordlist fixture).
- **R2:** Classical + PQ registry dispatch; `PQDGAResult` (`predictable`/`secretBound`/kem/sig fields); `PredictabilityClass` enum.
- **R3:** `QuantumResistantPqdga` SHAKE256 path via `pqforge`; `swissarmyknife` epoch/Result DNS helpers; deps `pqforge` + `swissarmyknife`; golden tests + example IOC lesson (“PQ hash ≠ secret”).
- **R4:** `SharedSecretPqdga` ML-KEM ss → SHAKE labels via `pqforge` encaps/decaps; `labEstablish` helper; `predictable=false`/`secretBound=true` + KEM IOC metadata; golden + round-trip tests; example demo.
- **R5:** `SignatureAuthenticatedPqdga` ML-DSA sign/verify over canonical domain‖epoch‖campaign; detached sigs + pubkey fingerprint on `PQDGAResult`; `requires_signature` P5 playbook flags; golden domains + verify/tamper drills; example lab verify.
- **R6:** `IdentityBasedPqdga` (vk namespace ± optional sign), `HybridSharedSecretPqdga` (`PqForgeCombiner` classical‖ML-KEM), `DecentralizedPqdga` (base32 DNS + abstract ids); goldens + registry complete for PQ core.
- **R7:** `SocFeatures` per-domain/batch feature extraction + IOC template helper; example prints features/IOC beside domains; SOC docs/PROGRESS updated.
- **R8:** Research generics (Markov, IDN/punycode, oracle-seed, multi-channel, fast-flux schedule, nested labels); classical P1/P2 malware-style families; PQ extras (`EnvelopeRendezvousPqdga`, `RateLimitedPqdga`, `MultiRecipientPqdga`); pre-P0 golden coverage.
- **R9 binding research ladder:** NIST SP 800-185 `Kmac256` helper; `KmacSharedSecretPqdga`, `HybridKmacPqdga`, `RatchetingPqdga`, `HierarchicalPqdga`, `MultiPartyPqdga`, `ThresholdPqdga`, `AuthenticatedContextPqdga`; registry + goldens; docs distinguish MultiRecipient wrap vs multi-party/threshold joint derivation; conservative novelty framing (construction class, not new primitive); roadmap R0–R9 complete.
- **Post-R9 polish:** `ClassicalSocMetadata` + full SOC metadata/`playbook_flags`/`soc_lesson` on **all** classical families; `SocFeatures.iocTemplateFromDga`; `HardnessScorecard` H1–H7 emission; example classical+PQ IOC/hardness lines; docs hygiene (`00-overview` baseline, open/deferred section in PROGRESS, scrub stub language in 03/04/07).
- **Post-R9 library hooks:** bump `pqforge` to **^0.4.0** (dependency override while pqforge 0.3 pins ^0.3.1); **real FIPS 205** `SlhDsaCheckpointPqdga` via `pqcrypto.SlhDsa` (sizes from `SlhDsaParams`); `LexicalSharedSecretPqdga` (ML-KEM + lexical codec); `HybridAuthenticatedPqdga` via `PqForgeHybridSigner`; `PostRendezvousSession` via `PqForgeSecureSession`; lab surfaces `DetectorNotebook` / `BindingAnalysis` / `LabHarness` / `LiteratureCorpus`; primitive policy **pqforge → pqcrypto → other** (no reimplementation of shipped NIST PQ).
- **Post-R9 analysis & fidelity:** P1/P2 literature-perfect re-keys against baderj (`literature_prng`, goldens); deeper `LabHarness` (cron, CodecPipeline bulk, Log capture); binding-ladder notebooks under `doc/notebooks/`; `NotebookConsumer` for DetectorNotebook/HardnessScorecard/SLH IOC catalog; `SlhDsaProvider` preference gate (still pqcrypto until pqforge ships SLH-DSA).
