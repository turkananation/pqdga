# Ethics and authorized lab use

## Purpose

`pqdga` exists to help **defenders and authorized researchers**:

- Reproduce classical DGAs for detector training and IR drills.  
- Model post-quantum rendezvous hardness so SOC playbooks stay ahead.  
- Emit analyst metadata, IOC templates, and mitigation guidance.

It is **not** a toolkit for running real malware campaigns or unauthorized infrastructure takeover.

## Allowed

- Use in **isolated labs**, CTF-style blue-team exercises, and academic/defensive research with proper authorization.  
- Generate domains against **toy campaign IDs** and **ephemeral** PQ keys created in-process for tests.  
- Publish detection guidance, feature schemas, and hardness analyses derived from the library.  
- Sinkhole or blocklist **only** systems and zones you are authorized to control.

## Not allowed / out of scope

- Operational command-and-control for real victims.  
- Shipping or embedding **live operator secrets**, production ML-KEM/ML-DSA keys, or real botnet configs.  
- Instructions or features whose primary purpose is **evading law enforcement** or harming third parties.  
- Scanning, registering, or attacking domains/infrastructure **without authorization**.  
- Exploit development or attack tooling (see project scope — documentation and generation lab only).

## Key and secret handling

| Rule | Detail |
| --- | --- |
| Ephemeral keys | Tests and examples call `PqForge.generateKeys` (or equivalent) per run |
| No secret logs | Never print ML-KEM shared secrets or signing private keys |
| Toy campaigns | Example `campaign_id` values like `lab-toy-001` only |
| Metadata OK | Algorithm ids, public lengths, pubkey **fingerprints**, predictability flags |

## Documentation tone

- Pair every adversarial “make it hard” feature with a **blue-team counter** ([06-adversarial-hardness.md](06-adversarial-hardness.md)).  
- Prefer SOC playbooks and IOC templates as first-class outputs ([05-soc-detection-mitigation.md](05-soc-detection-mitigation.md)).  
- Root [README.md](../README.md) and [doc/README.md](README.md) carry the defensive banner.

## Contributor expectations

- Do not open PRs that add real C2 channels, live credential material, or weaponized exploit paths.  
- Update [PROGRESS.md](PROGRESS.md) with honest status (stubs ≠ done).  
- When unsure, bias toward **detection enablement** over stealth features without counters.

## Reporting misuse concerns

If you believe the project is being misrepresented or extended for operational abuse, contact the maintainers through the repository’s normal security/contact channel and refrain from distributing sensitive forks publicly.
