import 'package:pqdga/src/classical/dga_core.dart';

/// QakBot / Qbot DGA configuration.
///
/// Seed material: CRC32 of `{dayBucket}.{mon}.{year}.{configSeedHex}` then MT19937.
/// Difficulty: [config-seeded] (magic config seed 0/1 and TLD table are sample IOCs).
class QakBotDGA extends DGAAlgorithm {
  /// Hard-coded config seed used in date string (commonly 0 or 1).
  final int configSeed;

  /// When true, adds 1 to the MT seed (sandbox-detected path in literature).
  final bool sandbox;

  /// TLD table (note historical double `org`).
  final List<String> tld;

  /// Inclusive min label length.
  final int minDomainLength;

  /// Inclusive max label length.
  final int maxDomainLength;

  /// Typical monthly volume class for metadata (3 × ~50 in literature).
  final int domainsPerMonthHint;

  const QakBotDGA({
    this.configSeed = 0,
    this.sandbox = false,
    this.tld = const ['com', 'net', 'org', 'info', 'biz', 'org'],
    this.minDomainLength = 8,
    this.maxDomainLength = 25,
    this.domainsPerMonthHint = 150,
  });
}
