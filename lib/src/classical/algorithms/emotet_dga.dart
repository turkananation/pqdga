import 'package:pqdga/src/classical/dga_core.dart';

/// Emotet / Geodo-era **volume + broad TLD** research model (P1).
///
/// Not bit-exact to a single Emotet generation (no baderj pin). Models the
/// SOC lesson: high daily volume across many TLDs. Difficulty: [config-seeded].
class EmotetDGA extends DGAAlgorithm {
  final List<String> tld;
  final int minDomainLength;
  final int maxDomainLength;
  final int seed;
  final int domainsPerDay;

  const EmotetDGA({
    this.tld = const [
      '.com',
      '.net',
      '.org',
      '.info',
      '.biz',
      '.eu',
      '.co.uk',
      '.ru',
      '.me',
      '.pw',
      '.top',
      '.xyz',
    ],
    this.minDomainLength = 12,
    this.maxDomainLength = 19,
    this.seed = 0x454D4F54, // 'EMOT'
    this.domainsPerDay = 1000,
  });
}
