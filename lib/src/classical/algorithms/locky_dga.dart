import 'package:pqdga/src/classical/dga_core.dart';

/// Locky ransomware DGA configuration (research reimplementation of v2-style).
///
/// Open literature: date + config seed → rotate/mul PRNG → a–y labels + TLD set.
/// Difficulty: [trivial] with known config seed (config constants are sample IOCs).
class LockyDGA extends DGAAlgorithm {
  /// Hard-coded sample seed (config IOC). Default matches common v2 config #1.
  final int seed;

  /// Rotate amount used in the mul/ror chain.
  final int shift;

  /// Domain-index modulus before rol packing.
  final int mod;

  /// TLD list without leading dots (Locky historically omits the dot in selection).
  final List<String> tld;

  /// How many domains a sample would try per generation window (lab metadata).
  final int domainsPerWindow;

  /// Algorithm family label for metadata (`v2` research path).
  final String variant;

  const LockyDGA({
    this.seed = 62,
    this.shift = 7,
    this.mod = 8,
    this.tld = const [
      'ru',
      'pw',
      'eu',
      'in',
      'yt',
      'pm',
      'us',
      'fr',
      'de',
      'it',
      'be',
      'uk',
      'nl',
      'tf',
    ],
    this.domainsPerWindow = 8,
    this.variant = 'v2',
  });
}
