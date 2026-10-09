import 'dart:convert';
import 'dart:typed_data';

import 'package:pqdga/src/post_quantum/crypto/dns_label_codec.dart';
import 'package:pqdga/src/post_quantum/crypto/kmac256.dart';
import 'package:pqdga/src/post_quantum/crypto/shake_xof.dart';
import 'package:pqdga/src/post_quantum/pqdga_core.dart';

/// One indexed share in a lab threshold set (not a live TSS protocol).
class ThresholdShare {
  /// 1-based share index.
  final int index;

  /// Share bytes (never log).
  final Uint8List material;

  const ThresholdShare({required this.index, required this.material});
}

/// Threshold k-of-n PQDGA (binding ladder R9f).
///
/// Lab model (synthetic shares, not production TSS):
/// * Dealer samples master `M`.
/// * Share `i` = KMAC/SHAKE(M, "share"‖i).
/// * Any **k** distinct shares recombine (sorted by index) into a binding key
///   that depends on the chosen index set **and** is stable for that set.
///
/// Research: how does increasing required participants affect resilience,
/// recovery, synchronization, and operational complexity?
///
/// **Not** the same as multi-recipient KEM wrap.
/// Never log master or shares.
class ThresholdPqdga extends PQDGAAlgorithm {
  final String campaignId;
  final List<String> tld;
  final String charset;
  final String domainSeparator;
  final String kdf;
  final String kmacCustomization;

  /// Threshold k (need ≥ k shares).
  final int threshold;

  /// Total n in the dealing (metadata).
  final int totalShares;

  /// Presented shares for this generation attempt.
  final List<ThresholdShare> shares;

  /// Optional pre-combined binding key.
  final Uint8List? bindingKey;

  final String groupId;

  const ThresholdPqdga({
    this.campaignId = 'toy-campaign',
    this.tld = const ['.com', '.net', '.org'],
    this.charset = DnsLabelCodec.defaultCharset,
    this.domainSeparator = 'pqdga/v1/threshold',
    this.kdf = 'KMAC256',
    this.kmacCustomization = 'pqdga/v1/threshold',
    this.threshold = 2,
    this.totalShares = 3,
    this.shares = const [],
    this.bindingKey,
    this.groupId = 'lab-threshold',
  });

  /// Deal n shares from master (lab only).
  static List<ThresholdShare> dealShares({
    required Uint8List master,
    required int totalShares,
    String kdf = 'KMAC256',
    String kmacCustomization = 'pqdga/v1/threshold',
    String domainSeparator = 'pqdga/v1/threshold',
  }) {
    if (totalShares < 1) {
      throw ArgumentError.value(totalShares, 'totalShares', 'must be >= 1');
    }
    final out = <ThresholdShare>[];
    for (var i = 1; i <= totalShares; i++) {
      final info = Uint8List.fromList([
        ...utf8.encode(domainSeparator),
        0x00,
        ...utf8.encode('share'),
        0x00,
        (i >> 8) & 0xff,
        i & 0xff,
      ]);
      final k = kdf.toUpperCase();
      late final Uint8List mat;
      if (k == 'KMAC256') {
        mat = Kmac256.macUtf8(
          key: master,
          data: info,
          outputLengthBytes: 32,
          customization: kmacCustomization,
        );
      } else if (k == 'SHAKE256') {
        mat = ShakeXof.shake256(
          Uint8List.fromList([...master, 0x00, ...info]),
          32,
        );
      } else {
        throw ArgumentError('unsupported kdf "$kdf"');
      }
      out.add(ThresholdShare(index: i, material: mat));
    }
    return out;
  }

  /// Combine ≥ k shares into binding key (sorted by index).
  static Uint8List combineShares({
    required List<ThresholdShare> shares,
    required int threshold,
    String kdf = 'KMAC256',
    String kmacCustomization = 'pqdga/v1/threshold',
    String domainSeparator = 'pqdga/v1/threshold',
  }) {
    if (threshold < 1) {
      throw ArgumentError.value(threshold, 'threshold', 'must be >= 1');
    }
    if (shares.length < threshold) {
      throw ArgumentError(
        'need at least $threshold shares, got ${shares.length}',
      );
    }
    final seen = <int>{};
    for (final s in shares) {
      if (s.index < 1) {
        throw ArgumentError('share index must be >= 1');
      }
      if (s.material.isEmpty) {
        throw ArgumentError('share material must be non-empty');
      }
      if (!seen.add(s.index)) {
        throw ArgumentError('duplicate share index ${s.index}');
      }
    }
    final ordered = List<ThresholdShare>.from(shares)
      ..sort((a, b) => a.index.compareTo(b.index));
    // Use exactly the first `threshold` after sort for stability when more
    // than k are presented (lab convention).
    final selected = ordered.take(threshold).toList();

    final packed = <int>[
      ...utf8.encode(domainSeparator),
      0x00,
      threshold & 0xff,
      selected.length & 0xff,
    ];
    for (final s in selected) {
      packed.addAll([
        (s.index >> 8) & 0xff,
        s.index & 0xff,
        (s.material.length >> 8) & 0xff,
        s.material.length & 0xff,
        ...s.material,
      ]);
    }
    final data = Uint8List.fromList(packed);
    final k = kdf.toUpperCase();
    if (k == 'KMAC256') {
      return Kmac256.macUtf8(
        key: selected.first.material,
        data: data,
        outputLengthBytes: 32,
        customization: kmacCustomization,
      );
    }
    if (k == 'SHAKE256') {
      return ShakeXof.shake256(data, 32);
    }
    throw ArgumentError('unsupported kdf "$kdf"');
  }

  /// Lab helper: deal n shares, present first k.
  static ThresholdLabSession labEstablish({
    Uint8List? master,
    int threshold = 2,
    int totalShares = 3,
    String campaignId = 'toy-campaign',
    List<String> tld = const ['.com', '.net', '.org'],
    String charset = DnsLabelCodec.defaultCharset,
    String domainSeparator = 'pqdga/v1/threshold',
    String kdf = 'KMAC256',
    String kmacCustomization = 'pqdga/v1/threshold',
    String groupId = 'lab-threshold',
  }) {
    if (threshold < 1 || threshold > totalShares) {
      throw ArgumentError('threshold $threshold must be in 1..$totalShares');
    }
    final m =
        master ??
        Uint8List.fromList(List<int>.generate(32, (i) => 0xE0 + (i & 0x0f)));
    final all = dealShares(
      master: m,
      totalShares: totalShares,
      kdf: kdf,
      kmacCustomization: kmacCustomization,
      domainSeparator: domainSeparator,
    );
    final presented = all.take(threshold).toList();
    final binding = combineShares(
      shares: presented,
      threshold: threshold,
      kdf: kdf,
      kmacCustomization: kmacCustomization,
      domainSeparator: domainSeparator,
    );
    final algo = ThresholdPqdga(
      campaignId: campaignId,
      tld: tld,
      charset: charset,
      domainSeparator: domainSeparator,
      kdf: kdf,
      kmacCustomization: kmacCustomization,
      threshold: threshold,
      totalShares: totalShares,
      shares: presented,
      bindingKey: binding,
      groupId: groupId,
    );
    return ThresholdLabSession(
      algorithm: algo,
      master: m,
      allShares: all,
      bindingKey: binding,
    );
  }
}

/// Lab materials for [ThresholdPqdga].
class ThresholdLabSession {
  final ThresholdPqdga algorithm;
  final Uint8List master;
  final List<ThresholdShare> allShares;
  final Uint8List bindingKey;

  const ThresholdLabSession({
    required this.algorithm,
    required this.master,
    required this.allShares,
    required this.bindingKey,
  });

  /// Present a specific subset of share indices (1-based).
  ThresholdPqdga withShareIndices(List<int> indices) {
    final map = {for (final s in allShares) s.index: s};
    final selected = <ThresholdShare>[];
    for (final i in indices) {
      final s = map[i];
      if (s == null) {
        throw ArgumentError('unknown share index $i');
      }
      selected.add(s);
    }
    return ThresholdPqdga(
      campaignId: algorithm.campaignId,
      tld: algorithm.tld,
      charset: algorithm.charset,
      domainSeparator: algorithm.domainSeparator,
      kdf: algorithm.kdf,
      kmacCustomization: algorithm.kmacCustomization,
      threshold: algorithm.threshold,
      totalShares: algorithm.totalShares,
      shares: selected,
      groupId: algorithm.groupId,
    );
  }
}
