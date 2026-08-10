# Classical DGA families

Status checkmarks: [PROGRESS.md](PROGRESS.md).  
Plug-in steps: [01-architecture.md](01-architecture.md).  
Detect/mitigate detail: [05-soc-detection-mitigation.md](05-soc-detection-mitigation.md).

## Difficulty classes

| Class | Meaning | Typical mitigation |
| --- | --- | --- |
| `trivial` | Seed is public date (or weak packing) only | Precompute + sinkhole / RPZ |
| `config-seeded` | Needs malware config / magic constants / wordlists | Config extraction + then precompute |
| `oracle-seeded` | Seed from external public stream (chain tip, trend hash) | Cannot pure-date sinkhole; need oracle feed or first-seen |
| `secret-seeded` | Cryptographic secret (classical or PQ) | Behavior, registration, EDR — not offline gen |

---

## Implemented — malware-style

| Family | Path | Pattern (short) | SOC look-fors | Difficulty |
| --- | --- | --- | --- | --- |
| Conficker | `conficker_dga.dart` | Week/date seed, high volume, multi-TLD | 10k–50k/day class volume, multi-TLD bursts, weekly buckets | `trivial`–`config-seeded` (variant) |
| Necurs | `necurs_dga.dart` | Custom LCG PRNG, variable length | Pronounceability-ish lengths, PRNG fingerprint | `trivial` |
| Pushdo | `pushdo_dga.dart` | Date-driven generation | Daily batches, charset/length bands | `trivial` |
| Rovnix | `rovnix_dga.dart` | Date/seed packing | Consistent structure | `trivial` |
| CryptoLocker | `cryptolocker_dga.dart` | Date arithmetic style | Ransomware-era daily sets | `trivial` |
| Bamital | `bamital_dga.dart` | Word/concat leaning patterns | Lower entropy than pure random | `config-seeded` (lists) |
| Tinba | `tinba_dga.dart` | Compact banker-style labels | Short labels, banking malware context | `trivial` |
| Murofet | `murofet_dga.dart` | Hash/date hybrids | Hex-ish or mixed labels | `trivial` |
| Simda | `simda_dga.dart` | Seeded generation | Campaign timing clusters | `trivial`–`config-seeded` |
| Matsnu | `matsnu_dga.dart` | MD5(date) substrings as labels | Hex-ratio high; MD5 in metadata | `trivial` |

Generator logic: `lib/src/classical/dga_generator.dart`.

## Implemented — generics

| Family | Path | Pattern | SOC look-fors | Difficulty |
| --- | --- | --- | --- | --- |
| Time-based | `time_based_dga.dart` | Explicit time bucket seed | Aligns to wall-clock buckets | `trivial` |
| Dictionary-based | `dictionary_based_dga.dart` | Wordlist composition | Low entropy, English-looking; **entropy rules fail** | `config-seeded` |
| Arithmetic | `arithmetic_dga.dart` | LCG / arithmetic progression | Uniform length/charset, arithmetic artifacts | `trivial` |
| Permutation | `permutation_dga.dart` | Permute seed material | Finite set exhaustion possible | `trivial`–`config-seeded` |

---

## Implemented — P0 (high ROI)

Track in PROGRESS § Classical — P0. Generator: `dga_generator.dart`. Goldens: `test/pqdga_test.dart`.

| Family | Path | Pattern (short) | SOC look-fors | Difficulty |
| --- | --- | --- | --- | --- |
| **Locky** | `locky_dga.dart` | Date + cfg seed → mul/ror PRNG → a–y labels (len 5–15) | Mid-entropy alpha, fixed length bands, ransomware C2 timing, TLD set `ru/pw/eu/…` | `trivial` (known cfg) |
| **QakBot / Qbot** | `qakbot_dga.dart` | CRC32(`dayBucket.mon.year.seed`) → MT19937 → a–z 8–25 + multi-TLD | NXDOMAIN storms, TLD diversity, month-bucketed seed string | `config-seeded` |
| **Suppobox-style** | `suppobox_dga.dart` | `unix>>9` bit-shuffle → two dictionary words + `.net` | Low entropy English-looking FQDNs; **entropy rules fail** → lexical models | `config-seeded` |
| **Banjori** | `banjori_dga.dart` | Mutate first 4 letters of hardcoded seed domain; tail fixed | Constant tail/TLD IOC; not date-seeded | `config-seeded` |
| **Ranbyus** | `ranbyus_dga.dart` | Date + seed dword arithmetic (May) → 14× a–y + rotating TLDs | Daily batches; fixed length 14; config seed IOC | `config-seeded` |

## Implemented — P1

PROGRESS § Classical — P1 (**done** R8). Goldens: `test/pqdga_test.dart`.

| Family | Path | Notes | SOC look-fors | Difficulty |
| --- | --- | --- | --- | --- |
| Ramnit | `ramnit_dga.dart` | MD5/date hex stream | Hash-hex substrings as labels | `trivial` |
| Nymaim / GozNym-ish | `nymaim_dga.dart` | Date + magic constants LCG | Magic constants → YARA/config IOCs | `config-seeded` |
| Shiotob / Urlzone | `shiotob_dga.dart` | Custom PRNG | Non-uniform length; PRNG fingerprint | `trivial` |
| Pykspa / Symmi | `pykspa_dga.dart` | Pronounceable CV | Vowel-consonant regularity → linguistic features | `trivial` |
| Vawtrak / Neverquest | `vawtrak_dga.dart` | Campaign + tier in seed | Seed ≠ pure date | `config-seeded` |
| Emotet/Geodo-era | `emotet_dga.dart` | High volume + broad TLD list | Volume + TTL patterns | `config-seeded` |

## Implemented — P2

PROGRESS § Classical — P2 (**done** R8).

| Family | Path | Notes | Difficulty |
| --- | --- | --- | --- |
| Kraken / Bobax | `kraken_dga.dart` | Older arithmetic; legacy IR labs | `trivial` |
| Torpig / Mebroot | `torpig_dga.dart` | Time windows; seed rotation lessons | `trivial` |
| CoreBot | `corebot_dga.dart` | Nested MD5 | `config-seeded` |
| DirCrypt / PadCrypt | `dircrypt_dga.dart` | Niche ransomware | `config-seeded` |
| Proslikefan | `proslikefan_dga.dart` | Corpus diversity | `trivial` |

## Implemented — Research generics (not malware names)

PROGRESS § Research generics (**done** R8).

| Generic | Path | Hardness angle | SOC shift |
| --- | --- | --- | --- |
| Markov / n-gram LM DGA | `markov_dga.dart` | Defeats entropy-only rules | Need LM / lexical detectors |
| Homoglyph / IDN / punycode | `idn_dga.dart` | Bypass ASCII-only filters | IDN abuse monitoring (`xn--`) |
| Seed-from-public-oracle | `oracle_seed_dga.dart` | Breaks pure date sinkholing | Oracle stream or first-seen PDNS |
| Multi-channel labels | `multi_channel_dga.dart` + `MultiChannelCodec` | DNS is one encoding of stream | DoH / alt-channel telemetry |
| Fast-flux schedule coupling | `fast_flux_dga.dart` + `FluxSchedule` | TTL + churn, not just names | Infra correlation |
| Wildcard / nested labels | `nested_label_dga.dart` | Deep label counts | DNS length limits as constraint |

---

## Metadata generators emit (all families — required)

Every classical `DGAResult.metadata` is built via `ClassicalSocMetadata` and supports SOC extractors / IOC templates:

| Key | Purpose |
| --- | --- |
| `charset` | Alphabet used |
| `length_min` / `length_max` | Length detectors |
| `seed_packing` | How date/config entered the PRNG |
| `prng` / constants | Fingerprinting & YARA |
| `tld_set` | TLD diversity rules |
| `predictability` | `trivial` \| `config-seeded` \| `oracle-seeded` \| `secret-seeded` |
| `predictable` / `secret_bound` | Bools for batch helpers |
| `playbook_flags` | Nested: `sinkhole_precompute`, `needs_config_extract`, `needs_lexical_model`, … |
| `soc_lesson` | One-line blue-team takeaway |
| `wordlist_id` / family extras | Dictionary ids, magic constants, oracle id, flux TTL, … |

Notebooks: `SocFeatures.iocTemplateFromDga(result)` and `HardnessScorecard.fromDgaResult(result)`.

---

## Cross-links

| Item | PROGRESS section |
| --- | --- |
| Implemented malware-style | Classical — implemented malware-style |
| Generics | Classical — implemented generics |
| Locky…Ranbyus | Classical — P0 (**done**) |
| Ramnit…Emotet | Classical — P1 (**done**) |
| Kraken…Proslikefan | Classical — P2 (**done**) |
| Markov…nested | Research generics (**done**) |
