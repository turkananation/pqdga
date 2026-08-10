import 'package:pqdga/src/classical/dga_core.dart';

/// Suppobox-style two-word dictionary DGA configuration.
///
/// Concatenates two words from a fixed wordlist using a bit-shuffle of
/// `unixSeconds >> 9` (and increments). Defeats simple entropy detectors.
/// Difficulty: [config-seeded] (wordlist is the critical config artifact).
class SuppoboxDGA extends DGAAlgorithm {
  /// Word list (literature sets are length 384; indices use 0..255 at minimum).
  final List<String> wordList;

  /// TLD including leading dot.
  final String tld;

  /// Optional fixed Unix seconds for reproducible lab runs.
  /// When null, uses the `date` argument as UTC epoch seconds.
  final int? unixSeconds;

  /// Domains emitted per seed window in original samples (~85).
  final int domainsPerWindow;

  const SuppoboxDGA({
    required this.wordList,
    this.tld = '.net',
    this.unixSeconds,
    this.domainsPerWindow = 85,
  });
}
