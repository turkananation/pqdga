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
