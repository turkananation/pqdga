/// FIPS 205 SLH-DSA parameter catalog backed by [pqcrypto] [SlhDsaParams].
///
/// **Primitive source:** real sizes and crypto come from `pqcrypto` 0.4+
/// ([SlhDsa] / [SlhDsaParams]). This module is a thin lab catalog + IOC table —
/// it does **not** reimplement SLH-DSA. Prefer [pqforge] when it exposes SLH-DSA;
/// until then hook [SlhDsa] from pqcrypto directly.
///
/// Checkpoint bodies from [SlhDsaCheckpointPqdga] are **real FIPS 205
/// signatures** when keys are supplied (lab ephemeral only).
library;

import 'package:pqforge/pqforge.dart';


/// One SLH-DSA parameter set for lab IOC / algorithm config.
///
/// Wraps [SlhDsaParams] so callers can stay on a stable pqdga surface.
class SlhDsaParameterSet {
  /// Stable lab id (lowercase, e.g. `slh-dsa-shake-128f`).
  final String id;

  /// NIST display name from [SlhDsaParams.name].
  final String name;

  /// Underlying pqcrypto parameter set (source of truth for sizes).
  final SlhDsaParams params;

  const SlhDsaParameterSet({
    required this.id,
    required this.name,
    required this.params,
  });

  int get securityCategory => params.securityCategory;
  int get publicKeyBytes => params.publicKeyBytes;
  int get secretKeyBytes => params.secretKeyBytes;
  int get signatureBytes => params.signatureBytes;
  bool get isFast => params.isFast;
  SlhDsaHashFamily get hashFamily => params.hashFamily;
}

/// NIST FIPS 205 SLH-DSA sizes / ids used as lab IOC templates.
class SlhDsaSizes {
  SlhDsaSizes._();

  static const slhDsaSha2_128s = SlhDsaParameterSet(
    id: 'slh-dsa-sha2-128s',
    name: 'SLH-DSA-SHA2-128s',
    params: SlhDsaParams.sha2128s,
  );

  static const slhDsaSha2_128f = SlhDsaParameterSet(
    id: 'slh-dsa-sha2-128f',
    name: 'SLH-DSA-SHA2-128f',
    params: SlhDsaParams.sha2128f,
  );

  static const slhDsaSha2_192s = SlhDsaParameterSet(
    id: 'slh-dsa-sha2-192s',
    name: 'SLH-DSA-SHA2-192s',
    params: SlhDsaParams.sha2192s,
  );

  static const slhDsaSha2_192f = SlhDsaParameterSet(
    id: 'slh-dsa-sha2-192f',
    name: 'SLH-DSA-SHA2-192f',
    params: SlhDsaParams.sha2192f,
  );

  static const slhDsaSha2_256s = SlhDsaParameterSet(
    id: 'slh-dsa-sha2-256s',
    name: 'SLH-DSA-SHA2-256s',
    params: SlhDsaParams.sha2256s,
  );

  static const slhDsaSha2_256f = SlhDsaParameterSet(
    id: 'slh-dsa-sha2-256f',
    name: 'SLH-DSA-SHA2-256f',
    params: SlhDsaParams.sha2256f,
  );

  static const slhDsaShake_128s = SlhDsaParameterSet(
    id: 'slh-dsa-shake-128s',
    name: 'SLH-DSA-SHAKE-128s',
    params: SlhDsaParams.shake128s,
  );

  static const slhDsaShake_128f = SlhDsaParameterSet(
    id: 'slh-dsa-shake-128f',
    name: 'SLH-DSA-SHAKE-128f',
    params: SlhDsaParams.shake128f,
  );

  static const slhDsaShake_192s = SlhDsaParameterSet(
    id: 'slh-dsa-shake-192s',
    name: 'SLH-DSA-SHAKE-192s',
    params: SlhDsaParams.shake192s,
  );

  static const slhDsaShake_192f = SlhDsaParameterSet(
    id: 'slh-dsa-shake-192f',
    name: 'SLH-DSA-SHAKE-192f',
    params: SlhDsaParams.shake192f,
  );

  static const slhDsaShake_256s = SlhDsaParameterSet(
    id: 'slh-dsa-shake-256s',
    name: 'SLH-DSA-SHAKE-256s',
    params: SlhDsaParams.shake256s,
  );

  static const slhDsaShake_256f = SlhDsaParameterSet(
    id: 'slh-dsa-shake-256f',
    name: 'SLH-DSA-SHAKE-256f',
    params: SlhDsaParams.shake256f,
  );

  /// Default lab set: fast `f` parameter (multi-KB IOC without slow `s` path).
  static const defaultSet = slhDsaShake_128f;

  static const List<SlhDsaParameterSet> all = [
    slhDsaSha2_128s,
    slhDsaSha2_128f,
    slhDsaSha2_192s,
    slhDsaSha2_192f,
    slhDsaSha2_256s,
    slhDsaSha2_256f,
    slhDsaShake_128s,
    slhDsaShake_128f,
    slhDsaShake_192s,
    slhDsaShake_192f,
    slhDsaShake_256s,
    slhDsaShake_256f,
  ];

  static SlhDsaParameterSet byId(String id) {
    final q = id.trim().toLowerCase();
    for (final p in all) {
      if (p.id == q || p.name.toLowerCase() == q) return p;
    }
    // Also accept bare NIST names without prefix normalization.
    for (final p in all) {
      if (p.params.name.toLowerCase() == q) return p;
    }
    throw ArgumentError('Unknown SLH-DSA parameter set: $id');
  }

  /// Compact size table for IOC notebooks / hardness docs.
  static List<Map<String, Object>> sizeTable() => [
        for (final p in all)
          {
            'id': p.id,
            'name': p.name,
            'category': p.securityCategory,
            'pk_bytes': p.publicKeyBytes,
            'sk_bytes': p.secretKeyBytes,
            'sig_bytes': p.signatureBytes,
            'is_fast': p.isFast,
            'hash_family': p.hashFamily.name,
            'primitive': 'pqcrypto.SlhDsa',
          },
      ];

  /// Compare ML-DSA vs SLH-DSA signature lengths (IOC training).
  static Map<String, Object> compareToMlDsa({
    int mlDsa44 = 2420,
    int mlDsa65 = 3309,
    int mlDsa87 = 4627,
    SlhDsaParameterSet slh = defaultSet,
  }) =>
      {
        'ml_dsa_44_sig': mlDsa44,
        'ml_dsa_65_sig': mlDsa65,
        'ml_dsa_87_sig': mlDsa87,
        'slh_dsa_id': slh.id,
        'slh_dsa_sig': slh.signatureBytes,
        'slh_vs_ml_dsa_65_ratio':
            (slh.signatureBytes / mlDsa65).toStringAsFixed(2),
        'note':
            'SLH-DSA sigs are multi-KB → excellent passive size IOCs vs ML-DSA',
        'primitive': 'pqcrypto.SlhDsa',
      };
}
