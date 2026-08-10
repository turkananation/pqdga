# pqdga research documentation

**Defensive research lab only.** This package reproduces classical DGA families and designs post-quantum rendezvous generators so SOC/IR teams can train detectors, sinkhole playbooks, and understand when precompute stops working. It is **not** operational C2 tooling. See [08-ethics-lab-use.md](08-ethics-lab-use.md).

## How to use this tree

| Audience | Start here |
| --- | --- |
| Maintainer / contributor | [PROGRESS.md](PROGRESS.md) → [07-implementation-roadmap.md](07-implementation-roadmap.md) |
| Implementer (plug-in a family) | [01-architecture.md](01-architecture.md) → [02-classical-families.md](02-classical-families.md) or [03-post-quantum-design.md](03-post-quantum-design.md) |
| SOC / blue team | [05-soc-detection-mitigation.md](05-soc-detection-mitigation.md) + family tables in [02](02-classical-families.md) / [03](03-post-quantum-design.md) |
| Adversarial hardness model | [06-adversarial-hardness.md](06-adversarial-hardness.md) |
| Package wiring (`pqforge` / `swissarmyknife`) | [04-package-utilization.md](04-package-utilization.md) |

## Document index

| Doc | Purpose |
| --- | --- |
| [PROGRESS.md](PROGRESS.md) | **Canonical tracker** — checklists, summary counts, definition of done |
| [00-overview.md](00-overview.md) | Mission, defensive framing, product outputs |
| [01-architecture.md](01-architecture.md) | Module map, dispatch pattern, plug-in recipe |
| [02-classical-families.md](02-classical-families.md) | Classical families catalog (malware-style, P0–P2, research generics) + required metadata keys |
| [03-post-quantum-design.md](03-post-quantum-design.md) | Shared PQ pipeline, family map, extras, **R9 binding ladder** |
| [04-package-utilization.md](04-package-utilization.md) | `pqforge` / `pqcrypto` / `pointycastle` KMAC / `swissarmyknife` usage matrix |
| [05-soc-detection-mitigation.md](05-soc-detection-mitigation.md) | Features, playbooks, predictability classes |
| [06-adversarial-hardness.md](06-adversarial-hardness.md) | Make-it-hard goals vs blue-team counters |
| [07-implementation-roadmap.md](07-implementation-roadmap.md) | Ordered build phases R0–R9 |
| [08-ethics-lab-use.md](08-ethics-lab-use.md) | Authorized lab boundaries |

## Progress tracker rule

**Update [PROGRESS.md](PROGRESS.md) in the same change as every code or doc deliverable.**

- Tick `- [x]` only when the item meets that category’s **definition of done**.
- Adjust the summary counts table when checklist totals change.
- Stubs and empty files are **not** done.
- Other docs describe *what/why/how*; they do **not** own live checkmarks (short “see PROGRESS” pointers only).
- Post-roadmap items live only in PROGRESS § **Open / deferred (post R9)**.

Status vocabulary used in narrative docs: `done` | `partial` | `todo` | `blocked` | `wontfix`.

### Analysis notebooks

- Binding ladder writeups: [`notebooks/`](notebooks/)
- Literature goldens: [`literature_goldens.json`](literature_goldens.json)
