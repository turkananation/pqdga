/// Fast-flux / double-flux schedule policy metadata (R8 research).
///
/// Attached to generation results so SOC notebooks can train on TTL + churn
/// correlation, not domain strings alone.
class FluxSchedule {
  /// Advertised DNS TTL in seconds (short = classic flux IOC).
  final int ttlSeconds;

  /// How often A/AAAA records rotate in the lab model.
  final int rotationSeconds;

  /// When true, NS set also churns (double-flux).
  final bool doubleFlux;

  /// Soft cap on distinct resolving IPs per window (lab metadata).
  final int maxIpsPerWindow;

  /// Soft cap on distinct NS hostnames when [doubleFlux] is true.
  final int maxNsPerWindow;

  /// Human policy id for notebooks.
  final String policyId;

  const FluxSchedule({
    this.ttlSeconds = 60,
    this.rotationSeconds = 300,
    this.doubleFlux = false,
    this.maxIpsPerWindow = 32,
    this.maxNsPerWindow = 8,
    this.policyId = 'lab-fast-flux',
  });

  /// Double-flux preset (short TTL + NS churn).
  const FluxSchedule.doubleFlux({
    this.ttlSeconds = 30,
    this.rotationSeconds = 180,
    this.maxIpsPerWindow = 64,
    this.maxNsPerWindow = 16,
    this.policyId = 'lab-double-flux',
  }) : doubleFlux = true;

  /// Serialize into DGA / PQ result metadata (non-secret).
  Map<String, dynamic> toMetadata() => {
    'flux_policy_id': policyId,
    'flux_ttl_seconds': ttlSeconds,
    'flux_rotation_seconds': rotationSeconds,
    'flux_double': doubleFlux,
    'flux_max_ips_per_window': maxIpsPerWindow,
    'flux_max_ns_per_window': maxNsPerWindow,
    'needs_infra_correlation': true,
  };
}
