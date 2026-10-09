import 'package:pqdga/src/classical/dga_core.dart';

/// Pykspa precursor DGA — literature-aligned (baderj/pykspa/precursor).
///
/// Unix-time // 2-day buckets seed a custom LCG; mixed TLDs.
/// Difficulty: [trivial] with time bucket.
///
/// Note: `pykspa/improved` needs MD6 fixtures — not bundled; precursor is the
/// pinned literature path.
class PykspaDGA extends DGAAlgorithm {
  final int domainsPerDay;

  /// When non-null, overrides date-derived 2-day bucket seed (lab pin).
  final int? seedOverride;

  const PykspaDGA({this.domainsPerDay = 5000, this.seedOverride});
}
