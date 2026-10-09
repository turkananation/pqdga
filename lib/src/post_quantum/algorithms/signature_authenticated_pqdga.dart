import 'dart:convert';
import 'dart:typed_data';

import 'package:pqforge/pqforge.dart';
import 'package:pqdga/src/post_quantum/crypto/dns_label_codec.dart';
import 'package:pqdga/src/post_quantum/crypto/shake_xof.dart';
import 'package:pqdga/src/post_quantum/pqdga_core.dart';

/// Signature-authenticated PQ DGA: ML-DSA over domain‖epoch‖campaign (R5).
///
/// **SOC lesson (P5):** Sinkhole IP alone fails if the bot requires a valid
/// operator signature before trusting C2. Defenders need key compromise,
/// client-side block that still fails verify, or binary rewrite. Hunt detached
/// sig sizes + pubkey fingerprint IOCs — never log [signatureSecretKey].
///
/// Names expand via SHAKE (public epoch/campaign by default, optional secret).
/// When [requireSignature] is true (default), [signatureSecretKey] is required
/// and each domain is signed as a detached ML-DSA artifact on [PQDGAResult].
class SignatureAuthenticatedPqdga extends PQDGAAlgorithm {
  /// Toy campaign identifier (never a live operator secret).
  final String campaignId;

  /// TLD list; entries may include or omit the leading dot.
  final List<String> tld;

  /// Label charset (default LDH alphanumeric lowercase).
  final String charset;

  /// When true (default), label seed is public epoch+campaign only.
  ///
  /// Names may still be precomputable; authenticity is the ML-DSA gate.
  final bool seedPublic;

  /// Optional non-public bytes bound into the XOF input when [seedPublic] is false.
  /// Lab only — never log this value.
  final Uint8List? secretMaterial;

  /// Domain-separation prefix absorbed into the label XOF input.
  final String domainSeparator;

  /// Domain-separation prefix for the signed canonical message.
  final String signatureDomainSeparator;

  /// XOF algorithm id recorded in results (`SHAKE256` or `SHAKE128`).
  final String xof;

  /// ML-DSA parameter set for sign/verify and IOC templates.
  final PqSignatureAlgorithm signatureAlgorithm;

  /// Operator signing secret key (required when [requireSignature] is true).
  final Uint8List? signatureSecretKey;

  /// Operator verification key (fingerprint + lab verify drills).
  final Uint8List? signaturePublicKey;

  /// When true (default), generation fails closed without a signing key and
  /// emits detached signatures on every domain.
  final bool requireSignature;

  /// Optional ML-DSA context bytes (max 255); included in sign/verify.
  final Uint8List? signContext;

  const SignatureAuthenticatedPqdga({
    this.campaignId = 'toy-campaign',
    this.tld = const ['.com', '.net', '.org'],
    this.charset = DnsLabelCodec.defaultCharset,
    this.seedPublic = true,
    this.secretMaterial,
    this.domainSeparator = 'pqdga/v1/sig-auth',
    this.signatureDomainSeparator = 'pqdga/v1/sig',
    this.xof = 'SHAKE256',
    this.signatureAlgorithm = PqSignatureAlgorithm.mlDsa65,
    this.signatureSecretKey,
    this.signaturePublicKey,
    this.requireSignature = true,
    this.signContext,
  });

  /// Lab helper: ephemeral ML-DSA keygen → ready algorithm config.
  ///
  /// Prefer [sigSeed] (32 bytes) for deterministic lab key material.
  /// Never log [SignatureAuthLabSession.signatureSecretKey].
  static SignatureAuthLabSession labEstablish({
    PqSignatureAlgorithm algorithm = PqSignatureAlgorithm.mlDsa65,
    Uint8List? sigSeed,
    String campaignId = 'toy-campaign',
    List<String> tld = const ['.com', '.net', '.org'],
    String charset = DnsLabelCodec.defaultCharset,
    bool seedPublic = true,
    Uint8List? secretMaterial,
    String domainSeparator = 'pqdga/v1/sig-auth',
    String signatureDomainSeparator = 'pqdga/v1/sig',
    String xof = 'SHAKE256',
    bool requireSignature = true,
    Uint8List? signContext,
  }) {
    final forge = const PqForge();
    final kp = sigSeed == null
        ? forge.generateSignatureKeyPair(algorithm: algorithm)
        : forge.generateSignatureKeyPairFromSeed(sigSeed, algorithm: algorithm);
    final algo = SignatureAuthenticatedPqdga(
      campaignId: campaignId,
      tld: tld,
      charset: charset,
      seedPublic: seedPublic,
      secretMaterial: secretMaterial,
      domainSeparator: domainSeparator,
      signatureDomainSeparator: signatureDomainSeparator,
      xof: xof,
      signatureAlgorithm: algorithm,
      signatureSecretKey: kp.secretKey,
      signaturePublicKey: kp.publicKey,
      requireSignature: requireSignature,
      signContext: signContext,
    );
    return SignatureAuthLabSession(
      algorithm: algo,
      signatureSecretKey: kp.secretKey,
      signaturePublicKey: kp.publicKey,
      signatureAlgorithm: algorithm,
    );
  }

  /// Canonical bytes signed for a domain: sep‖domain‖epoch‖campaign.
  static Uint8List canonicalMessage({
    required String signatureDomainSeparator,
    required String domain,
    required String epoch,
    required String campaignId,
  }) {
    return Uint8List.fromList([
      ...utf8.encode(signatureDomainSeparator),
      0x00,
      ...utf8.encode(domain),
      0x00,
      ...utf8.encode(epoch),
      0x00,
      ...utf8.encode(campaignId),
    ]);
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

  /// Lab verify: check detached ML-DSA over canonical(domain‖epoch‖campaign).
  static bool verifyDomain({
    required Uint8List publicKey,
    required String domain,
    required String epoch,
    required String campaignId,
    required Uint8List signature,
    PqSignatureAlgorithm algorithm = PqSignatureAlgorithm.mlDsa65,
    String signatureDomainSeparator = 'pqdga/v1/sig',
    Uint8List? context,
  }) {
    final message = canonicalMessage(
      signatureDomainSeparator: signatureDomainSeparator,
      domain: domain,
      epoch: epoch,
      campaignId: campaignId,
    );
    return const PqForge().verify(
      publicKey,
      message,
      signature,
      algorithm: algorithm,
      context: context,
    );
  }

  /// Instance verify using this config's algorithm / separators / context.
  bool verify({
    required String domain,
    required String epoch,
    required Uint8List signature,
    Uint8List? publicKey,
  }) {
    final pk = publicKey ?? signaturePublicKey;
    if (pk == null || pk.isEmpty) {
      throw ArgumentError(
        'signaturePublicKey required for verify '
        '(pass publicKey or set on config)',
      );
    }
    return verifyDomain(
      publicKey: pk,
      domain: domain,
      epoch: epoch,
      campaignId: campaignId,
      signature: signature,
      algorithm: signatureAlgorithm,
      signatureDomainSeparator: signatureDomainSeparator,
      context: signContext,
    );
  }
}

/// Ephemeral lab materials from [SignatureAuthenticatedPqdga.labEstablish].
///
/// Keep [signatureSecretKey] out of logs and SOC summaries.
class SignatureAuthLabSession {
  /// Generator-ready algorithm (includes sk — treat as sensitive in process).
  final SignatureAuthenticatedPqdga algorithm;

  /// Signing secret key for operator-side drills only.
  final Uint8List signatureSecretKey;

  /// Verification public key (safe to fingerprint / embed in bot lab samples).
  final Uint8List signaturePublicKey;

  /// Parameter set.
  final PqSignatureAlgorithm signatureAlgorithm;

  const SignatureAuthLabSession({
    required this.algorithm,
    required this.signatureSecretKey,
    required this.signaturePublicKey,
    required this.signatureAlgorithm,
  });

  /// Hex fingerprint of [signaturePublicKey] (non-secret IOC).
  String get pubkeyFingerprint =>
      SignatureAuthenticatedPqdga.pubkeyFingerprintOf(signaturePublicKey);

  /// Config view with only the public key (no sk) for verify-only drills.
  SignatureAuthenticatedPqdga get asVerifyOnlyConfig =>
      SignatureAuthenticatedPqdga(
        campaignId: algorithm.campaignId,
        tld: algorithm.tld,
        charset: algorithm.charset,
        seedPublic: algorithm.seedPublic,
        secretMaterial: algorithm.secretMaterial,
        domainSeparator: algorithm.domainSeparator,
        signatureDomainSeparator: algorithm.signatureDomainSeparator,
        xof: algorithm.xof,
        signatureAlgorithm: signatureAlgorithm,
        signaturePublicKey: signaturePublicKey,
        requireSignature: false,
        signContext: algorithm.signContext,
      );
}
