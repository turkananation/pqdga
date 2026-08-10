import 'package:pqdga/src/classical/dga_core.dart';

/// Shiotob / Urlzone DGA — literature-perfect (baderj/shiotob).
///
/// Pure seed-domain mutation; **date-independent**. Alternates `.com`/`.net`.
/// Difficulty: [config-seeded] (seed domain is the extract IOC).
class ShiotobDGA extends DGAAlgorithm {
  /// Initial domain including TLD (literature example `4ypv1eehphg3a.com`).
  final String seedDomain;

  final int domainsPerDay;

  const ShiotobDGA({
    this.seedDomain = '4ypv1eehphg3a.com',
    this.domainsPerDay = 2001,
  });
}
