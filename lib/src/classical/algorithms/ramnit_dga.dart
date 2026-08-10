import 'package:pqdga/src/classical/dga_core.dart';

/// Ramnit DGA — literature-perfect (baderj / bin.re Park–Miller LCG).
///
/// Config seed is a hex dword (known campaign seeds). Labels are a–y only
/// (modulus 25); TLDs rotate through [tld]. Difficulty: [config-seeded].
class RamnitDGA extends DGAAlgorithm {
  /// TLD labels without or with leading dot (normalized at generate).
  final List<String> tld;

  /// Minimum SLD length (literature default 9).
  final int sldMinLength;

  /// Maximum SLD length (literature default 25).
  final int sldMaxLength;

  final int domainsPerDay;

  /// Campaign seed as unsigned 32-bit (literature known seed `0x16647BB4`).
  final int seed;

  /// Optional hex string form of [seed] (takes precedence when non-null).
  final String? seedHex;

  const RamnitDGA({
    this.tld = const ['click', 'com', 'eu', 'bid'],
    this.sldMinLength = 9,
    this.sldMaxLength = 25,
    this.domainsPerDay = 1000,
    this.seed = 0x16647BB4,
    this.seedHex,
  });

  /// Resolved seed dword for generation / IOC.
  int get resolvedSeed {
    if (seedHex != null && seedHex!.isNotEmpty) {
      return int.parse(seedHex!, radix: 16) & 0xFFFFFFFF;
    }
    return seed & 0xFFFFFFFF;
  }
}
