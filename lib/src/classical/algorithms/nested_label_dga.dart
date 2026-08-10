import 'package:pqdga/src/classical/dga_core.dart';

/// Wildcard / subdomain nesting DGA (research generic, R8).
///
/// Emits multi-label FQDNs (`a.b.c.tld`) to stress depth/length detectors and
/// DNS wire limits. **SOC lesson:** count labels and total FQDN length; deep
/// nesting is a structural IOC even when each label looks normal.
///
/// Difficulty: [trivial] with known seed (date + config).
class NestedLabelDGA extends DGAAlgorithm {
  /// TLD list (with or without leading dot).
  final List<String> tld;

  /// Number of labels **before** the TLD (depth ≥ 1).
  final int labelDepth;

  /// Per-label length bounds.
  final int minLabelLength;
  final int maxLabelLength;

  /// Optional config seed mixed into PRNG.
  final int seed;

  /// Charset for each label.
  final String charset;

  /// When true, prefix first label with `*` for wildcard-style lab IOCs
  /// (not a valid DNS query name — training artifact only).
  final bool emitWildcardMarker;

  const NestedLabelDGA({
    this.tld = const ['.com', '.net', '.org'],
    this.labelDepth = 3,
    this.minLabelLength = 3,
    this.maxLabelLength = 8,
    this.seed = 0x4E535444, // 'NSTD'
    this.charset = 'abcdefghijklmnopqrstuvwxyz0123456789',
    this.emitWildcardMarker = false,
  });
}
