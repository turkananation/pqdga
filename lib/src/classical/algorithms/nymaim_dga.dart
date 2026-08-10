import 'package:pqdga/src/classical/dga_core.dart';

/// Nymaim DGA — literature-perfect (baderj/nymaim date PRNG).
///
/// Seed mixes year/month/dow/day with magic dwords REVA/IHOL/YUH /MAV .
/// TLD chosen from last-but-one letter ranges. Difficulty: [trivial] given date.
class NymaimDGA extends DGAAlgorithm {
  final int domainsPerDay;

  /// Literature TLD decision is hard-coded in the expand path; list is IOC only.
  final List<String> tld;

  const NymaimDGA({
    this.domainsPerDay = 128,
    this.tld = const ['.com', '.org', '.biz', '.net', '.info'],
  });
}
