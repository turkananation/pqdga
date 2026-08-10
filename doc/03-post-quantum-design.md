# Post-quantum DGA design

**Implementation status:** All PQ **core** families + **all extras** + **R9 binding research ladder** (R9a–R9g) implemented.  
Live ticks: [PROGRESS.md](PROGRESS.md). Package APIs: [04-package-utilization.md](04-package-utilization.md). Hardness model: [06-adversarial-hardness.md](06-adversarial-hardness.md). Roadmap: [07-implementation-roadmap.md](07-implementation-roadmap.md) § R9.

**Novelty framing (conservative):** this project does **not** invent a new PQ primitive (ML-KEM / ML-DSA / SHAKE / KMAC are standardized). It investigates a **class of deterministic namespace constructions** bound to post-quantum shared secrets, authenticity, groups, hierarchy, and evolving key material. Prefer: *“we evaluate predictability, sync, rotation, and observability of secret-/group-bound deterministic namespaces.”* Do **not** claim “world’s first PQ DGA.”

## Goal

Model **harder rendezvous** so SOC teams can see:

1. When **precompute/sinkhole** still works (public seed + PQ hash ≠ secret).
2. When defenders must shift to **behavior, registration, EDR, key extraction**.
3. Which **network IOCs** PQ crypto leaves (ML-KEM CT sizes, ML-DSA sig sizes).

Lab only — ephemeral keys, toy campaign IDs. See [08-ethics-lab-use.md](08-ethics-lab-use.md).

## Shared pipeline (recommended)

```text
seed_material = domain_separate(
  epoch_bucket || campaign_id || counter || optional_context
)
secret_state  = ML-KEM shared secret and/or long-term key material   // pqforge
                (or empty/public for QuantumResistant baseline)
stream        = SHAKE256( secret_state || seed_material )            // pqcrypto XOF
             OR KMAC256(key=secret_state, data=seed_material, S=…)   // R9a/b (SP 800-185)
labels        = map stream → DNS-safe charset                        // swissarmyknife codecs/validators
optional      = ML-DSA.sign( canonical(label || epoch || campaign) ) // pqforge (R5)
             OR ML-DSA.sign(context) → derive from sig               // R9g authenticity axis
artifact      = PQDGAResult(domains, signatures?, kem_meta?, flags)
```

Domain separation prefixes (suggested string/byte tags): `pqdga/v1/epoch`, `pqdga/v1/label`, `pqdga/v1/sig`, `pqdga/v1/kmac-ss`, `pqdga/v1/ratchet`, …

## Intended `PQDGAResult` fields

| Field | Type (sketch) | SOC use |
| --- | --- | --- |
| `domains` | `List<String>` | Lab resolutions / blocklists |
| `generationDate` / `epoch` | time bucket | Alignment with PDNS |
| `algorithm` | string | Family id |
| `seed` | explainability (non-secret) | Docs only — never log ss |
| `predictable` | `bool` | `true` ⇒ offline precompute viable |
| `secretBound` | `bool` | Needs ss / non-public seed |
| `xof` | e.g. `SHAKE256` | Method fingerprint |
| `kemAlgorithm` | e.g. `ML-KEM-768` | Profile IOC |
| `kemCiphertextLength` | int? | Wire-size IOC |
| `sigAlgorithm` | e.g. `ML-DSA-65` | Profile IOC |
| `signatureLength` | int? | Wire-size IOC |
| `signatures` | `List<Uint8List>?` | Verify drills |
| `pubkeyFingerprint` | string? | Config extraction target |
| `metadata` | `Map` | Playbook flags, charset, campaign toy id |

---

## Family → behavior map

Paths under `lib/src/post_quantum/algorithms/`. Core five + all extras + R9 ladder **done** (not stubs).

### 1. `QuantumResistantPqdga` — baseline *quantum-resistant hash* expander

**Status:** implemented (R3). **Naming:** PQ-hardened / quantum-resistant hash-based construction — **not** a NIST PQC algorithm DGA (SHAKE is not ML-KEM/ML-DSA).

| | |
| --- | --- |
| **Mechanism** | SHAKE256 over public epoch/campaign; optional secret material flips flags |
| **pqforge / pqcrypto** | `Shake256` / XOF from `pqcrypto` |
| **secretBound** | `false` if seed public |
| **predictable** | `true` if seed public |
| **SOC lesson** | **PQ hash ≠ secret.** Date-only SHAKE DGAs remain fully precomputable. Hardness is only against short-seed brute/Grover if seeds are long/secret. |
| **Metadata** | `xof: SHAKE256`, `seed_public: true/false` |

### 2. `SharedSecretPqdga` — main hardness jump

**Status:** implemented (R4).

| | |
| --- | --- |
| **Mechanism** | Operator/bot share ML-KEM `sharedSecret` (32 B). `domain_i = DNSEncode(SHAKE256(ss \|\| date_bucket \|\| campaign \|\| i))`. Optional rotate ss via new encaps every `seedRotationDays`. |
| **pqforge** | `PqForge.generateKemKeyPair` / `generateKeys`, `encapsulate`, `decapsulate` |
| **secretBound** | `true` |
| **predictable** | `false` without ss |
| **SOC lesson** | Offline generation fails without ss. Shift to **behavior** (resolution bursts, DoH), **registration telemetry**, sinkhole after first observe — not pure precompute. |
| **Emit (non-secret)** | KEM CT length, algorithm id (`ML-KEM-768`), epoch — **never** ss in logs |

### 3. `SignatureAuthenticatedPqdga` — anti-sinkhole / anti-hijack

**Status:** implemented (R5).

| | |
| --- | --- |
| **Mechanism** | Generate name from secret or public seed; `PqForge.sign` with **ML-DSA** over `canonical(domain \|\| epoch \|\| campaign)`. Bot verifies with embedded operator pubkey before trusting C2. |
| **pqforge** | `generateSignatureKeyPair` / `FromSeed`, `sign`, `verify`; `labEstablish` helper |
| **Hardness** | Sinkhole IP alone fails if bot requires valid sig |
| **SOC lesson** | Need **key compromise**, client-side block that still fails verify, or **binary rewrite**. Research output: detached sig + pubkey fingerprint for lab drills. |
| **Flags** | `requires_signature: true`, `sig_alg` (`ML-DSA-65`), `sig_len` (3309), `pubkeyFingerprint` |
| **Emit (non-secret)** | Detached signatures list, signature length, algorithm id, SHAKE256 pubkey fingerprint — **never** sk in logs |

### 4. `IdentityBasedPqdga` — pubkey-as-namespace

**Status:** implemented (R6).

| | |
| --- | --- |
| **Mechanism** | `label = SHAKE256(ml_dsa_vk \|\| epoch_bucket \|\| i)` (or KEM pk). Anyone with vk can **predict** names; only sk holder signs (combine with signatures). |
| **pqforge** | key gen + optional sign; SHAKE for expand; `labEstablish` |
| **predictable** | `true` if vk extracted from sample (`config-seeded`) |
| **SOC lesson** | Treat embedded PQ **verification keys like classical RC4 seeds/config blocks** — extraction restores precompute for names. |
| **Flags** | `needs_config_extract: true`; optional `requires_signature` |

### 5. `DecentralizedPqdga` — beyond pure DNS thinking

**Status:** implemented (R6).

| | |
| --- | --- |
| **Mechanism** | Content-addressed id: `SHAKE256(vk \|\| epoch)` → base32/hex/ldh label **or** non-DNS `pqdga:` handle. |
| **encoding** | `base32` (default), `hex`, `ldh`; `dnsMode` toggles FQDN vs abstract |
| **SOC lesson** | Pure DNS RPZ insufficient; need PDNS + alternative-channel monitoring analogies in playbooks (P7). |

---

## Extra families

PROGRESS § PQ — extras (**all done** R6/R8).

| Family | Mechanism | Hardness | Defender shift |
| --- | --- | --- | --- |
| **HybridSharedSecretPqdga** (**done** R6) | classical ss ‖ ML-KEM via `PqForgeCombiner` → SHAKE | Survive break of classical **or** PQ alone, not both | Same as shared secret; document hybrid |
| **EnvelopeRendezvousPqdga** (**done** R8) | Short domain id; real config in ML-KEM-DEM envelope | Name is decoy; payload is crypto | Inspect payload crypto / sizes, not only FQDN |
| **RateLimitedPqdga** (**done** R8) | Same crypto seed; emit ≤ N names/hour | Low volume evades sinkhole racing | Longer observation windows |
| **MultiRecipientPqdga** (**done** R8) | Primary ML-KEM ss + additional recipient wraps | Compartmentation (wrap model) | Partial takedown resilience — **not** multi-party/threshold joint derivation |

**SLH-DSA checkpoints (post-R9, done):** `SlhDsaCheckpointPqdga` uses **real** FIPS 205 `pqcrypto.SlhDsa` (not a size simulation). Default lab set `SLH-DSA-SHAKE-128f` (~17 KB sigs) → excellent passive size IOCs vs ML-DSA. Prefer pqforge if/when it re-exports SLH-DSA; until then hook pqcrypto directly (override `^0.4.0`).

---

## R9 — Cryptographic binding research ladder

**Status:** implemented (2026-08-09). Historical project IDs R0–R8 stay fixed; this is an **add-on** series.

Research question spanning the ladder:

> What new properties emerge when deterministic naming/rendezvous constructions are progressively bound to post-quantum cryptographic primitives, identities, groups, and evolving key material?

| ID | Type | Mechanism | `secretBound` / notes | SOC / research lesson |
| --- | --- | --- | --- | --- |
| **R9a** `KmacSharedSecretPqdga` | Secret-bound expand | Same ML-KEM ss as R4; **KMAC256**(K=ss, X=context, S=custom) instead of absorb-all SHAKE | `true` | Keyed SP 800-185 domain separation vs raw XOF; compare domain sets to SharedSecret |
| **R9b** `HybridKmacPqdga` | Hybrid + keyed expand | classical ‖ ML-KEM combiner → session → **KMAC256** | `true` | Migration-period: need both classical and PQ material **and** keyed expand |
| **R9c** `RatchetingPqdga` | Epoch evolution | `root → ek_0 → ek_1 → …`; labels from current epoch key | `true` | Delete-forward experiment: later ek must not reconstruct earlier names if chain is one-way — **do not claim FS** until analyzed |
| **R9d** `HierarchicalPqdga` | Delegation tree | Path segments derive child keys; leaf expands labels | `true` | Compartment: sibling paths differ; leaf-only after root delete |
| **R9e** `MultiPartyPqdga` | Group-bound (all-of-n) | Independent party secrets → binding key → labels | `true` | **≠** MultiRecipient wrap; missing any required party fails generation |
| **R9f** `ThresholdPqdga` | Group-bound (k-of-n) | Lab deal shares from master; ≥k combine → binding key | `true` | **≠** MultiRecipient; **≠** production TSS — ops/resilience experiment only |
| **R9g** `AuthenticatedContextPqdga` | Authenticity axis | Sign **context** (sep‖epoch‖campaign‖counter) with ML-DSA; derive from sig (± optional secret) | auth-only: `false`; +secret: `true` | Authenticity ≠ confidentiality; distinct from R5 (sign final domain string) |

**Helper:** `Kmac256` (`lib/src/post_quantum/crypto/kmac256.dart`) — PointyCastle `CSHAKEDigest`, goldens vs NIST/BouncyCastle KMAC256 samples.

**Metadata:** `binding_mode`, `binding_ladder` (`R9a`…`R9g`), `kdf`/`xof`, playbook flags; never log keys/ss/shares.

---

## Config knobs (implemented)

Fields used across PQ algorithm configs / `PQDGAConfig`:

| Knob | Role |
| --- | --- |
| `minDomainLength` / `maxDomainLength` | On `PQDGAConfig` |
| `seedRotationDays` | Epoch / ss rotation (`EpochBucket`) |
| `campaignId` | Toy string only in examples |
| `charset` / encoding | base32, hex, LDH map of XOF/KMAC |
| `kemAlgorithm` / signature algorithm enums | Profile selection + IOC sizes |
| `requireSignature` / sign flags | SignatureAuthenticated + Identity optional sign |
| Hybrid classical + PQ material | `HybridSharedSecretPqdga` / `HybridKmacPqdga` |
| R9 path/ratchet/share knobs | hierarchy path, epoch index, party secrets, k-of-n |

## Implementation order (PQ slice) — historical

Matches roadmap R2–R9 (**all delivered**):

1. `PQDGAResult` + generator + registry dispatch  
2. QuantumResistant (SHAKE) — teaches false confidence  
3. SharedSecret (ML-KEM) — real hardness  
4. SignatureAuthenticated (ML-DSA)  
5. Identity + Hybrid + Decentralized + extras  
6. Binding ladder R9a–R9g (KMAC, ratchet, hierarchy, multi-party, threshold, auth-context)  

Definition of done: [PROGRESS.md](PROGRESS.md).

### Post-R9 library-hook extras (done)

| Family / helper | Primitive source | Role |
| --- | --- | --- |
| `LexicalSharedSecretPqdga` | pqforge ML-KEM + SHAKE/KMAC + `LexicalLabelCodec` | Secret-bound **pronounceable/Markov/dictionary** labels (H5) |
| `SlhDsaCheckpointPqdga` | **pqcrypto** `SlhDsa` / `SlhDsaParams` | Real FIPS 205 multi-KB epoch seals + size IOC catalog |
| `HybridAuthenticatedPqdga` | **pqforge** `PqForgeHybridSigner` | ML-DSA + Ed25519 dual-sign (`requireBoth`) |
| `PostRendezvousSession` | **pqforge** `PqForgeSecureSession` | Post-name AEAD lab phase (**not** a DGA) |

**Policy:** pqforge → pqcrypto → other. Do not reimplement NIST PQ already present in those packages.
