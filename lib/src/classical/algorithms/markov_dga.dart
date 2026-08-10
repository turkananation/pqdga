import 'package:pqdga/src/classical/dga_core.dart';

/// Markov / n-gram language-model DGA (research generic, R8).
///
/// Samples labels from a fixed bigram transition table so names look
/// pronounceable/English-ish. **SOC lesson:** entropy-only detectors fail;
/// defenders need lexical / LM features (`needs_lexical_model`).
///
/// Difficulty: [config-seeded] (transition table + seed are sample IOCs).
class MarkovDGA extends DGAAlgorithm {
  /// Toy campaign / table id (not a live operator secret).
  final String campaignId;

  /// TLD list (with or without leading dot).
  final List<String> tld;

  /// Label length bounds.
  final int minDomainLength;
  final int maxDomainLength;

  /// Optional 32-bit config seed mixed into the date PRNG.
  final int seed;

  /// Alphabet for emission (default lowercase a–z).
  final String charset;

  /// Order of the Markov model (`2` = bigram).
  final int order;

  const MarkovDGA({
    this.campaignId = 'toy-markov',
    this.tld = const ['.com', '.net', '.org', '.info'],
    this.minDomainLength = 8,
    this.maxDomainLength = 16,
    this.seed = 0x4D4B5256, // 'MKRV'
    this.charset = 'abcdefghijklmnopqrstuvwxyz',
    this.order = 2,
  });
}
