# Adversarial hardness model

Design goals for making rendezvous **super hard**, always paired with blue-team counters.  
Implementation maps to PQ families in [03-post-quantum-design.md](03-post-quantum-design.md) and playbooks in [05-soc-detection-mitigation.md](05-soc-detection-mitigation.md).

**Rule:** every hardness feature documented or coded must name its counter. This keeps the project defensive-first.

## Scorecard (per family)

Rate `0` (absent) – `2` (strong) in design notes and **emitted** via `HardnessScorecard` (lab design ratings, not proofs):

| ID | Goal | Adversary intent |
| --- | --- | --- |
| H1 | Unpredictability without secret | Offline domain gen fails |
| H2 | Unforgeability of C2 | Cannot hijack name→trust without sk |
| H3 | Forward secrecy of rendezvous | Old ss useless after rotation |
| H4 | Hybrid survival | Classical **or** PQ break alone insufficient |
| H5 | Low observability | Entropy/lexical detectors struggle |
| H6 | Channel agility | DNS RPZ incomplete |
| H7 | Anti-sinkhole | Sinkhole IP ≠ successful C2 |

---

## H1 — Unpredictability without secret

| | |
| --- | --- |
| **Mechanism** | ML-KEM shared secret (or long non-public seed) bound into SHAKE or **KMAC256** input (`SharedSecretPqdga`, `KmacSharedSecretPqdga`, Hybrid*, MultiParty, Threshold, Hierarchical leaf) |
| **Not sufficient** | SHAKE/MD5 over public date alone (`QuantumResistant` public mode, classical trivial); authenticity-only context sig without secret (`AuthenticatedContext` auth-only) |
| **Blue-team counters** | Binary/config extraction of ss/seed/shares; behavioral EDR; first-seen PDNS; registration/CT; traffic analysis; multi-party ops disruption |

## H2 — Unforgeability of C2

| | |
| --- | --- |
| **Mechanism** | ML-DSA over `canonical(domain \|\| epoch \|\| campaign)`; bot verifies before trust (`SignatureAuthenticatedPqdga`) |
| **Blue-team counters** | Recover signing key; rewrite binary to skip verify; block resolution/process before app-level trust; hunt pubkey fingerprint |

## H3 — Forward secrecy of rendezvous

| | |
| --- | --- |
| **Mechanism** | Fresh encaps / ss per epoch (`seedRotationDays`); **R9c** `RatchetingPqdga` chains epoch keys for a delete-forward **experiment** |
| **Claim discipline** | Do **not** assert cryptographic forward secrecy for R9c until analyzed under an explicit threat model |
| **Blue-team counters** | Historical ss decrypts **past** windows if logged; seize current epoch material; continuous first-seen |

## H4 — Hybrid survival

| | |
| --- | --- |
| **Mechanism** | X25519 + ML-KEM via `PqForgeHybridKeyAgreement` / combiner — need both breaks |
| **Blue-team counters** | Same as H1 operationally; document hybrid in malware config IOCs; size/algorithm fingerprints differ from pure ML-KEM |

## H5 — Low observability

| | |
| --- | --- |
| **Mechanism** | Dictionary / Markov encoding of XOF output; pronounceable labels; IDN |
| **Blue-team counters** | Lexical/LM models; wordlist detectors; IDN monitoring; batch graph features — **not** entropy-only rules |

## H6 — Channel agility

| | |
| --- | --- |
| **Mechanism** | Same XOF stream → DNS label **or** DoH path token **or** abstract non-DNS id (`DecentralizedPqdga`, multi-channel generic) |
| **Blue-team counters** | Multi-channel telemetry; correlate encodings; do not rely on recursive DNS alone |

## H7 — Anti-sinkhole

| | |
| --- | --- |
| **Mechanism** | H2 signatures + optional pinned AEAD session after rendezvous (`PqForgeSecureSession` as **post-DGA** lab phase) |
| **Blue-team counters** | Key compromise; client isolation; binary modification; legal/takedown on operator keys; sinkhole still disrupts naive bots without verify |

---

## Family × hardness (target design)

| Family | H1 | H2 | H3 | H4 | H5 | H6 | H7 | Notes |
| --- | :-: | :-: | :-: | :-: | :-: | :-: | :-: | --- |
| Classical date DGAs | 0 | 0 | 0 | 0 | 0–1 | 0 | 0 | Training set; precompute wins |
| Dictionary / Markov | 0 | 0 | 0 | 0 | 2 | 0 | 0 | Observability only |
| Oracle-seed | 1 | 0 | 1* | 0 | 0–1 | 0 | 0 | *if oracle rotates |
| QuantumResistant (public) | 0 | 0 | 0 | 0 | 0–1 | 0 | 0 | **Teaches PQ hash ≠ hard** |
| SharedSecret | 2 | 0 | 2 | 0 | 0–2† | 0–1 | 0 | †if dictionary-encoded |
| SignatureAuthenticated | 0–2‡ | 2 | 0–2 | 0 | 0–1 | 0 | 2 | ‡depends on name seed |
| IdentityBased | 0§ | 0–2 | 0 | 0 | 0–1 | 0 | 0–2 | §vk public ⇒ names predictable |
| HybridSharedSecret | 2 | 0 | 2 | 2 | 0–2 | 0–1 | 0 | SHAKE expand |
| HybridKmac (R9b) | 2 | 0 | 2 | 2 | 0–2 | 0–1 | 0 | KMAC expand |
| KmacSharedSecret (R9a) | 2 | 0 | 2 | 0 | 0–2 | 0–1 | 0 | vs SharedSecret control |
| Ratcheting (R9c) | 2 | 0 | 1–2* | 0 | 0–1 | 0 | 0 | *experimental FS only |
| Hierarchical (R9d) | 2 | 0 | 0–2 | 0 | 0–1 | 0 | 0 | compartment / revoke drills |
| MultiParty (R9e) | 2 | 0 | 0–1 | 0 | 0–1 | 0 | 0 | all parties required; ≠ wrap |
| Threshold (R9f) | 2 | 0 | 0–1 | 0 | 0–1 | 0 | 0 | k-of-n lab shares; ≠ TSS product |
| AuthenticatedContext (R9g) | 0–2 | 2 | 0–1 | 0 | 0–1 | 0 | 1–2 | auth axis; +secret ⇒ H1 |
| EnvelopeRendezvous | 2 | 0–2 | 2 | 0–2 | 1 | 1 | 0–2 | Name may be decoy |
| Decentralized | 0–2 | 0–2 | 0–2 | 0–2 | 0–1 | 2 | 0–2 | Channel emphasis |
| MultiRecipient | 2 | 0 | 0–2 | 0 | 0–1 | 0 | 0 | wrap compartmentation |
| Rate-limited | same crypto | | | | | | | Low volume vs sinkhole race |

---

## Blue-team counter-objectives (always-on list)

1. **Binary config extraction** — vk, ss seed handling, campaign id, charset tables.  
2. **First-seen passive DNS + graph correlation.**  
3. **Behavioral EDR** — resolver process, parent chain, post-connect actions.  
4. **Registration and certificate transparency** on first use.  
5. **Traffic crypto fingerprinting** — ML-KEM/ML-DSA/envelope sizes.  
6. **Legal/takedown** on operator keys once recovered.  
7. **Lexical models** where adversaries optimize for “English-looking” labels.

## Lab scoring output (implemented)

`HardnessScorecard.fromDgaResult` / `fromPqdgaResult` + example suite print lines like:

```text
family=SharedSecretPqdga predictable=false secretBound=true
hardness={H1:2 H2:0 H3:2 H4:0 H5:0 H6:0 H7:0} counters=[behavior,pdns_first_seen,registration,ct_sizes]
ioc={kem=ML-KEM-768,ct_len=…,xof=SHAKE256}
```

Classical paths emit the same hardness line from metadata (`predictability`, lexical/alt-channel/flux flags). No live secrets. Toy `campaign_id` only.
