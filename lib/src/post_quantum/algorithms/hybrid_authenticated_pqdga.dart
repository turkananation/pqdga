import 'dart:convert';
import 'dart:typed_data';

import 'package:pqforge/pqforge.dart';
import 'package:pqdga/src/post_quantum/crypto/dns_label_codec.dart';
import 'package:pqdga/src/post_quantum/pqdga_core.dart';

/// Hybrid authenticity PQDGA: ML-DSA + classical (Ed25519) via [PqForgeHybridSigner].
///
/// Names expand like [SignatureAuthenticatedPqdga] (public or optional secret
/// seed). Each domain is dual-signed so **both** PQ and classical breaks are
/// required under `requireBoth` policy (H2 + partial H4 authenticity axis).
///
/// **SOC lesson:** hybrid signatures change IOC sizes (ML-DSA sig + 64-byte
/// Ed25519) and verification policy; sinkhole IP still fails if the bot
/// requires dual verify.
///
/// Never log secret keys.
class HybridAuthenticatedPqdga extends PQDGAAlgorithm {
  final String campaignId;
  final List<String> tld;
  final String charset;
  final bool seedPublic;
  final Uint8List? secretMaterial;
  final String domainSeparator;
  final String signatureDomainSeparator;
  final String xof;
  final PqSignatureAlgorithm pqcSignatureAlgorithm;
  final PqClassicalSignatureAlgorithm classicalAlgorithm;
  final Uint8List? pqcSecretKey;
  final Uint8List? pqcPublicKey;
  final Uint8List? classicalSecretKey;
  final Uint8List? classicalPublicKey;
  final bool requireSignature;
  final Uint8List? signContext;
  final PqDualSignaturePolicy dualPolicy;

  const HybridAuthenticatedPqdga({
    this.campaignId = 'toy-campaign',
    this.tld = const ['.com', '.net', '.org'],
    this.charset = DnsLabelCodec.defaultCharset,
    this.seedPublic = true,
    this.secretMaterial,
    this.domainSeparator = 'pqdga/v1/hybrid-auth',
    this.signatureDomainSeparator = 'pqdga/v1/hybrid-sig',
    this.xof = 'SHAKE256',
    this.pqcSignatureAlgorithm = PqSignatureAlgorithm.mlDsa65,
    this.classicalAlgorithm = PqClassicalSignatureAlgorithm.ed25519,
    this.pqcSecretKey,
    this.pqcPublicKey,
    this.classicalSecretKey,
    this.classicalPublicKey,
    this.requireSignature = true,
    this.signContext,
    this.dualPolicy = PqDualSignaturePolicy.requireBoth,
  });

  /// Canonical message signed by both algorithms.
  static Uint8List canonicalMessage({
    required String signatureDomainSeparator,
    required String domain,
    required String epoch,
    required String campaignId,
  }) {
    return Uint8List.fromList(utf8.encode(
      '$signatureDomainSeparator|$domain|$epoch|$campaignId',
    ));
  }

  static String pubkeyFingerprintOf(Uint8List pk) {
    final d = PqBytes.sha256(pk);
    return d
        .sublist(0, 8)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// Lab helper: ephemeral ML-DSA + Ed25519 keygen.
  static Future<HybridAuthenticatedLabSession> labEstablish({
    PqSignatureAlgorithm pqcAlgorithm = PqSignatureAlgorithm.mlDsa65,
    PqClassicalSignatureAlgorithm classicalAlgorithm =
        PqClassicalSignatureAlgorithm.ed25519,
    Uint8List? pqcSeed,
    Uint8List? classicalSeed,
    String campaignId = 'toy-campaign',
    List<String> tld = const ['.com', '.net', '.org'],
    String charset = DnsLabelCodec.defaultCharset,
    bool seedPublic = true,
    Uint8List? secretMaterial,
    String domainSeparator = 'pqdga/v1/hybrid-auth',
    String signatureDomainSeparator = 'pqdga/v1/hybrid-sig',
    String xof = 'SHAKE256',
    bool requireSignature = true,
    Uint8List? signContext,
    PqDualSignaturePolicy dualPolicy = PqDualSignaturePolicy.requireBoth,
  }) async {
    final forge = const PqForge();
    final pqcKp = pqcSeed == null
        ? forge.generateSignatureKeyPair(algorithm: pqcAlgorithm)
        : forge.generateSignatureKeyPairFromSeed(
            pqcSeed,
            algorithm: pqcAlgorithm,
          );
    final signer = PqForgeHybridSigner(
      profile: PqForgeProfile(
        name: 'pqdga-hybrid-auth',
        kem: PqKemAlgorithm.mlKem768,
        signature: pqcAlgorithm,
      ),
      classicalAlgorithm: classicalAlgorithm,
    );
    final classicalKp = await signer.generateClassicalKeyPair(
      seed: classicalSeed,
    );
    final algo = HybridAuthenticatedPqdga(
      campaignId: campaignId,
      tld: tld,
      charset: charset,
      seedPublic: seedPublic,
      secretMaterial: secretMaterial,
      domainSeparator: domainSeparator,
      signatureDomainSeparator: signatureDomainSeparator,
      xof: xof,
      pqcSignatureAlgorithm: pqcAlgorithm,
      classicalAlgorithm: classicalAlgorithm,
      pqcSecretKey: pqcKp.secretKey,
      pqcPublicKey: pqcKp.publicKey,
      classicalSecretKey: classicalKp.secretKey,
      classicalPublicKey: classicalKp.publicKey,
      requireSignature: requireSignature,
      signContext: signContext,
      dualPolicy: dualPolicy,
    );
    return HybridAuthenticatedLabSession(
      algorithm: algo,
      pqcPublicKey: pqcKp.publicKey,
      classicalPublicKey: classicalKp.publicKey,
      pqcSecretKey: pqcKp.secretKey,
      classicalSecretKey: classicalKp.secretKey,
      pqcAlgorithm: pqcAlgorithm,
      classicalAlgorithm: classicalAlgorithm,
    );
  }
}

/// Ephemeral hybrid auth lab materials.
class HybridAuthenticatedLabSession {
  final HybridAuthenticatedPqdga algorithm;
  final Uint8List pqcPublicKey;
  final Uint8List classicalPublicKey;
  final Uint8List pqcSecretKey;
  final Uint8List classicalSecretKey;
  final PqSignatureAlgorithm pqcAlgorithm;
  final PqClassicalSignatureAlgorithm classicalAlgorithm;

  const HybridAuthenticatedLabSession({
    required this.algorithm,
    required this.pqcPublicKey,
    required this.classicalPublicKey,
    required this.pqcSecretKey,
    required this.classicalSecretKey,
    required this.pqcAlgorithm,
    required this.classicalAlgorithm,
  });

  String get pqcFingerprint =>
      HybridAuthenticatedPqdga.pubkeyFingerprintOf(pqcPublicKey);

  String get classicalFingerprint =>
      HybridAuthenticatedPqdga.pubkeyFingerprintOf(classicalPublicKey);

  /// Verify a dual signature from a [PQDGAResult]-style hybrid payload.
  Future<bool> verify({
    required String domain,
    required String epoch,
    required Uint8List pqcSignature,
    required Uint8List classicalSignature,
    String? campaignId,
    Uint8List? context,
  }) {
    final signer = PqForgeHybridSigner(
      profile: PqForgeProfile(
        name: 'pqdga-hybrid-auth',
        kem: PqKemAlgorithm.mlKem768,
        signature: pqcAlgorithm,
      ),
      classicalAlgorithm: classicalAlgorithm,
    );
    final message = HybridAuthenticatedPqdga.canonicalMessage(
      signatureDomainSeparator: algorithm.signatureDomainSeparator,
      domain: domain,
      epoch: epoch,
      campaignId: campaignId ?? algorithm.campaignId,
    );
    return signer.verify(
      pqcPublicKey: pqcPublicKey,
      classicalPublicKey: classicalPublicKey,
      message: message,
      signature: PqHybridSignature(
        pqcSignature: pqcSignature,
        classicalSignature: classicalSignature,
        pqcAlgorithm: pqcAlgorithm,
        classicalAlgorithm: classicalAlgorithm,
        policy: algorithm.dualPolicy,
      ),
      context: context ?? algorithm.signContext,
    );
  }
}
