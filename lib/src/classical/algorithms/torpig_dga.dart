import 'package:pqdga/src/classical/dga_core.dart';

/// Torpig-style **time-window seed rotation** research model (P2).
///
/// Pedagogical target: seed rotates every [windowDays] (literature weekly
/// windows). Not a single bit-exact Torpig pin (no baderj module).
/// Difficulty: [trivial] within a window once algorithm is known.
class TorpigDGA extends DGAAlgorithm {
  final List<String> tld;
  final int minDomainLength;
  final int maxDomainLength;

  /// Days per seed window (rotation lesson).
  final int windowDays;

  final int seed;
  final int domainsPerDay;

  const TorpigDGA({
    this.tld = const ['.com', '.net', '.biz', '.org'],
    this.minDomainLength = 8,
    this.maxDomainLength = 12,
    this.windowDays = 7,
    this.seed = 0x544F5250, // 'TORP'
    this.domainsPerDay = 250,
  });
}
