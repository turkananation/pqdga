import 'package:pqdga/src/classical/dga_core.dart';

/// Homoglyph / IDN / punycode DGA (research generic, R8).
///
/// Builds lookalike labels then encodes via punycode (`xn--…`) so ASCII-only
/// filters miss the abuse. **SOC lesson:** monitor IDN / `xn--` registrations
/// and confusable scripts, not just LDH entropy.
///
/// Difficulty: [config-seeded] (base word + confusable map are IOCs).
class IdnDGA extends DGAAlgorithm {
  /// Base ASCII word that will receive confusable substitutions.
  final String baseWord;

  /// TLD list without or with leading dots.
  final List<String> tld;

  /// When true (default), emit A-label form `xn--…tld`.
  final bool emitPunycode;

  /// Optional 32-bit seed mixed with date for which positions to mutate.
  final int seed;

  /// How many confusable substitutions to attempt per domain.
  final int maxSubstitutions;

  const IdnDGA({
    this.baseWord = 'paypal',
    this.tld = const ['.com', '.net', '.org'],
    this.emitPunycode = true,
    this.seed = 0x49444E31, // 'IDN1'
    this.maxSubstitutions = 2,
  });
}
