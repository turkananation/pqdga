import 'dart:convert';
import 'dart:typed_data';

import 'package:pqforge/pqforge.dart';
import 'package:pqdga/src/post_quantum/algorithms/hybrid_shared_secret_pqdga.dart';
import 'package:pqdga/src/post_quantum/crypto/dns_label_codec.dart';
import 'package:pqdga/src/post_quantum/pqdga_core.dart';

/// Hybrid classical + PQ session key expanded with KMAC256 (binding ladder R9b).
///
/// Same combiner story as [HybridSharedSecretPqdga] (classical ‖ ML-KEM →
/// session key), but labels expand via **KMAC256** rather than raw SHAKE.
/// Research: transition-period properties when both classical and PQ material
/// are required **and** expansion is keyed/domain-separated.
///
/// Never log session keys or component secrets.
class HybridKmacPqdga extends PQDGAAlgorithm {
  final String campaignId;
  final List<String> tld;
  final String charset;

  /// Context domain-separation packed into KMAC data.
  final String domainSeparator;

  /// KMAC customization string `S`.
  final String kmacCustomization;

  /// KDF id (`KMAC256`).
  final String kdf;

  final Uint8List? hybridSessionKey;
  final Uint8List? classicalSharedSecret;
  final Uint8List? postQuantumSharedSecret;
  final PqKemAlgorithm kemAlgorithm;
  final Uint8List? kemCiphertext;
  final String classicalAlgorithm;
  final String combinerInfo;
  final Uint8List? combinerSalt;
  final String combinerProfile;

  const HybridKmacPqdga({
    this.campaignId = 'toy-campaign',
    this.tld = const ['.com', '.net', '.org'],
    this.charset = DnsLabelCodec.defaultCharset,
    this.domainSeparator = 'pqdga/v1/hybrid-kmac',
    this.kmacCustomization = 'pqdga/v1/hybrid-kmac',
    this.kdf = 'KMAC256',
    this.hybridSessionKey,
    this.classicalSharedSecret,
    this.postQuantumSharedSecret,
    this.kemAlgorithm = PqKemAlgorithm.mlKem768,
    this.kemCiphertext,
    this.classicalAlgorithm = 'x25519',
    this.combinerInfo = 'pqdga/v1/hybrid',
    this.combinerSalt,
    this.combinerProfile = 'balanced',
  });

  /// Lab helper via [HybridSharedSecretPqdga.labEstablish] materials.
  static HybridKmacLabSession labEstablish({
    Uint8List? classicalSharedSecret,
    Uint8List? postQuantumSharedSecret,
    PqKemAlgorithm kemAlgorithm = PqKemAlgorithm.mlKem768,
    Uint8List? kemSeed,
    Uint8List? encapsNonce,
    String campaignId = 'toy-campaign',
    List<String> tld = const ['.com', '.net', '.org'],
    String charset = DnsLabelCodec.defaultCharset,
    String domainSeparator = 'pqdga/v1/hybrid-kmac',
    String kmacCustomization = 'pqdga/v1/hybrid-kmac',
    String classicalAlgorithm = 'x25519',
    String combinerInfo = 'pqdga/v1/hybrid',
    Uint8List? combinerSalt,
    String combinerProfile = 'balanced',
  }) {
    final base = HybridSharedSecretPqdga.labEstablish(
      classicalSharedSecret: classicalSharedSecret,
      postQuantumSharedSecret: postQuantumSharedSecret,
      kemAlgorithm: kemAlgorithm,
      kemSeed: kemSeed,
      encapsNonce: encapsNonce,
      campaignId: campaignId,
      tld: tld,
      charset: charset,
      domainSeparator: domainSeparator,
      classicalAlgorithm: classicalAlgorithm,
      combinerInfo: combinerInfo,
      combinerSalt: combinerSalt,
      combinerProfile: combinerProfile,
    );
    final algo = HybridKmacPqdga(
      campaignId: campaignId,
      tld: tld,
      charset: charset,
      domainSeparator: domainSeparator,
      kmacCustomization: kmacCustomization,
      hybridSessionKey: base.hybridSessionKey,
      classicalSharedSecret: base.classicalSharedSecret,
      postQuantumSharedSecret: base.postQuantumSharedSecret,
      kemAlgorithm: kemAlgorithm,
      kemCiphertext: base.kemCiphertext,
      classicalAlgorithm: classicalAlgorithm,
      combinerInfo: combinerInfo,
      combinerSalt: combinerSalt,
      combinerProfile: combinerProfile,
    );
    return HybridKmacLabSession(
      algorithm: algo,
      hybridSessionKey: base.hybridSessionKey,
      classicalSharedSecret: base.classicalSharedSecret,
      postQuantumSharedSecret: base.postQuantumSharedSecret,
      kemCiphertext: base.kemCiphertext,
      kemPublicKey: base.kemPublicKey,
      kemAlgorithm: kemAlgorithm,
    );
  }

  /// UTF-8 combiner info bytes (non-secret).
  Uint8List get combinerInfoBytes =>
      Uint8List.fromList(utf8.encode(combinerInfo));
}

/// Lab materials for [HybridKmacPqdga].
class HybridKmacLabSession {
  final HybridKmacPqdga algorithm;
  final Uint8List hybridSessionKey;
  final Uint8List classicalSharedSecret;
  final Uint8List postQuantumSharedSecret;
  final Uint8List? kemCiphertext;
  final Uint8List? kemPublicKey;
  final PqKemAlgorithm kemAlgorithm;

  const HybridKmacLabSession({
    required this.algorithm,
    required this.hybridSessionKey,
    required this.classicalSharedSecret,
    required this.postQuantumSharedSecret,
    required this.kemCiphertext,
    required this.kemPublicKey,
    required this.kemAlgorithm,
  });

  HybridKmacPqdga get asCombinerConfig => HybridKmacPqdga(
        campaignId: algorithm.campaignId,
        tld: algorithm.tld,
        charset: algorithm.charset,
        domainSeparator: algorithm.domainSeparator,
        kmacCustomization: algorithm.kmacCustomization,
        kdf: algorithm.kdf,
        classicalSharedSecret: classicalSharedSecret,
        postQuantumSharedSecret: postQuantumSharedSecret,
        kemAlgorithm: kemAlgorithm,
        kemCiphertext: kemCiphertext,
        classicalAlgorithm: algorithm.classicalAlgorithm,
        combinerInfo: algorithm.combinerInfo,
        combinerSalt: algorithm.combinerSalt,
        combinerProfile: algorithm.combinerProfile,
      );
}
