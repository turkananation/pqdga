/// Adversarial difficulty / SOC predictability class for generated names.
///
/// Bridges classical → PQ hardness ratings used in metadata and playbooks.
enum PredictabilityClass {
  /// Date-only or fully public seed — offline precompute works.
  trivial,

  /// Needs malware config constants / wordlists / magic seeds from sample.
  configSeeded,

  /// Seed from external public oracle stream (blockchain tip, trend hash, …).
  oracleSeeded,

  /// Requires non-public secret (e.g. ML-KEM shared secret).
  secretSeeded,
}

/// Wire / metadata string values (stable for SOC notebooks).
extension PredictabilityClassWire on PredictabilityClass {
  String get wireName {
    switch (this) {
      case PredictabilityClass.trivial:
        return 'trivial';
      case PredictabilityClass.configSeeded:
        return 'config-seeded';
      case PredictabilityClass.oracleSeeded:
        return 'oracle-seeded';
      case PredictabilityClass.secretSeeded:
        return 'secret-seeded';
    }
  }
}
