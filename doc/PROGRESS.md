# Progress tracker

**Last updated:** 2026-08-09 (post-R9 extras: real SLH-DSA via pqcrypto 0.4 + lexical/hybrid-auth + library hooks)  
**Source of truth** for done vs pending. Narrative design lives in sibling docs; tick boxes live here.

## Legend

| Mark | Meaning |
| --- | --- |
| `- [x]` | Done — meets definition of done below |
| `- [ ]` | Todo / not started |
| Status words in notes | `done` \| `partial` \| `todo` \| `blocked` \| `wontfix` |

**Rule:** update this file in the same change as the deliverable. Stubs ≠ done.

## Summary counts (2026-08-09)

| Category | Done | Total | Notes |
| --- | ---: | ---: | --- |
| Classical malware-style (implemented set) | 10 | 10 | Core set complete |
| Classical generics | 4 | 4 | Complete |
| Classical P0 | 5 | 5 | Locky, QakBot, Suppobox, Banjori, Ranbyus |
| Classical P1 planned | 6 | 6 | Ramnit…Emotet-era **done** |
| Classical P2 planned | 5 | 5 | Kraken…Proslikefan **done** |
| Research generics | 6 | 6 | Markov, IDN, oracle, multi-channel, fast-flux, nested |
| PQ core (generator + result + 5 families) | 7 | 7 | All core families + result/generator |
| PQ extras | 4 | 4 | Hybrid + Envelope + RateLimited + MultiRecipient |
| PQ binding ladder (R9a–R9g + KMAC helper) | 8 | 8 | KMAC256 + 7 constructions |
| Infra / deps | 4 | 4 | pqforge, pointycastle, swissarmyknife, direct pqcrypto |
| SOC code artifacts | 7 | 7 | SocFeatures + classical metadata + hardness + classical IOC |
| Docs (this phase) | 11 | 11 | Full `/doc` + root README (overview refreshed) |

> Totals are checklist rows below. Recompute the table when adding rows.

---

## Definition of done

### Classical family

- [x] Config class under `lib/src/classical/algorithms/<name>_dga.dart` extending `DGAAlgorithm`
- [x] Generator path in `DGAGenerator` (or post-refactor registry)
- [x] Export in `lib/src/pqdga_base.dart`
- [x] Golden test: fixed date (+ config) → fixed domain list
- [x] Metadata useful to SOC (charset, length, seed packing, constants)
- [x] Catalog row + SOC look-for note in `doc/02-classical-families.md` (or pointer)

### PQ family

- [x] Non-stub config + real generation path in `PQDGAGenerator`
- [x] Uses documented `pqforge` / `pqcrypto` / `swissarmyknife` pieces
- [x] `PQDGAResult` (or equivalent) with `predictable`, `secretBound`, kem/sig metadata
- [x] Golden or property tests with **ephemeral** keys only
- [x] SOC lesson documented in `doc/03-post-quantum-design.md`

### Infra

- [x] Dependency declared and resolvable; usage documented in `doc/04-package-utilization.md`

### SOC artifact

- [x] Code or structured doc that emits features / playbook flags / IOC templates consumed by lab tooling

### Doc

- [x] File present, linked from `doc/README.md`, consistent with PROGRESS baseline

---

## Docs (this phase)

- [x] `doc/README.md` — index + ethics one-liner + tracker rule
- [x] `doc/PROGRESS.md` — this file
- [x] `doc/00-overview.md`
- [x] `doc/01-architecture.md`
- [x] `doc/02-classical-families.md`
- [x] `doc/03-post-quantum-design.md`
- [x] `doc/04-package-utilization.md`
- [x] `doc/05-soc-detection-mitigation.md`
- [x] `doc/06-adversarial-hardness.md`
- [x] `doc/07-implementation-roadmap.md`
- [x] `doc/08-ethics-lab-use.md`
- [x] Root `README.md` — package blurb, ethics banner, links to `/doc`

---

## Classical — implemented malware-style

- [x] Conficker — `lib/src/classical/algorithms/conficker_dga.dart`
- [x] Necurs — `lib/src/classical/algorithms/necurs_dga.dart`
- [x] Pushdo — `lib/src/classical/algorithms/pushdo_dga.dart`
- [x] Rovnix — `lib/src/classical/algorithms/rovnix_dga.dart`
- [x] CryptoLocker — `lib/src/classical/algorithms/cryptolocker_dga.dart`
- [x] Bamital — `lib/src/classical/algorithms/bamital_dga.dart`
- [x] Tinba — `lib/src/classical/algorithms/tinba_dga.dart`
- [x] Murofet — `lib/src/classical/algorithms/murofet_dga.dart`
- [x] Simda — `lib/src/classical/algorithms/simda_dga.dart`
- [x] Matsnu — `lib/src/classical/algorithms/matsnu_dga.dart`

## Classical — implemented generics

- [x] Time-based — `lib/src/classical/algorithms/time_based_dga.dart`
- [x] Dictionary-based — `lib/src/classical/algorithms/dictionary_based_dga.dart`
- [x] Arithmetic — `lib/src/classical/algorithms/arithmetic_dga.dart`
- [x] Permutation — `lib/src/classical/algorithms/permutation_dga.dart`

## Classical — P0

- [x] Locky — `lib/src/classical/algorithms/locky_dga.dart` (+ generator, export, golden test)
- [x] QakBot / Qbot — `lib/src/classical/algorithms/qakbot_dga.dart` (+ MT19937 path, golden test)
- [x] Suppobox-style word DGA — `lib/src/classical/algorithms/suppobox_dga.dart` (+ fixture wordlist)
- [x] Banjori — `lib/src/classical/algorithms/banjori_dga.dart`
- [x] Ranbyus — `lib/src/classical/algorithms/ranbyus_dga.dart` (May variant)

## Classical — P1

- [x] Ramnit — `lib/src/classical/algorithms/ramnit_dga.dart` (+ golden)
- [x] Nymaim / GozNym-ish — `lib/src/classical/algorithms/nymaim_dga.dart` (+ golden)
- [x] Shiotob / Urlzone — `lib/src/classical/algorithms/shiotob_dga.dart` (+ golden)
- [x] Pykspa / Symmi — `lib/src/classical/algorithms/pykspa_dga.dart` (+ golden)
- [x] Vawtrak / Neverquest — `lib/src/classical/algorithms/vawtrak_dga.dart` (+ golden)
- [x] Emotet/Geodo-era (historical) — `lib/src/classical/algorithms/emotet_dga.dart` (+ golden)

## Classical — P2

- [x] Kraken / Bobax — `lib/src/classical/algorithms/kraken_dga.dart` (+ golden)
- [x] Torpig / Mebroot — `lib/src/classical/algorithms/torpig_dga.dart` (+ golden)
- [x] CoreBot — `lib/src/classical/algorithms/corebot_dga.dart` (+ golden)
- [x] DirCrypt / PadCrypt — `lib/src/classical/algorithms/dircrypt_dga.dart` (+ golden)
- [x] Proslikefan — `lib/src/classical/algorithms/proslikefan_dga.dart` (+ golden)

## Research generics (classical-looking / hybrid research)

- [x] Markov / n-gram language-model DGA — `lib/src/classical/algorithms/markov_dga.dart`
- [x] Homoglyph / IDN / punycode DGA — `lib/src/classical/algorithms/idn_dga.dart`
- [x] Seed-from-public-oracle — `lib/src/classical/algorithms/oracle_seed_dga.dart`
- [x] Multi-channel rendezvous labels — `multi_channel_dga.dart` + `common/multi_channel_codec.dart`
- [x] Fast-flux / double-flux schedule coupling — `fast_flux_dga.dart` + `common/flux_schedule.dart`
- [x] Wildcard / subdomain nesting — `lib/src/classical/algorithms/nested_label_dga.dart`

---

## PQ — core

- [x] `PQDGAGenerator` — `lib/src/post_quantum/pqdga_generator.dart` (registry; core + extras + R9 ladder)
- [x] `PQDGAResult` — `lib/src/post_quantum/pqdga_result.dart` (`predictable`, `secretBound`, kem/sig fields, epoch)
- [x] QuantumResistantPqdga (SHAKE baseline) — quantum-resistant **hash-based** construction; **not** a NIST PQC algorithm DGA (+ golden tests)
- [x] SharedSecretPqdga (ML-KEM ss → SHAKE) — primary secret-bound construction (+ golden + encaps/decaps)
- [x] SignatureAuthenticatedPqdga (ML-DSA over final domain) — (+ golden domains, verify drills, labEstablish)
- [x] IdentityBasedPqdga — (+ vk namespace goldens, optional sign)
- [x] DecentralizedPqdga — (+ base32 DNS + abstract ids)

## PQ — extras

- [x] HybridSharedSecretPqdga — classical ‖ ML-KEM via `PqForgeCombiner` → SHAKE (+ golden + combiner round-trip)
- [x] EnvelopeRendezvousPqdga — KEM-DEM envelope; domain as short decoy id (+ golden + payload IOC)
- [x] Rate-limited adaptive DGA — `RateLimitedPqdga` emit ≤ N names/hour (+ cap golden)
- [x] Multi-recipient compartmentation — `MultiRecipientPqdga` (one DEM key wrapped for N recipients) — **not** threshold/multi-party joint derivation

## PQ — binding research ladder (R9)

Conservative novelty framing: **construction class** research (secret-/group-/evolution-bound deterministic namespaces), **not** a new cryptographic primitive.

- [x] `Kmac256` helper — NIST SP 800-185 on PointyCastle cSHAKE (`lib/src/post_quantum/crypto/kmac256.dart`) + sample vectors
- [x] R9a `KmacSharedSecretPqdga` — ML-KEM ss → **KMAC256** expand (+ golden; differs from SHAKE SharedSecret)
- [x] R9b `HybridKmacPqdga` — hybrid combiner session → **KMAC256** (+ golden; differs from Hybrid SHAKE)
- [x] R9c `RatchetingPqdga` — chained epoch keys; delete-forward experiment (**no FS security claim**)
- [x] R9d `HierarchicalPqdga` — root→region→team path derivation; sibling compartment drill
- [x] R9e `MultiPartyPqdga` — all independent secrets required for binding key (**≠ MultiRecipient**)
- [x] R9f `ThresholdPqdga` — lab k-of-n share deal/combine (**≠ MultiRecipient**; not production TSS)
- [x] R9g `AuthenticatedContextPqdga` — ML-DSA over **context** then derive; authenticity vs confidentiality axis

---

## Infra / dependencies

- [x] `pqforge: ^0.3.0` — `pubspec.yaml`
- [x] `pointycastle: ^4.0.0` — classical MD5/etc. + R9 KMAC256 (`CSHAKEDigest`)
- [x] `swissarmyknife: ^0.1.0` — `pubspec.yaml` (epoch, Result/validators)
- [x] Direct `pqcrypto: ^0.4.0` (override) — SHAKE + FIPS 205 SLH-DSA; prefer pqforge when it exposes SLH-DSA

## Architecture / quality

- [x] Dispatch refactor — classical + PQ `registry` maps (`DGAGenerator` / `PQDGAGenerator`)
- [x] Classical golden tests for P0 families — `test/pqdga_test.dart` (baseline families still smoke-tested)
- [x] Classical golden tests coverage pass for **all** pre-P0 implemented families
- [x] PQ lab examples print IOC templates (CT/sig sizes, charset) beside domains
- [x] Classical lab examples print features / IOC / hardness beside domains
- [x] Feature-vector / batch metadata helpers for SOC notebooks — `lib/src/common/soc_features.dart`
- [x] R9 binding ladder goldens + registry coverage in `test/pqdga_test.dart`
- [x] Classical SOC metadata contract tests — baseline + generics + P0 + hardness/IOC helpers

## SOC artifacts

- [x] Per-domain feature extraction helper (length, entropy hooks, ratios, TLD, depth) — `SocFeatures.forDomain`
- [x] Batch features (domains/day, expected NX ratio hooks) — `SocFeatures.forBatch` / `fromDgaResult` / `fromPqdgaResult`
- [x] Predictability / hardness rating emitted on every result — PQ fields + **all** classical metadata; batch helpers surface them
- [x] Mitigation playbook flags in metadata (`sinkhole_precompute`, `needs_lexical_model`, …) — **all classical families** + PQ + R9 `binding_mode` / `binding_ladder`
- [x] Classical SOC metadata builder — `ClassicalSocMetadata` (`lib/src/common/classical_soc_metadata.dart`)
- [x] Classical IOC templates — `SocFeatures.iocTemplateFromDga` (symmetric to PQ)
- [x] Hardness H1–H7 scorecard emission — `HardnessScorecard` (`lib/src/common/hardness_scorecard.dart`); example prints summary lines

---

## Roadmap phase IDs (see `07-implementation-roadmap.md`)

| ID | Phase | Status |
| --- | --- | --- |
| R0 | Documentation (`/doc` + README) | **done** (2026-08-08) |
| R1 | Classical P0 families | **done** (2026-08-08) |
| R2 | Dispatch refactor + `PQDGAResult` | **done** (2026-08-08) |
| R3 | QuantumResistant (SHAKE) | **done** (2026-08-08) |
| R4 | SharedSecret (ML-KEM) | **done** (2026-08-08) |
| R5 | SignatureAuthenticated (ML-DSA) | **done** (2026-08-09) |
| R6 | Identity + Hybrid + Decentralized | **done** (2026-08-09) |
| R7 | SOC polish (features, IOC templates) | **done** (2026-08-09) |
| R8 | Research generics + P1/P2 + PQ extras | **done** (2026-08-09) |
| R9 | Cryptographic binding research ladder (R9a–R9g) | **done** (2026-08-09) |

---

## Open / deferred (post R9)

Single backlog for work **after** roadmap completion. Do not re-open R0–R9 rows for these.

### Done in post-R9 polish (2026-08-09)

- [x] Doc hygiene: refresh `00-overview.md` baseline; scrub stub/future language in 03/04/07
- [x] Classical metadata + IOC parity for **all** earlier DGAs (baseline + generics + P0–P2 + research)
- [x] Hardness H1–H7 structured score emission (`HardnessScorecard`)
- [x] Classical example path prints features / IOC / hardness beside domains

### Done in post-R9 library-hook extras (2026-08-09)

**Primitive policy:** prefer **pqforge** → **pqcrypto** → other. Never reimplement NIST PQ already shipped by those libs.

- [x] Bump **pqcrypto ^0.4.0** (`dependency_overrides` vs pqforge 0.3’s `^0.3.1`) for FIPS 205 SLH-DSA + existing SHAKE
- [x] `SlhDsaCheckpointPqdga` — **real** `pqcrypto.SlhDsa` sign/verify checkpoints (default `shake-128f`); sizes from `SlhDsaParams` catalog (`slh_dsa_sizes.dart`)
- [x] `LexicalSharedSecretPqdga` — ML-KEM ss (pqforge) + SHAKE/KMAC → markov/dictionary/pronounceable labels (`LexicalLabelCodec`)
- [x] `HybridAuthenticatedPqdga` — dual-sign via **`PqForgeHybridSigner`** (ML-DSA + Ed25519, `requireBoth`)
- [x] `PostRendezvousSession` — AEAD lab phase via **`PqForgeSecureSession`** (not a DGA; post-name channel)
- [x] Lab surfaces: `DetectorNotebook`, `BindingAnalysis`, `LabHarness`, `LiteratureCorpus`, `NotebookConsumer`, `SlhDsaProvider`
- [x] Generator registry + public exports for all of the above
- [x] Tests green (`dart test` — 71 cases) including real SLH-DSA seal + hybrid dual verify

### Done in post-R9 analysis & fidelity pass (2026-08-09)

- [x] P1/P2 **literature-perfect re-keys** vs baderj corpus (Ramnit, Nymaim, Shiotob, Pykspa precursor, Vawtrak, Kraken, Corebot, DirCrypt, Proslikefan); Emotet/Torpig remain documented research-models — `literature_prng.dart`, goldens in `doc/literature_goldens.json` + tests
- [x] Deeper `swissarmyknife` harness — cron buckets/`CronExpression`, `CodecPipeline` bulk, `SafeJson` rows, `DateRange`, structured `Log` capture, rate limiter — `LabHarness`
- [x] Binding-ladder **analysis notebooks** (writeups): `doc/notebooks/` R9a/c/d/e-f + `BindingAnalysis.writeups()`
- [x] Notebook/detector consumers — `NotebookConsumer` wires `DetectorNotebook`, `HardnessScorecard`, SLH size IOC catalog, literature notes, codec pipeline
- [x] SLH-DSA provider preference gate — `SlhDsaProvider` (pqforge → pqcrypto); still blocked on pqforge exposing SLH-DSA
- [x] PROGRESS / CHANGELOG / literature corpus synced

### Still optional / upstream-blocked

- [ ] When **pqforge** exposes SLH-DSA, flip `SlhDsaProvider.pqforgeExposesSlhDsa` and drop `dependency_overrides` if versions align
- [ ] Keep PROGRESS in sync with any future families

### Research claims that stay open until analyzed

- [ ] R9c `RatchetingPqdga` — **no forward-secrecy claim** without threat model
- [ ] R9f `ThresholdPqdga` — **not production TSS**
- [ ] Novelty / “first PQ DGA” — explicitly **do not claim**; construction-class framing only
- [ ] MultiRecipient vs MultiParty/Threshold distinction — keep; no conflation

### Intentionally out of scope (wontfix)

- [x] wontfix: PQRP productization rush
- [x] wontfix: live multiparty protocols / live operator secrets
- [x] wontfix: operational C2 / unauthorized sinkholing
- [x] wontfix: weaponized exploit paths
