import 'dart:convert';
import 'dart:typed_data';

import 'package:pqdga/src/post_quantum/crypto/dns_label_codec.dart';
import 'package:pqdga/src/post_quantum/crypto/shake_xof.dart';
import 'package:pqdga/src/post_quantum/crypto/slh_dsa_sizes.dart';
import 'package:pqdga/src/post_quantum/pqdga_core.dart';
import 'package:pqforge/pqforge.dart';

/// SLH-DSA **checkpoint** lab family (post-R9 optional).
///
/// Emits secret-or-public-seed domains **and** detached FIPS 205 SLH-DSA
/// checkpoints via [SlhDsa] from **pqcrypto** (not reimplemented here;
/// pqforge 0.3.x does not expose SLH-DSA yet).
///
/// **SOC lesson:** multi-KB signature IOCs vs ML-DSA; sinkhole IP still fails
/// if the bot requires a valid SLH-DSA epoch seal. Metadata carries
/// `slh_dsa_crypto: fips-205-pqcrypto`.
///
/// Optional [checkpointEvery] attaches a real signature every N domains
/// (operator “epoch seal” drill). Slow `s` parameter sets need
/// [allowSlowSigning] = true.
///
/// Never log [secretKey].
class SlhDsaCheckpointPqdga extends PQDGAAlgorithm {
  final String campaignId;
  final List<String> tld;
  final String charset;
  final String domainSeparator;
  final String signatureDomainSeparator;
  final String xof;

  /// FIPS 205 parameter set (sizes + [SlhDsa] params from pqcrypto).
  final SlhDsaParameterSet parameterSet;

  /// When true, labels use only public epoch/campaign (predictable names).
  final bool seedPublic;

  /// Optional lab secret bound into label expand when [seedPublic] is false.
  final Uint8List? secretMaterial;

  /// Attach a real SLH-DSA checkpoint every N domains (default 1 = each).
  final int checkpointEvery;

  /// SLH-DSA secret key (required when [requireCheckpoint] is true).
  final Uint8List? secretKey;

  /// SLH-DSA public key (fingerprint + verify drills).
  final Uint8List? publicKey;

  /// When true (default), generation fails closed without a signing key.
  final bool requireCheckpoint;

  /// Required for slow `*-s` parameter sets (pqcrypto gate).
  final bool allowSlowSigning;

  /// Optional FIPS 205 context (max 255 bytes).
  final Uint8List? signContext;

  const SlhDsaCheckpointPqdga({
    this.campaignId = 'toy-campaign',
    this.tld = const ['.com', '.net', '.org'],
    this.charset = DnsLabelCodec.defaultCharset,
    this.domainSeparator = 'pqdga/v1/slh-checkpoint',
    this.signatureDomainSeparator = 'pqdga/v1/slh-sig',
    this.xof = 'SHAKE256',
    this.parameterSet = SlhDsaSizes.defaultSet,
    this.seedPublic = true,
    this.secretMaterial,
    this.checkpointEvery = 1,
    this.secretKey,
    this.publicKey,
    this.requireCheckpoint = true,
    this.allowSlowSigning = false,
    this.signContext,
  });

  /// Canonical message sealed by the SLH-DSA checkpoint.
  static Uint8List canonicalMessage({
    required String signatureDomainSeparator,
    required String domain,
    required String epoch,
    required String campaignId,
    required int counter,
  }) {
    return Uint8List.fromList(utf8.encode(
      '$signatureDomainSeparator|$domain|$epoch|$campaignId|$counter',
    ));
  }

  /// Short hex fingerprint of a verification key (config-extraction IOC).
  static String pubkeyFingerprintOf(Uint8List publicKey) {
    final digest = ShakeXof.shake256(publicKey, 16);
    final buffer = StringBuffer();
    for (final b in digest) {
      buffer.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  /// Lab helper: ephemeral SLH-DSA keygen via [SlhDsa.generateKeyPair].
  static SlhDsaCheckpointLabSession labEstablish({
    SlhDsaParameterSet parameterSet = SlhDsaSizes.defaultSet,
    String campaignId = 'toy-campaign',
    List<String> tld = const ['.com', '.net', '.org'],
    String charset = DnsLabelCodec.defaultCharset,
    bool seedPublic = true,
    Uint8List? secretMaterial,
    int checkpointEvery = 1,
    bool requireCheckpoint = true,
    bool allowSlowSigning = false,
    Uint8List? signContext,
  }) {
    final (pk, sk) = SlhDsa.generateKeyPair(parameterSet.params);
    final algo = SlhDsaCheckpointPqdga(
      campaignId: campaignId,
      tld: tld,
      charset: charset,
      parameterSet: parameterSet,
      seedPublic: seedPublic,
      secretMaterial: secretMaterial,
      checkpointEvery: checkpointEvery,
      secretKey: sk,
      publicKey: pk,
      requireCheckpoint: requireCheckpoint,
      allowSlowSigning: allowSlowSigning || !parameterSet.isFast,
      signContext: signContext,
    );
    return SlhDsaCheckpointLabSession(
      algorithm: algo,
      publicKey: pk,
      secretKey: sk,
      parameterSet: parameterSet,
    );
  }

  /// Verify a checkpoint with [SlhDsa.verify] (pqcrypto).
  static bool verifyCheckpoint({
    required Uint8List publicKey,
    required Uint8List message,
    required Uint8List signature,
    required SlhDsaParameterSet parameterSet,
    Uint8List? context,
  }) {
    return SlhDsa.verify(
      publicKey,
      message,
      signature,
      parameterSet.params,
      context: context ?? Uint8List(0),
    );
  }
}

/// Ephemeral SLH-DSA lab materials from [SlhDsaCheckpointPqdga.labEstablish].
class SlhDsaCheckpointLabSession {
  final SlhDsaCheckpointPqdga algorithm;
  final Uint8List publicKey;
  final Uint8List secretKey;
  final SlhDsaParameterSet parameterSet;

  const SlhDsaCheckpointLabSession({
    required this.algorithm,
    required this.publicKey,
    required this.secretKey,
    required this.parameterSet,
  });

  String get pubkeyFingerprint =>
      SlhDsaCheckpointPqdga.pubkeyFingerprintOf(publicKey);

  bool verify({
    required String domain,
    required String epoch,
    required int counter,
    required Uint8List signature,
    String? campaignId,
    Uint8List? context,
  }) {
    final message = SlhDsaCheckpointPqdga.canonicalMessage(
      signatureDomainSeparator: algorithm.signatureDomainSeparator,
      domain: domain,
      epoch: epoch,
      campaignId: campaignId ?? algorithm.campaignId,
      counter: counter,
    );
    return SlhDsaCheckpointPqdga.verifyCheckpoint(
      publicKey: publicKey,
      message: message,
      signature: signature,
      parameterSet: parameterSet,
      context: context ?? algorithm.signContext,
    );
  }
}
