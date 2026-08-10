import 'package:pqdga/src/classical/dga_core.dart';

/// Kraken DGA — literature-perfect (baderj/kraken v2, seed set `a`/`b`).
///
/// Date-based discards + LCG; TLD set 1 (com/net/tv/cc) or 2 (dyndns family).
/// Difficulty: [trivial] with date + seed set.
class KrakenDGA extends DGAAlgorithm {
  /// Literature seed set key: `a` or `b`.
  final String seedSet;

  /// `1` = com/net/tv/cc; `2` = dyndns.org/yi.org/dynserv.com/mooo.com.
  final int tldSet;

  final int domainsPerDay;

  /// When true, emit only the `ex` (temp_file) stream half (stable goldens).
  final bool exOnly;

  const KrakenDGA({
    this.seedSet = 'a',
    this.tldSet = 1,
    this.domainsPerDay = 1000,
    this.exOnly = false,
  });
}
