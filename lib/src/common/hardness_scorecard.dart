import 'package:pqdga/src/classical/dga_result.dart';
import 'package:pqdga/src/common/predictability.dart';
import 'package:pqdga/src/post_quantum/pqdga_result.dart';

/// Adversarial hardness dimensions H1–H7 (see `doc/06-adversarial-hardness.md`).
///
/// Scores are **lab design ratings** (0 absent – 2 strong), not formal proofs.
class HardnessScorecard {
  /// H1 unpredictability without secret.
  final int h1;

  /// H2 unforgeability of C2 (signatures).
  final int h2;

  /// H3 forward secrecy / rotation of rendezvous.
  final int h3;

  /// H4 hybrid classical+PQ survival.
  final int h4;

  /// H5 low lexical observability.
  final int h5;

  /// H6 channel agility beyond DNS RPZ.
  final int h6;

  /// H7 anti-sinkhole (app-level trust).
  final int h7;

  /// Short counter tags for notebooks.
  final List<String> counters;

  const HardnessScorecard({
    required this.h1,
    required this.h2,
    required this.h3,
    required this.h4,
    required this.h5,
    required this.h6,
    required this.h7,
    this.counters = const [],
  });

  Map<String, int> get scores => {
    'H1': h1,
    'H2': h2,
    'H3': h3,
    'H4': h4,
    'H5': h5,
    'H6': h6,
    'H7': h7,
  };

  Map<String, dynamic> toJson() => {
    'hardness': scores,
    'counters': List<String>.from(counters),
  };

  /// Compact one-line summary for examples.
  String get summaryLine {
    final h = 'H1:$h1 H2:$h2 H3:$h3 H4:$h4 H5:$h5 H6:$h6 H7:$h7';
    final c = counters.isEmpty ? '' : ' counters=[${counters.join(',')}]';
    return 'hardness={$h}$c';
  }

  /// Infer a classical scorecard from result metadata + algorithm id.
  static HardnessScorecard fromDgaResult(DGAResult result) {
    final meta = result.metadata;
    final predWire =
        meta['predictability']?.toString() ??
        PredictabilityClass.trivial.wireName;
    final lexical =
        meta['needs_lexical_model'] == true ||
        _flag(meta, 'needs_lexical_model');
    final alt =
        meta['needs_alt_channel_telemetry'] == true ||
        _flag(meta, 'needs_alt_channel_telemetry');
    final flux =
        meta['needs_flux_correlation'] == true ||
        _flag(meta, 'needs_flux_correlation') ||
        meta.containsKey('ttl_seconds') ||
        meta.containsKey('flux_ttl_seconds');
    final idn =
        meta['needs_idn_monitoring'] == true ||
        _flag(meta, 'needs_idn_monitoring') ||
        result.algorithm.toLowerCase().contains('idn');
    final oracle = predWire == PredictabilityClass.oracleSeeded.wireName;
    final secret = predWire == PredictabilityClass.secretSeeded.wireName;

    final h1 = secret
        ? 2
        : oracle
        ? 1
        : 0;
    final h5 = lexical || idn
        ? 2
        : (result.algorithm.contains('Markov') ? 2 : 0);
    final h6 = alt ? 2 : 0;
    final counters = <String>[
      if (predWire == PredictabilityClass.trivial.wireName)
        'sinkhole_precompute',
      if (predWire == PredictabilityClass.configSeeded.wireName)
        'config_extract',
      if (lexical) 'lexical_model',
      if (oracle) 'oracle_feed',
      if (secret) 'behavior',
      if (alt) 'alt_channel',
      if (flux) 'flux_correlation',
      if (idn) 'idn_monitor',
    ];

    return HardnessScorecard(
      h1: h1,
      h2: 0,
      h3: oracle ? 1 : 0,
      h4: 0,
      h5: h5,
      h6: h6,
      h7: 0,
      counters: counters,
    );
  }

  /// Infer a PQ scorecard from [PQDGAResult] fields + metadata.
  static HardnessScorecard fromPqdgaResult(PQDGAResult result) {
    final meta = result.metadata;
    final binding = _bindingLadder(meta);
    final mode = meta['binding_mode']?.toString() ?? '';
    final algo = result.algorithm.toLowerCase();
    final requiresSig =
        meta['requires_signature'] == true ||
        _flag(meta, 'requires_signature') ||
        _flag(meta, 'needs_signature_verify') ||
        (result.signatures != null && result.signatures!.isNotEmpty);
    final hybrid =
        algo.contains('hybrid') || mode.contains('hybrid') || binding == 'R9b';
    final ratchet = binding == 'R9c' || mode.contains('ratchet');
    final multiChannel =
        _flag(meta, 'needs_alt_channel_telemetry') ||
        algo.contains('decentralized');
    final envelope = algo.contains('envelope');
    final authContext =
        binding == 'R9g' || mode.contains('authenticated-context');
    final identity = algo.contains('identity');
    final lexical =
        _flag(meta, 'needs_lexical_model') ||
        algo.contains('lexical') ||
        mode.contains('lexical');
    final slh =
        algo.contains('slh') ||
        meta['slh_dsa_crypto'] != null ||
        (result.sigAlgorithm?.toLowerCase().contains('slh') ?? false);
    final postSession =
        meta['post_rendezvous'] == true || _flag(meta, 'needs_secure_session');

    final h1 = result.secretBound
        ? 2
        : (identity ? 0 : (result.predictable ? 0 : 1));
    final h2 = requiresSig || authContext ? 2 : 0;
    final h3 = ratchet
        ? 1
        : (result.secretBound
              ? 2
              : 0); // rotation possible; ratchet experimental
    final h4 = hybrid ? 2 : 0;
    final h5 = lexical ? 2 : (envelope ? 1 : 0);
    final h6 = multiChannel ? 2 : (envelope ? 1 : 0);
    // SLH size-sim checkpoints teach large-sig IOCs; H2 only if real verify path.
    final h7 = requiresSig
        ? 2
        : (authContext || postSession ? 1 : (slh ? 1 : 0));

    final counters = <String>[
      if (result.predictable) 'sinkhole_precompute',
      if (result.secretBound) 'behavior',
      if (result.secretBound) 'pdns_first_seen',
      if (result.secretBound) 'registration',
      if (result.kemCiphertextLength != null || result.signatureLength != null)
        'ct_sizes',
      if (requiresSig || slh) 'pubkey_fingerprint',
      if (identity) 'config_extract_vk',
      if (hybrid) 'hybrid_config_ioc',
      if (ratchet) 'epoch_window',
      if (multiChannel) 'alt_channel',
      if (envelope) 'payload_crypto',
      if (lexical) 'lexical_model',
      if (slh) 'slh_dsa_size_ioc',
      if (postSession) 'secure_session',
      if (binding.isNotEmpty) 'binding_$binding',
    ];

    return HardnessScorecard(
      h1: h1,
      h2: h2,
      h3: h3,
      h4: h4,
      h5: h5,
      h6: h6,
      h7: h7,
      counters: counters,
    );
  }

  static String _bindingLadder(Map<String, dynamic> meta) {
    final top = meta['binding_ladder']?.toString();
    if (top != null && top.isNotEmpty) return top;
    final flags = meta['playbook_flags'];
    if (flags is Map && flags['binding_ladder'] != null) {
      return flags['binding_ladder'].toString();
    }
    return '';
  }

  static bool _flag(Map<String, dynamic> meta, String key) {
    final flags = meta['playbook_flags'];
    if (flags is Map && flags[key] == true) return true;
    return meta[key] == true;
  }
}
