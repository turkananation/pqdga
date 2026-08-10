import 'package:pqdga/src/classical/dga_core.dart';

/// Banjori (MultiBanker 2) DGA configuration.
///
/// Mutates only the first four letters of a hardcoded seed domain; the tail
/// (including TLD) is constant. Not date-seeded — date is metadata only.
/// Difficulty: [config-seeded] (seed domain is the sample IOC).
class BanjoriDGA extends DGAAlgorithm {
  /// Full seed FQDN, e.g. `earnestnessbiophysicalohax.com`.
  final String seedDomain;

  /// Whether the first emitted domain is the seed itself (literature samples do).
  final bool includeSeedDomain;

  const BanjoriDGA({
    this.seedDomain = 'earnestnessbiophysicalohax.com',
    this.includeSeedDomain = true,
  });
}
