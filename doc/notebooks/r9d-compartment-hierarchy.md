# R9d — Hierarchy compartmentation

## Question

Do sibling hierarchy paths from the same root produce **distinct** domain
namespaces (compartmentation) in `HierarchicalPqdga`?

## Method

1. Root secret → path `region-a/team-1` and sibling `region-a/team-2`.
2. Generate domains for each leaf.
3. Confirm ordered lists differ; leaf-only config matches full path derive.

## Lab API

```dart
final exp = await BindingAnalysis.hierarchyCompartment();
// exp['siblings_differ'] == true
```

## Observation (lab)

Sibling paths yield **distinct** namespaces. Leaf-only expand matches the
fully specified hierarchy config for the same path.

## Interpretation (claim-disciplined)

- Validates **path-bound expand** behavior for playbooks (compartment IOC:
  hierarchy path string / depth).
- **Not** a formal isolation proof (no cryptographic access-control theorem).

## SOC lesson

Compromise of one team leaf should not imply offline precompute of sibling
compartments **if** leaf secrets are independent after derive — still model
root compromise as catastrophic.
