import 'package:pqdga/src/classical/dga_core.dart';

/// Ranbyus DGA configuration (May arithmetic variant by default).
///
/// Date + 32-bit config seed → 14-letter a–y labels + rotating TLD set.
/// Difficulty: [config-seeded] (seed dword is sample IOC).
class RanbyusDGA extends DGAAlgorithm {
  /// 32-bit config seed (e.g. `0xB6354BC3`).
  final int seed;

  /// `may` = original 14-char arithmetic DGA; `september` reserved for PCG path.
  final String variant;

  /// TLD set without dots (May order).
  final List<String> tld;

  /// Domains per day in literature samples.
  final int domainsPerDay;

  const RanbyusDGA({
    this.seed = 0xB6354BC3,
    this.variant = 'may',
    this.tld = const ['in', 'me', 'cc', 'su', 'tw', 'net', 'com', 'pw', 'org'],
    this.domainsPerDay = 40,
  });
}
