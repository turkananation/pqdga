import 'package:pqdga/src/classical/dga_core.dart';

/// Vawtrak DGA — literature-perfect (baderj/vawtrak glibc LCG → `.top`).
///
/// Seed is a config dword (not pure date). Difficulty: [config-seeded].
class VawtrakDGA extends DGAAlgorithm {
  /// Literature default seed used in open examples.
  final int seed;

  final String tld;
  final int domainsPerDay;

  /// Optional campaign/tier metadata for SOC notebooks (not in expand path).
  final String campaignId;
  final int tier;

  const VawtrakDGA({
    this.seed = 0xDEADBEEF,
    this.tld = '.top',
    this.domainsPerDay = 96,
    this.campaignId = 'lab',
    this.tier = 1,
  });
}
