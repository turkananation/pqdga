import 'dart:typed_data';

import 'package:pqforge/pqforge.dart';
import 'package:pqdga/src/post_quantum/algorithms/signature_authenticated_pqdga.dart';
import 'package:pqdga/src/post_quantum/crypto/dns_label_codec.dart';
import 'package:pqdga/src/post_quantum/pqdga_core.dart';

/// Identity-based PQ DGA: SHAKE over embedded verification/public key namespace.
///
/// **SOC lesson (P2→P1):** Treat embedded PQ verification keys like classical
/// config seeds — once the vk/pk is extracted from a sample, names are
/// precomputable. Optional ML-DSA signing (P5) can still gate C2 trust.
///
/// Default path binds [identityPublicKey] into the label XOF (not a secret).
/// Provide [signatureSecretKey] + [requireSignature] to also emit detached sigs.
class IdentityBasedPqdga extends PQDGAAlgorithm {
  /// Toy campaign identifier (never a live operator secret).
  final String campaignId;

  /// TLD list; entries may include or omit the leading dot.
  final List<String> tld;

  /// Label charset (default LDH alphanumeric lowercase).
  final String charset;

  /// Domain-separation prefix absorbed into the label XOF input.
  final String domainSeparator;

  /// XOF algorithm id recorded in results (`SHAKE256` or `SHAKE128`).
  final String xof;

  /// Public identity material (ML-DSA vk or ML-KEM pk) bound into names.
  ///
  /// Lab only — this is the extraction target, not a shared secret.
  final Uint8List? identityPublicKey;

  /// Kind tag for IOC templates (`ml-dsa-vk` or `ml-kem-pk`).
  final String identityKind;

  /// Optional ML-DSA algorithm when [requireSignature] is true.
  final PqSignatureAlgorithm signatureAlgorithm;

  /// Operator signing secret key when combining identity namespace + signatures.
  final Uint8List? signatureSecretKey;

  /// Domain-separation prefix for signed canonical messages.
  final String signatureDomainSeparator;

  /// When true, each domain is ML-DSA-signed (needs [signatureSecretKey]).
  final bool requireSignature;

  /// Optional ML-DSA context bytes.
  final Uint8List? signContext;

  const IdentityBasedPqdga({
    this.campaignId = 'toy-campaign',
    this.tld = const ['.com', '.net', '.org'],
    this.charset = DnsLabelCodec.defaultCharset,
    this.domainSeparator = 'pqdga/v1/identity',
    this.xof = 'SHAKE256',
    this.identityPublicKey,
    this.identityKind = 'ml-dsa-vk',
    this.signatureAlgorithm = PqSignatureAlgorithm.mlDsa65,
    this.signatureSecretKey,
    this.signatureDomainSeparator = 'pqdga/v1/sig',
    this.requireSignature = false,
    this.signContext,
  });

  /// Lab helper: ephemeral ML-DSA keygen → vk namespaces labels.
  ///
  /// Prefer [sigSeed] (32 bytes) for deterministic lab keys.
  static IdentityBasedLabSession labEstablish({
    PqSignatureAlgorithm algorithm = PqSignatureAlgorithm.mlDsa65,
    Uint8List? sigSeed,
    String campaignId = 'toy-campaign',
    List<String> tld = const ['.com', '.net', '.org'],
    String charset = DnsLabelCodec.defaultCharset,
    String domainSeparator = 'pqdga/v1/identity',
    String xof = 'SHAKE256',
    bool requireSignature = false,
    String signatureDomainSeparator = 'pqdga/v1/sig',
    Uint8List? signContext,
  }) {
    final forge = const PqForge();
    final kp = sigSeed == null
        ? forge.generateSignatureKeyPair(algorithm: algorithm)
        : forge.generateSignatureKeyPairFromSeed(sigSeed, algorithm: algorithm);
    final algo = IdentityBasedPqdga(
      campaignId: campaignId,
      tld: tld,
      charset: charset,
      domainSeparator: domainSeparator,
      xof: xof,
      identityPublicKey: kp.publicKey,
      identityKind: 'ml-dsa-vk',
      signatureAlgorithm: algorithm,
      signatureSecretKey: requireSignature ? kp.secretKey : null,
      signatureDomainSeparator: signatureDomainSeparator,
      requireSignature: requireSignature,
      signContext: signContext,
    );
    return IdentityBasedLabSession(
      algorithm: algo,
      identityPublicKey: kp.publicKey,
      signatureSecretKey: kp.secretKey,
      signatureAlgorithm: algorithm,
    );
  }

  /// Hex fingerprint of the identity public key (config-extraction IOC).
  String? get pubkeyFingerprint {
    final pk = identityPublicKey;
    if (pk == null || pk.isEmpty) return null;
    return SignatureAuthenticatedPqdga.pubkeyFingerprintOf(pk);
  }
}

/// Ephemeral lab materials from [IdentityBasedPqdga.labEstablish].
class IdentityBasedLabSession {
  /// Generator-ready algorithm (vk embedded; sk only if signing enabled).
  final IdentityBasedPqdga algorithm;

  /// Identity / verification public key (safe fingerprint IOC).
  final Uint8List identityPublicKey;

  /// Signing secret key (do not log); present for optional sign drills.
  final Uint8List signatureSecretKey;

  /// Parameter set for optional signatures.
  final PqSignatureAlgorithm signatureAlgorithm;

  const IdentityBasedLabSession({
    required this.algorithm,
    required this.identityPublicKey,
    required this.signatureSecretKey,
    required this.signatureAlgorithm,
  });

  /// Fingerprint of [identityPublicKey].
  String get pubkeyFingerprint =>
      SignatureAuthenticatedPqdga.pubkeyFingerprintOf(identityPublicKey);

  /// Config that also signs each domain with the lab sk.
  IdentityBasedPqdga get asSignedConfig => IdentityBasedPqdga(
        campaignId: algorithm.campaignId,
        tld: algorithm.tld,
        charset: algorithm.charset,
        domainSeparator: algorithm.domainSeparator,
        xof: algorithm.xof,
        identityPublicKey: identityPublicKey,
        identityKind: algorithm.identityKind,
        signatureAlgorithm: signatureAlgorithm,
        signatureSecretKey: signatureSecretKey,
        signatureDomainSeparator: algorithm.signatureDomainSeparator,
        requireSignature: true,
        signContext: algorithm.signContext,
      );
}
