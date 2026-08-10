import 'package:pqdga/src/classical/dga_core.dart';

/// Proslikefan DGA — literature-perfect (baderj/proslikefan string-hash).
///
/// Magic string (known: `prospect`, `OK`) + date + TLD → Java-style hash walk.
/// Difficulty: [config-seeded].
class ProslikefanDGA extends DGAAlgorithm {
  final List<String> tld;

  /// Literature magic string seed.
  final String magic;

  /// Domains emitted per (index × tld) wave; literature uses 10 indices.
  final int waves;

  final int domainsPerDay;

  const ProslikefanDGA({
    this.tld = const ['com', 'net', 'biz', 'ru', 'cc'],
    this.magic = 'prospect',
    this.waves = 10,
    this.domainsPerDay = 100,
  });
}
