# SOC detection and mitigation

Companion to family catalogs ([02](02-classical-families.md), [03](03-post-quantum-design.md)) and hardness model ([06](06-adversarial-hardness.md)).  
Code emitters: `package:pqdga` → `SocFeatures` (`lib/src/common/soc_features.dart`) — per-domain + batch + **classical and PQ** IOC templates; `ClassicalSocMetadata` for uniform classical flags; `HardnessScorecard` for H1–H7 lab ratings. Live ticks: [PROGRESS.md](PROGRESS.md) § SOC artifacts.

## Predictability classes → first response

| Class | Offline precompute? | First-line mitigation |
| --- | --- | --- |
| `trivial` | Yes (date) | Precompute domain set → sinkhole / RPZ / registrar early warning |
| `config-seeded` | After config extract | Malware config / wordlist / constants → then same as trivial |
| `oracle-seeded` | Only with oracle stream | Ingest oracle (or accept first-seen); cannot pure-date race |
| `secret-seeded` | No (w/o secret) | Behavior, EDR, registration/CT, traffic crypto sizes; sinkhole after observe |
| PQ `predictable=true` | Yes | Same as classical precompute — **do not** assume SHAKE implies hard |
| PQ `secretBound=true` | No | SharedSecret / hybrid path playbooks below |

Generators emit `predictability` / `predictable` / `secretBound` on PQ results and classical metadata; `SocFeatures` batch helpers surface them for notebooks.

---

## Per-domain feature vector

Extract via `SocFeatures.forDomain(fqdn)` for detector training and notebooks:

| Feature | Notes |
| --- | --- |
| `length` | Label and FQDN |
| `entropy` (Shannon) | Weak alone against dictionary/Markov |
| `hex_ratio` | Matsnu / hash-substring families |
| `digit_ratio` | Mixed alphanumeric Locky-like |
| `vowel_consonant_transitions` | Necurs / Pykspa pronounceable |
| `ngram_score_vs_english` | Dictionary / Suppobox / Markov |
| `tld` | Multi-TLD families (Conficker, QakBot) |
| `subdomain_depth` | Nested-label research generic |
| `idn` / `punycode` | IDN generic (`xn--`) |
| `charset_class` | alpha / alnum / hex / custom |

## Batch / campaign features

| Feature | Notes |
| --- | --- |
| `domains_per_day` / requested count | Conficker-scale vs rate-limited PQ |
| `tld_diversity` | Distinct TLDs in window |
| `inter_arrival` | If bot cadence simulated (`RateLimiter`) |
| `expected_nxdomain_ratio` | Pre-registration DGA noise |
| `length_histogram` | Family fingerprint |
| `first_seen_vs_precompute` | Secret-bound families |

---

## Mitigation playbooks

### P1 — Precompute + sinkhole / RPZ

**When:** `trivial` or config recovered; PQ with `predictable=true`.

1. Run generator for date window (golden-test style).  
2. Load RPZ / internal sinkhole / passive DNS watch list.  
3. Set blocklist TTL policy; monitor NX → sudden resolve flips.  
4. Registrar bulk-lookalike early warning where available.

**Metadata flags:** `sinkhole_precompute: true`.

### P2 — Config / key extraction then precompute

**When:** `config-seeded`, IdentityBased (vk in sample), magic constants.

1. RE sample → wordlists, seeds, PRNG constants, **PQ vk**.  
2. Feed config into generator.  
3. Fall through to P1.  
4. YARA/config IOCs on constants (Nymaim-class).

**Flags:** `needs_config_extract: true`.

### P3 — Lexical / LM detection

**When:** Dictionary, Suppobox-style, Markov — entropy rules fail.

1. n-gram / LM scores vs English.  
2. Wordlist membership and concat patterns.  
3. Do **not** rely on high entropy alone.

**Flags:** `needs_lexical_model: true`.

### P4 — Behavioral + registration (secret-bound)

**When:** SharedSecret, Hybrid, low-volume rate-limited; offline gen fails.

1. EDR: who resolves, process ancestry, what follows connect.  
2. Resolution bursts, DoH destinations, JA3/JA4-like client patterns (lab notes).  
3. First-seen passive DNS + graph correlation.  
4. Registration + certificate transparency on first use.  
5. Sinkhole **after** observe if authorized — not calendar precompute.

**Flags:** `sinkhole_precompute: false`, `secret_bound: true`.

### P5 — Anti-sinkhole signatures

**When:** SignatureAuthenticated (ML-DSA gate).

1. Sinkhole IP alone insufficient if bot verifies sig.  
2. Paths: recover sk, binary patch, or block before verify (hosts / DNS still fails app-level trust).  
3. Hunt **pubkey fingerprint** and detached sig blobs in traffic/config.

**Flags:** `requires_signature: true`.

### P6 — Crypto size IOCs (PQ traffic)

| Artifact | Why it helps |
| --- | --- |
| ML-KEM ciphertext length | Stable per parameter set |
| ML-DSA signature length | Stable per parameter set |
| Envelope / hybrid blob sizes | EnvelopeRendezvous |
| Algorithm ids in metadata | Lab and future malware config strings |

Emit `kemCiphertextLength`, `signatureLength`, algorithm enums from generators (done on PQ paths). Notebooks: `SocFeatures.iocTemplateFromPqdga(result)` and `SocFeatures.iocTemplateFromDga(result)` for classical PRNG/charset/seed packing IOCs.

### P7 — Channel agility / non-DNS

**When:** Decentralized / multi-channel encodings.

1. RPZ-only is incomplete.  
2. Extend monitoring notes to DoH endpoints and abstract non-DNS handles (docs/analogies unless channel simulated).  
3. Correlate same XOF stream across encodings if lab implements multi-channel.

---

## Metadata checklist for implementers

Every family (classical + PQ) **does** populate (post-R9 polish):

```text
predictability | predictable | secret_bound / secretBound
charset | length_* | tld_set | seed_packing | prng/constants
playbook_flags: sinkhole_precompute, needs_lexical_model,
                needs_config_extract, requires_signature, …
soc_lesson
PQ: xof/kdf, kemAlgorithm, kemCiphertextLength, sigAlgorithm, signatureLength,
    pubkeyFingerprint (non-secret)
R9: binding_mode, binding_ladder (R9a…R9g), ratchet/hierarchy/group ids
campaign_id: toy only
hardness: HardnessScorecard.fromDgaResult / fromPqdgaResult → H1…H7 + counters
```

## Mapping families → playbooks (summary)

| Family group | Primary playbooks |
| --- | --- |
| Conficker, Necurs, Matsnu, most date DGAs | P1 |
| QakBot, dictionary, Bamital, Suppobox | P2 + P3 |
| Markov / IDN research | P3 (+ IDN monitors) |
| Oracle-seed | oracle feed + first-seen |
| QuantumResistant (public seed) | P1 — teach false confidence |
| SharedSecret / Hybrid (SHAKE or KMAC) | P4 + P6 |
| SignatureAuthenticated (sign domain) | P5 + P6 |
| AuthenticatedContext (sign context → derive) | P5 lesson + optional P4 if secretBound |
| IdentityBased | P2 (vk) then P1; + P5 if signed |
| Decentralized / multi-channel | P7 + P4 |
| EnvelopeRendezvous | P6 + payload inspection |
| Rate-limited | P4 with longer windows |
| MultiRecipient (wrap) | P4 + partial-takedown isolation notes |
| MultiParty / Threshold (joint derive) | P4 + multi-party ops (sync, missing shares) — **≠ wrap** |
| Ratcheting | P4 + epoch-window hunting; FS is experimental only |
| Hierarchical | P4 + compartment / subtree revoke drills |
