import 'dart:typed_data';

import 'package:pqdga/src/post_quantum/algorithms/hierarchical_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/kmac_shared_secret_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/multi_party_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/ratcheting_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/shared_secret_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/threshold_pqdga.dart';
import 'package:pqdga/src/post_quantum/pqdga_config.dart';
import 'package:pqdga/src/post_quantum/pqdga_generator.dart';
import 'package:pqdga/src/post_quantum/pqdga_result.dart';

/// In-process analysis drills for the R9 binding ladder (not formal proofs).
///
/// Implements the deferred “analysis notebooks” as callable lab routines:
/// KMAC vs SHAKE, ratchet delete-forward, hierarchy compartment, multi-party
/// vs threshold ops cost. Results are structured maps for detectors/docs.
///
/// **Claim discipline:** these experiments document *behavior under lab
/// assumptions*. They do **not** establish forward secrecy, production TSS
/// security, or novelty claims.
class BindingAnalysis {
  BindingAnalysis._();

  static final DateTime _labDate = DateTime.utc(2024, 6, 15);

  /// R9a vs R4: same ss → different domain lists under KMAC vs SHAKE expand.
  static Future<Map<String, dynamic>> kmacVsShake({
    Uint8List? sharedSecret,
    int count = 5,
  }) async {
    final ss =
        sharedSecret ??
        Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
    final ct = Uint8List(1088);
    final kmac = await PQDGAGenerator(
      PQDGAConfig(
        algorithm: KmacSharedSecretPqdga(
          sharedSecret: ss,
          campaignId: 'analysis-kmac',
          kemCiphertext: ct,
        ),
        minDomainLength: 8,
        maxDomainLength: 12,
        seedRotationDays: 1,
      ),
    ).generateDomains(_labDate, count);
    final shake = await PQDGAGenerator(
      PQDGAConfig(
        algorithm: SharedSecretPqdga(
          sharedSecret: ss,
          campaignId: 'analysis-kmac',
          kemCiphertext: ct,
        ),
        minDomainLength: 8,
        maxDomainLength: 12,
        seedRotationDays: 1,
      ),
    ).generateDomains(_labDate, count);

    final differ = !_listEq(kmac.domains, shake.domains);
    return {
      'experiment': 'R9a_kmac_vs_R4_shake',
      'same_secret': true,
      'same_campaign_epoch': true,
      'kmac_domains': kmac.domains,
      'shake_domains': shake.domains,
      'outputs_differ': differ,
      'kmac_kdf': kmac.xof,
      'shake_xof': shake.xof,
      'finding': differ
          ? 'KMAC domain-separated expand yields a distinct namespace from '
                'raw SHAKE absorb of the same ss‖context — construction delta is real.'
          : 'Unexpected collision — investigate expand inputs.',
      'security_claim': 'none — construction comparison only',
    };
  }

  /// R9c delete-forward: later epoch key must not regenerate earlier names.
  static Future<Map<String, dynamic>> ratchetDeleteForward({
    Uint8List? root,
    int earlyEpoch = 0,
    int lateEpoch = 3,
    int count = 3,
  }) async {
    final r =
        root ?? Uint8List.fromList(List<int>.generate(32, (i) => 0x40 + i));
    final earlyKey = RatchetingPqdga.deriveEpochKey(
      root: r,
      epochIndex: earlyEpoch,
    );
    final lateKey = RatchetingPqdga.deriveEpochKey(
      root: r,
      epochIndex: lateEpoch,
    );

    final early = await _ratchetDomains(earlyKey, earlyEpoch, count);
    final late = await _ratchetDomains(lateKey, lateEpoch, count);
    // Attempt: use late key but claim early epoch index in expand context.
    final spoofEarlyWithLateKey = await _ratchetDomains(
      lateKey,
      earlyEpoch,
      count,
    );

    final reconstructFails = !_listEq(
      spoofEarlyWithLateKey.domains,
      early.domains,
    );
    return {
      'experiment': 'R9c_ratchet_delete_forward',
      'early_epoch': earlyEpoch,
      'late_epoch': lateEpoch,
      'early_domains': early.domains,
      'late_domains': late.domains,
      'late_key_as_early_epoch_domains': spoofEarlyWithLateKey.domains,
      'later_key_reconstructs_earlier_names': !reconstructFails,
      'finding': reconstructFails
          ? 'With epoch index bound into expand, a later epoch key alone does '
                'not reproduce earlier names in this lab construction.'
          : 'Later key reproduced earlier names — weak binding; do not claim FS.',
      'security_claim':
          'NO forward-secrecy claim — lab observation under delete-forward drill only',
      'threat_model_status': 'open',
    };
  }

  /// R9d compartment: sibling hierarchy paths must not share namespaces.
  static Future<Map<String, dynamic>> hierarchyCompartment({
    Uint8List? root,
    int count = 3,
  }) async {
    final r =
        root ?? Uint8List.fromList(List<int>.generate(32, (i) => 0x10 + i));
    final a = HierarchicalPqdga.labEstablish(
      rootSecret: r,
      hierarchyPath: const ['region-a', 'team-1'],
    );
    final b = HierarchicalPqdga.labEstablish(
      rootSecret: r,
      hierarchyPath: const ['region-a', 'team-2'],
    );
    final c = HierarchicalPqdga.labEstablish(
      rootSecret: r,
      hierarchyPath: const ['region-b', 'team-1'],
    );

    final da = await _hier(a);
    final db = await _hier(b);
    final dc = await _hier(c);

    return {
      'experiment': 'R9d_hierarchy_compartment',
      'path_a': a.algorithm.hierarchyPath,
      'path_b': b.algorithm.hierarchyPath,
      'path_c': c.algorithm.hierarchyPath,
      'domains_a': da.domains,
      'domains_b': db.domains,
      'domains_c': dc.domains,
      'siblings_differ': !_listEq(da.domains, db.domains),
      'regions_differ': !_listEq(da.domains, dc.domains),
      'finding':
          (!_listEq(da.domains, db.domains) && !_listEq(da.domains, dc.domains))
          ? 'Sibling and cross-region leaves produce distinct namespaces from '
                'the same root — compartmentation holds in-lab.'
          : 'Unexpected namespace collision across hierarchy paths.',
      'security_claim': 'none — lab compartment drill',
    };
  }

  /// R9e/f ops cost: multi-party (all n) vs threshold (k-of-n) material counts.
  static Future<Map<String, dynamic>> multiPartyVsThresholdOps({
    int partyCount = 3,
    int threshold = 2,
    int totalShares = 3,
    int count = 2,
  }) async {
    final mp = MultiPartyPqdga.labEstablish(partyCount: partyCount);
    final th = ThresholdPqdga.labEstablish(
      threshold: threshold,
      totalShares: totalShares,
    );

    final mpRes = await PQDGAGenerator(
      PQDGAConfig(
        algorithm: mp.algorithm,
        minDomainLength: 8,
        maxDomainLength: 12,
      ),
    ).generateDomains(_labDate, count);
    final thRes = await PQDGAGenerator(
      PQDGAConfig(
        algorithm: th.algorithm,
        minDomainLength: 8,
        maxDomainLength: 12,
      ),
    ).generateDomains(_labDate, count);

    // Drop one multi-party secret → must fail closed.
    final incompleteSecrets = mp.algorithm.partySecrets.sublist(
      0,
      partyCount - 1,
    );
    var incompleteThrows = false;
    try {
      await PQDGAGenerator(
        PQDGAConfig(
          algorithm: MultiPartyPqdga(
            campaignId: mp.algorithm.campaignId,
            partySecrets: incompleteSecrets,
            minParties: partyCount,
          ),
          minDomainLength: 8,
          maxDomainLength: 12,
        ),
      ).generateDomains(_labDate, 1);
    } catch (_) {
      incompleteThrows = true;
    }

    return {
      'experiment': 'R9e_f_ops_cost',
      'multi_party': {
        'parties_required': partyCount,
        'domains': mpRes.domains,
        'incomplete_n_minus_1_fails': incompleteThrows,
      },
      'threshold': {
        'k': threshold,
        'n': totalShares,
        'domains': thRes.domains,
        'note': 'lab share deal/combine — not production TSS',
      },
      'ops_cost_observation': {
        'multi_party_sync_points': partyCount,
        'threshold_min_online': threshold,
        'threshold_allows_offline_parties': totalShares - threshold,
      },
      'finding':
          'Multi-party needs all $partyCount secrets online; threshold lab '
          'needs any $threshold of $totalShares — resilience vs sync tradeoff.',
      'security_claim':
          'NO production threshold signature / TSS claim — synthetic lab shares',
      'distinction':
          'MultiRecipient wrap ≠ MultiParty joint derivation ≠ Threshold k-of-n',
    };
  }

  /// Research writeup blurbs for notebooks (claim-disciplined).
  static Map<String, String> writeups() => {
    'R9a_kmac_vs_R4_shake':
        'Same shared secret and campaign/epoch context expand under KMAC256 '
        'vs raw SHAKE256 into **distinct** domain namespaces. This is a '
        'construction delta (domain separation), not a security proof. '
        'Detectors must not assume SHAKE precomputes cover KMAC campaigns.',
    'R9c_ratchet_delete_forward':
        'Later epoch keys with epoch index bound into expand do **not** '
        'reproduce earlier names in this lab construction. Observation only: '
        '**no forward-secrecy claim** without a full threat model (open).',
    'R9d_hierarchy_compartment':
        'Sibling hierarchy paths from the same root produce distinct '
        'namespaces in-lab (compartmentation drill). Not a formal isolation '
        'proof — validates path-bound expand behavior for SOC playbooks.',
    'R9e_f_ops_cost':
        'Multi-party needs all n secrets online; threshold lab needs any k of n. '
        'Resilience vs sync tradeoff. **Not production TSS.** Keep '
        'MultiRecipient wrap ≠ MultiParty joint ≠ Threshold k-of-n distinct.',
    'global_claim_discipline':
        'No novelty / first-PQ-DGA claims. Construction-class framing only. '
        'No FS claim (R9c). No production TSS (R9f).',
  };

  /// Run the full binding-ladder analysis suite.
  static Future<Map<String, dynamic>> runAll() async {
    final kmac = await kmacVsShake();
    final ratchet = await ratchetDeleteForward();
    final hier = await hierarchyCompartment();
    final ops = await multiPartyVsThresholdOps();
    return {
      'suite': 'binding_ladder_analysis',
      'date': _labDate.toIso8601String(),
      'experiments': {
        'kmac_vs_shake': kmac,
        'ratchet_delete_forward': ratchet,
        'hierarchy_compartment': hier,
        'multiparty_vs_threshold_ops': ops,
      },
      'global_claim_discipline': {
        'new_primitive': false,
        'first_pq_dga': false,
        'forward_secrecy': false,
        'production_tss': false,
        'framing':
            'construction-class research on secret-/group-/evolution-bound '
            'deterministic namespaces',
      },
    };
  }

  static Future<PQDGAResult> _ratchetDomains(
    Uint8List epochKey,
    int epochIndex,
    int count,
  ) {
    return PQDGAGenerator(
      PQDGAConfig(
        algorithm: RatchetingPqdga(
          epochKey: epochKey,
          epochIndex: epochIndex,
          campaignId: 'analysis-ratchet',
        ),
        minDomainLength: 8,
        maxDomainLength: 12,
      ),
    ).generateDomains(_labDate, count);
  }

  static Future<PQDGAResult> _hier(HierarchicalLabSession session) {
    return PQDGAGenerator(
      PQDGAConfig(
        algorithm: session.asLeafOnlyConfig,
        minDomainLength: 8,
        maxDomainLength: 12,
      ),
    ).generateDomains(_labDate, 3);
  }

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
