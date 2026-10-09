import 'dart:convert';
import 'dart:typed_data';

import 'package:pqdga/src/post_quantum/crypto/dns_label_codec.dart';
import 'package:pqdga/src/post_quantum/crypto/kmac256.dart';
import 'package:pqdga/src/post_quantum/crypto/shake_xof.dart';
import 'package:pqdga/src/post_quantum/pqdga_core.dart';

/// Epoch-ratcheting secret-bound PQDGA (binding ladder R9c).
///
/// Instead of deriving every epoch independently from the same root, epoch
/// keys chain:
///
/// ```
/// root → epochKey_0 → epochKey_1 → … → epochKey_n
/// ```
///
/// Research question: if earlier epoch material is deleted after advancing,
/// can knowledge of a later epoch reconstruct earlier namespace material?
/// (Forward-evolution / delete-forward experiment — do **not** claim forward
/// secrecy until analyzed.)
///
/// Provide either:
/// * [epochKey] for the current epoch (after ratchet), or
/// * [rootSecret] + [epochIndex] to derive the chain in-lab.
///
/// Never log root or epoch keys.
class RatchetingPqdga extends PQDGAAlgorithm {
  final String campaignId;
  final List<String> tld;
  final String charset;
  final String domainSeparator;

  /// KDF id (`KMAC256` default; `SHAKE256` allowed as control arm).
  final String kdf;

  /// KMAC customization when [kdf] is KMAC256.
  final String kmacCustomization;

  /// Current epoch key (32 bytes typical). Prefer over exposing root.
  final Uint8List? epochKey;

  /// Root secret for lab chain derivation (never log).
  final Uint8List? rootSecret;

  /// Non-negative epoch index along the ratchet (0 = first child of root).
  final int epochIndex;

  /// Optional public ratchet id for metadata / IOC notebooks.
  final String ratchetId;

  const RatchetingPqdga({
    this.campaignId = 'toy-campaign',
    this.tld = const ['.com', '.net', '.org'],
    this.charset = DnsLabelCodec.defaultCharset,
    this.domainSeparator = 'pqdga/v1/ratchet',
    this.kdf = 'KMAC256',
    this.kmacCustomization = 'pqdga/v1/ratchet',
    this.epochKey,
    this.rootSecret,
    this.epochIndex = 0,
    this.ratchetId = 'lab-ratchet',
  });

  /// One ratchet step: parent key → child key at [nextIndex].
  static Uint8List ratchetStep({
    required Uint8List parentKey,
    required int nextIndex,
    String kdf = 'KMAC256',
    String kmacCustomization = 'pqdga/v1/ratchet',
    String domainSeparator = 'pqdga/v1/ratchet',
  }) {
    if (nextIndex < 0) {
      throw ArgumentError.value(nextIndex, 'nextIndex', 'must be >= 0');
    }
    final info = Uint8List.fromList([
      ...utf8.encode(domainSeparator),
      0x00,
      ...utf8.encode('epoch'),
      0x00,
      (nextIndex >> 24) & 0xff,
      (nextIndex >> 16) & 0xff,
      (nextIndex >> 8) & 0xff,
      nextIndex & 0xff,
    ]);
    final k = kdf.toUpperCase();
    if (k == 'KMAC256') {
      return Kmac256.macUtf8(
        key: parentKey,
        data: info,
        outputLengthBytes: 32,
        customization: kmacCustomization,
      );
    }
    if (k == 'SHAKE256') {
      final material = Uint8List.fromList([...parentKey, 0x00, ...info]);
      return ShakeXof.shake256(material, 32);
    }
    throw ArgumentError('unsupported kdf "$kdf"; use KMAC256 or SHAKE256');
  }

  /// Derive epoch key at [epochIndex] from [root] (0 = first step from root).
  static Uint8List deriveEpochKey({
    required Uint8List root,
    required int epochIndex,
    String kdf = 'KMAC256',
    String kmacCustomization = 'pqdga/v1/ratchet',
    String domainSeparator = 'pqdga/v1/ratchet',
  }) {
    if (epochIndex < 0) {
      throw ArgumentError.value(epochIndex, 'epochIndex', 'must be >= 0');
    }
    var key = Uint8List.fromList(root);
    for (var i = 0; i <= epochIndex; i++) {
      key = ratchetStep(
        parentKey: key,
        nextIndex: i,
        kdf: kdf,
        kmacCustomization: kmacCustomization,
        domainSeparator: domainSeparator,
      );
    }
    return key;
  }

  /// Lab helper: fixed root → derive epoch key at [epochIndex].
  static RatchetingLabSession labEstablish({
    Uint8List? rootSecret,
    int epochIndex = 0,
    String campaignId = 'toy-campaign',
    List<String> tld = const ['.com', '.net', '.org'],
    String charset = DnsLabelCodec.defaultCharset,
    String domainSeparator = 'pqdga/v1/ratchet',
    String kdf = 'KMAC256',
    String kmacCustomization = 'pqdga/v1/ratchet',
    String ratchetId = 'lab-ratchet',
  }) {
    if (epochIndex < 0) {
      throw ArgumentError.value(epochIndex, 'epochIndex', 'must be >= 0');
    }
    final root =
        rootSecret ??
        Uint8List.fromList(List<int>.generate(32, (i) => 0xC0 + (i & 0x0f)));
    final ek = deriveEpochKey(
      root: root,
      epochIndex: epochIndex,
      kdf: kdf,
      kmacCustomization: kmacCustomization,
      domainSeparator: domainSeparator,
    );
    final algo = RatchetingPqdga(
      campaignId: campaignId,
      tld: tld,
      charset: charset,
      domainSeparator: domainSeparator,
      kdf: kdf,
      kmacCustomization: kmacCustomization,
      epochKey: ek,
      rootSecret: root,
      epochIndex: epochIndex,
      ratchetId: ratchetId,
    );
    return RatchetingLabSession(
      algorithm: algo,
      rootSecret: root,
      epochKey: ek,
      epochIndex: epochIndex,
    );
  }
}

/// Lab materials for [RatchetingPqdga].
class RatchetingLabSession {
  final RatchetingPqdga algorithm;
  final Uint8List rootSecret;
  final Uint8List epochKey;
  final int epochIndex;

  const RatchetingLabSession({
    required this.algorithm,
    required this.rootSecret,
    required this.epochKey,
    required this.epochIndex,
  });

  /// Config holding only the current epoch key (simulates root deletion).
  RatchetingPqdga get asEpochOnlyConfig => RatchetingPqdga(
    campaignId: algorithm.campaignId,
    tld: algorithm.tld,
    charset: algorithm.charset,
    domainSeparator: algorithm.domainSeparator,
    kdf: algorithm.kdf,
    kmacCustomization: algorithm.kmacCustomization,
    epochKey: epochKey,
    epochIndex: epochIndex,
    ratchetId: algorithm.ratchetId,
  );

  /// Advance one step; caller should drop the prior epoch key for FS drills.
  RatchetingLabSession advance() {
    final next = epochIndex + 1;
    final nextKey = RatchetingPqdga.ratchetStep(
      parentKey: epochKey,
      nextIndex: next,
      kdf: algorithm.kdf,
      kmacCustomization: algorithm.kmacCustomization,
      domainSeparator: algorithm.domainSeparator,
    );
    final algo = RatchetingPqdga(
      campaignId: algorithm.campaignId,
      tld: algorithm.tld,
      charset: algorithm.charset,
      domainSeparator: algorithm.domainSeparator,
      kdf: algorithm.kdf,
      kmacCustomization: algorithm.kmacCustomization,
      epochKey: nextKey,
      rootSecret: rootSecret,
      epochIndex: next,
      ratchetId: algorithm.ratchetId,
    );
    return RatchetingLabSession(
      algorithm: algo,
      rootSecret: rootSecret,
      epochKey: nextKey,
      epochIndex: next,
    );
  }
}
