import 'package:pqdga/src/classical/dga_core.dart';

/// DirCrypt DGA — literature-perfect (baderj/dircrypt Park–Miller → `.com`).
///
/// Config seed hex dword; length 8–20; a–z labels. Difficulty: [config-seeded].
class DirCryptDGA extends DGAAlgorithm {
  final int seed;
  final int domainsPerDay;
  final String tld;

  const DirCryptDGA({
    this.seed = 0x8EB35B15,
    this.domainsPerDay = 30,
    this.tld = '.com',
  });
}
