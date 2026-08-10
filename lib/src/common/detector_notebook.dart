import 'package:pqdga/src/classical/dga_result.dart';
import 'package:pqdga/src/common/hardness_scorecard.dart';
import 'package:pqdga/src/common/soc_features.dart';
import 'package:pqdga/src/post_quantum/crypto/slh_dsa_provider.dart';
import 'package:pqdga/src/post_quantum/crypto/slh_dsa_sizes.dart';
import 'package:pqdga/src/post_quantum/lab/post_rendezvous_session.dart';
import 'package:pqdga/src/post_quantum/pqdga_result.dart';

/// Notebook / detector integration surface for SOC lab tooling.
///
/// Single entry that packages per-domain features, batch stats, IOC templates,
/// hardness H1–H7, and optional post-rendezvous session IOCs — so external
/// notebooks need not re-implement metadata walks.
class DetectorNotebook {
  DetectorNotebook._();

  /// Full classical consumer payload.
  static Map<String, dynamic> fromDga(DGAResult result) {
    final hard = HardnessScorecard.fromDgaResult(result);
    final batch = SocFeatures.fromDgaResult(result);
    final perDomain = [
      for (final d in result.domains) SocFeatures.forDomain(d).toJson(),
    ];
    return {
      'kind': 'classical',
      'algorithm': result.algorithm,
      'seed': result.seed,
      'generation_date': result.generationDate.toUtc().toIso8601String(),
      'domains': List<String>.from(result.domains),
      'per_domain_features': perDomain,
      'batch': batch.toJson(),
      'ioc': SocFeatures.iocTemplateFromDga(result),
      'hardness': hard.toJson(),
      'hardness_line': hard.summaryLine,
      'playbook_flags': _mapOrEmpty(result.metadata['playbook_flags']),
      'predictability': result.metadata['predictability'],
      'soc_lesson': result.metadata['soc_lesson'],
      'legend': hardnessLegend(),
    };
  }

  /// Full PQ consumer payload.
  static Map<String, dynamic> fromPqdga(PQDGAResult result) {
    final hard = HardnessScorecard.fromPqdgaResult(result);
    final batch = SocFeatures.fromPqdgaResult(result);
    final perDomain = [
      for (final d in result.domains) SocFeatures.forDomain(d).toJson(),
    ];
    return {
      'kind': 'post_quantum',
      'algorithm': result.algorithm,
      'seed': result.seed,
      'generation_date': result.generationDate.toUtc().toIso8601String(),
      'domains': List<String>.from(result.domains),
      'predictable': result.predictable,
      'secret_bound': result.secretBound,
      'epoch': result.epoch,
      'xof': result.xof,
      'kem_algorithm': result.kemAlgorithm,
      'kem_ciphertext_length': result.kemCiphertextLength,
      'sig_algorithm': result.sigAlgorithm,
      'signature_length': result.signatureLength,
      'pubkey_fingerprint': result.pubkeyFingerprint,
      'binding_ladder': result.metadata['binding_ladder'],
      'binding_mode': result.metadata['binding_mode'],
      'per_domain_features': perDomain,
      'batch': batch.toJson(),
      'ioc': SocFeatures.iocTemplateFromPqdga(result),
      'hardness': hard.toJson(),
      'hardness_line': hard.summaryLine,
      'playbook_flags': _mapOrEmpty(result.metadata['playbook_flags']),
      'soc_lesson': result.metadata['soc_lesson'],
      'legend': hardnessLegend(),
    };
  }

  /// Attach post-rendezvous session IOC (not a DGA) beside a PQ result.
  static Map<String, dynamic> withPostRendezvous(
    PQDGAResult result,
    PostRendezvousSession session, {
    int? lastPacketLength,
  }) {
    final base = fromPqdga(result);
    base['post_rendezvous'] = session.iocTemplate(
      lastPacketLength: lastPacketLength,
    );
    return base;
  }

  /// SLH-DSA size table block for notebooks (sizes from pqcrypto params).
  static Map<String, dynamic> slhDsaSizeIocs() => {
        'kind': 'slh_dsa_size_catalog',
        'crypto_status': SlhDsaProvider.cryptoStatus,
        'primitive': SlhDsaProvider.backendId,
        'pqforge_exposes_slh_dsa': SlhDsaProvider.pqforgeExposesSlhDsa,
        'parameter_sets': SlhDsaSizes.sizeTable(),
        'vs_ml_dsa': SlhDsaSizes.compareToMlDsa(),
      };

  /// Explain why classical lines may show all-zero hardness.
  static Map<String, String> hardnessLegend() => {
        'H1': 'Unpredictable without secret (0 = date/config public precompute)',
        'H2': 'Unforgeable C2 / signatures required',
        'H3': 'Forward / rotation hardness (ratchet experimental = 1)',
        'H4': 'Hybrid classical+PQ required',
        'H5': 'Low lexical observability (dictionary/Markov/IDN)',
        'H6': 'Channel agility beyond DNS RPZ',
        'H7': 'Anti-sinkhole app-level trust (sig / session)',
        'zeros_ok':
            'All-zero hardness is correct for trivial classical and public '
            'QuantumResistant — teaches precompute wins and PQ hash ≠ secret',
      };

  /// Compact CSV-ish rows for spreadsheet notebooks.
  static List<Map<String, dynamic>> hardnessRows({
    DGAResult? dga,
    PQDGAResult? pqdga,
  }) {
    final rows = <Map<String, dynamic>>[];
    if (dga != null) {
      final h = HardnessScorecard.fromDgaResult(dga);
      rows.add({
        'family': dga.algorithm,
        ...h.scores,
        'counters': h.counters.join('|'),
      });
    }
    if (pqdga != null) {
      final h = HardnessScorecard.fromPqdgaResult(pqdga);
      rows.add({
        'family': pqdga.algorithm,
        ...h.scores,
        'counters': h.counters.join('|'),
      });
    }
    return rows;
  }

  static Map<String, dynamic> _mapOrEmpty(Object? v) {
    if (v is Map<String, dynamic>) return Map<String, dynamic>.from(v);
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), val));
    }
    return {};
  }
}
