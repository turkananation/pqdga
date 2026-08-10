import 'package:pqdga/src/classical/dga_core.dart';

/// Corebot DGA — literature-perfect (baderj/corebot NR LCG + `.ddns.net`).
///
/// Date + `nr_b` + init seed packed into LCG state; variable length 12–23.
/// Difficulty: [config-seeded].
class CoreBotDGA extends DGAAlgorithm {
  /// Initial LCG dword before date mix (literature lab often `0`).
  final int seed;

  /// `nr_b` packed into seed (literature samples use `8`).
  final int nrB;

  final int domainsPerDay;

  /// Fixed literature suffix.
  final String suffix;

  const CoreBotDGA({
    this.seed = 0,
    this.nrB = 8,
    this.domainsPerDay = 40,
    this.suffix = '.ddns.net',
  });
}
