# Binding-ladder analysis notebooks

Research writeups (not new generators). Runnable lab surface:
`BindingAnalysis` + `NotebookConsumer.consumeBindingAnalysis()`.

| Notebook | Ladder | Code entry |
| --- | --- | --- |
| [R9a KMAC vs R4 SHAKE](r9a-kmac-vs-r4-shake.md) | Expand KDF delta | `BindingAnalysis.kmacVsShake` |
| [R9c delete-forward / ratcheting](r9c-delete-forward-ratcheting.md) | Evolution | `BindingAnalysis.ratchetDeleteForward` |
| [R9d compartment / hierarchy](r9d-compartment-hierarchy.md) | Path binding | `BindingAnalysis.hierarchyCompartment` |
| [R9e/f multi-party & threshold ops](r9e-f-multiparty-threshold-ops.md) | Group binding | `BindingAnalysis.multiPartyVsThresholdOps` |

### Claim discipline (global)

- Construction-class framing only — **no** novelty / “first PQ DGA” claims.
- R9c: **no forward-secrecy claim** without a threat model.
- R9f: **not production TSS**.
- Keep **MultiRecipient** (wrap) ≠ **MultiParty** (all n) ≠ **Threshold** (k-of-n).

### Detector consumers

Wire reports via:

```dart
final briefing = await NotebookConsumer.labBriefing(
  dga: classicalResult,
  pqdga: pqResult,
  runBindingAnalysis: true,
  includeSlhCatalog: true,
);
```

See also `DetectorNotebook`, `HardnessScorecard`, `LabHarness`, `LiteratureCorpus`.
