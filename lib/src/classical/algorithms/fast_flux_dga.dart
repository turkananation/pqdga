import 'package:pqdga/src/classical/dga_core.dart';
import 'package:pqdga/src/common/flux_schedule.dart';

/// Fast-flux / double-flux schedule-coupled DGA (research generic, R8).
///
/// Generates names **and** attaches flux policy metadata (TTL, churn window,
/// NS flux flag) so detectors can train on infra correlation, not names alone.
/// **SOC lesson:** pair NX/resolution features with TTL + NS churn.
///
/// Difficulty: [trivial]–[config-seeded].
class FastFluxDGA extends DGAAlgorithm {
  /// TLD list.
  final List<String> tld;

  /// Label length bounds.
  final int minDomainLength;
  final int maxDomainLength;

  /// Config seed.
  final int seed;

  /// Flux schedule policy (TTL, rotation seconds, double-flux).
  final FluxSchedule schedule;

  /// Charset for labels.
  final String charset;

  const FastFluxDGA({
    this.tld = const ['.com', '.net', '.org', '.info'],
    this.minDomainLength = 10,
    this.maxDomainLength = 16,
    this.seed = 0x464C5558, // 'FLUX'
    this.schedule = const FluxSchedule(),
    this.charset = 'abcdefghijklmnopqrstuvwxyz0123456789',
  });
}
