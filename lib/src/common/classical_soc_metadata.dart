import 'package:pqdga/src/common/predictability.dart';

/// Canonical classical [DGAResult.metadata] keys and playbook flags.
///
/// Keeps baseline malware-style, generics, P0–P2, and research families on the
/// same analyst contract as PQ results (predictability + playbook_flags + IOC).
class ClassicalSocMetadata {
  ClassicalSocMetadata._();

  /// Build nested playbook flags from predictability + optional specialty flags.
  static Map<String, dynamic> playbookFlags({
    required PredictabilityClass predictability,
    bool needsLexicalModel = false,
    bool needsConfigExtract = false,
    bool needsAltChannelTelemetry = false,
    bool needsIdnMonitoring = false,
    bool needsFluxCorrelation = false,
    bool requiresSignature = false,
  }) {
    final configExtract = needsConfigExtract ||
        predictability == PredictabilityClass.configSeeded;
    final sinkhole = predictability == PredictabilityClass.trivial ||
        predictability == PredictabilityClass.configSeeded;
    return {
      'sinkhole_precompute': sinkhole,
      'needs_config_extract': configExtract,
      'needs_lexical_model': needsLexicalModel,
      'needs_behavioral_detection':
          predictability == PredictabilityClass.secretSeeded ||
              predictability == PredictabilityClass.oracleSeeded,
      'needs_oracle_feed': predictability == PredictabilityClass.oracleSeeded,
      'requires_signature': requiresSignature,
      if (needsAltChannelTelemetry) 'needs_alt_channel_telemetry': true,
      if (needsIdnMonitoring) 'needs_idn_monitoring': true,
      if (needsFluxCorrelation) 'needs_flux_correlation': true,
    };
  }

  /// Standard classical metadata map (merge [extra] last for family-specific keys).
  static Map<String, dynamic> build({
    required PredictabilityClass predictability,
    String? charset,
    int? lengthMin,
    int? lengthMax,
    List<String>? tldSet,
    String? seedPacking,
    String? prng,
    String? socLesson,
    int? domainsPerDay,
    bool needsLexicalModel = false,
    bool needsConfigExtract = false,
    bool needsAltChannelTelemetry = false,
    bool needsIdnMonitoring = false,
    bool needsFluxCorrelation = false,
    bool requiresSignature = false,
    Map<String, dynamic>? extra,
  }) {
    final flags = playbookFlags(
      predictability: predictability,
      needsLexicalModel: needsLexicalModel,
      needsConfigExtract: needsConfigExtract,
      needsAltChannelTelemetry: needsAltChannelTelemetry,
      needsIdnMonitoring: needsIdnMonitoring,
      needsFluxCorrelation: needsFluxCorrelation,
      requiresSignature: requiresSignature,
    );
    final map = <String, dynamic>{
      'charset': ?charset,
      'length_min': ?lengthMin,
      'length_max': ?lengthMax,
      if (tldSet != null) 'tld_set': List<String>.from(tldSet),
      'seed_packing': ?seedPacking,
      'prng': ?prng,
      'domains_per_day': ?domainsPerDay,
      'predictability': predictability.wireName,
      // Offline precompute without sample config/oracle/secret.
      'predictable': predictability == PredictabilityClass.trivial,
      'secret_bound': predictability == PredictabilityClass.secretSeeded,
      'playbook_flags': flags,
      if (needsLexicalModel) 'needs_lexical_model': true,
      // Promote oracle flag to top-level for notebook/test consumers (also in flags).
      if (predictability == PredictabilityClass.oracleSeeded)
        'needs_oracle_feed': true,
      'soc_lesson': ?socLesson,
    };
    if (extra != null && extra.isNotEmpty) {
      map.addAll(extra);
      // Preserve nested flags if extra overwrote with partial map.
      final extraFlags = extra['playbook_flags'];
      if (extraFlags is Map) {
        map['playbook_flags'] = {
          ...flags,
          ...extraFlags.map((k, v) => MapEntry(k.toString(), v)),
        };
      }
    }
    return map;
  }

  /// Merge standard keys onto an existing family metadata map (P0/P1/R8 polish).
  static Map<String, dynamic> enrich(
    Map<String, dynamic> existing, {
    required PredictabilityClass predictability,
    bool needsLexicalModel = false,
    bool needsConfigExtract = false,
    bool needsAltChannelTelemetry = false,
    bool needsIdnMonitoring = false,
    bool needsFluxCorrelation = false,
    String? socLesson,
  }) {
    final base = build(
      predictability: predictability,
      needsLexicalModel: needsLexicalModel ||
          existing['needs_lexical_model'] == true,
      needsConfigExtract: needsConfigExtract,
      needsAltChannelTelemetry: needsAltChannelTelemetry ||
          existing['needs_alt_channel_telemetry'] == true,
      needsIdnMonitoring: needsIdnMonitoring,
      needsFluxCorrelation: needsFluxCorrelation,
      socLesson: socLesson ?? existing['soc_lesson']?.toString(),
      extra: existing,
    );
    return base;
  }
}
