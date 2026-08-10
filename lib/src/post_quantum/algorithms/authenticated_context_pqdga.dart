import 'dart:typed_data';

import 'package:pqforge/pqforge.dart';
import 'package:pqdga/src/post_quantum/crypto/dns_label_codec.dart';
import 'package:pqdga/src/post_quantum/pqdga_core.dart';

/// ML-DSA-authenticated **context** PQDGA (binding ladder R9g / email R13).
///
/// Distinct from [SignatureAuthenticatedPqdga] (sign final domain strings):
/// here the experiment is:
///
/// ```
/// context (sep‖epoch‖campaign‖counter)
///    → ML-DSA signature
///    → authenticated context (sig bytes)
///    → derivation (SHAKE or KMAC)
///    → identifier
/// ```
///
/// Research: what does **authenticity** add vs **confidentiality**?
/// ML-DSA does not make the namespace secret; optional [secretMaterial] adds
/// secret-binding as a separate axis.
///
/// Never log signature secret keys or [secretMaterial].
class AuthenticatedContextPqdga extends PQDGAAlgorithm {
  final String campaignId;
  final List<String> tld;
  final String charset;

  /// Domain-separation for the signed context transcript.
  final String domainSeparator;

  /// Expansion primitive: `SHAKE256` (default) or `KMAC256`.
  final String kdf;

  /// KMAC customization when [kdf] is KMAC256.
  final String kmacCustomization;

  /// Optional secret for confidentiality axis (null → authenticity-only).
  final Uint8List? secretMaterial;

  /// ML-DSA algorithm.
  final PqSignatureAlgorithm signatureAlgorithm;

  /// Signer secret key (required to produce context signatures).
  final Uint8List? signatureSecretKey;

  /// Verification public key (fingerprint IOC; verify drills).
  final Uint8List? signaturePublicKey;

  /// Optional fixed context signature seed material for deterministic labs
  /// (when set with keys from labEstablish, generator still signs live).
  final Uint8List? signContext;

  /// When true (default), generator must produce/verify signatures.
  final bool requireSignature;

  const AuthenticatedContextPqdga({
    this.campaignId = 'toy-campaign',
    this.tld = const ['.com', '.net', '.org'],
    this.charset = DnsLabelCodec.defaultCharset,
    this.domainSeparator = 'pqdga/v1/auth-context',
    this.kdf = 'SHAKE256',
    this.kmacCustomization = 'pqdga/v1/auth-context',
    this.secretMaterial,
    this.signatureAlgorithm = PqSignatureAlgorithm.mlDsa65,
    this.signatureSecretKey,
    this.signaturePublicKey,
    this.signContext,
    this.requireSignature = true,
  });

  /// Whether this config is secret-bound (confidentiality axis).
  bool get secretBound =>
      secretMaterial != null && secretMaterial!.isNotEmpty;

  /// Lab helper: ephemeral ML-DSA keys (± optional secret).
  static AuthenticatedContextLabSession labEstablish({
    PqSignatureAlgorithm algorithm = PqSignatureAlgorithm.mlDsa65,
    Uint8List? sigSeed,
    Uint8List? secretMaterial,
    String campaignId = 'toy-campaign',
    List<String> tld = const ['.com', '.net', '.org'],
    String charset = DnsLabelCodec.defaultCharset,
    String domainSeparator = 'pqdga/v1/auth-context',
    String kdf = 'SHAKE256',
    String kmacCustomization = 'pqdga/v1/auth-context',
    bool requireSignature = true,
    Uint8List? signContext,
  }) {
    final forge = const PqForge();
    final kp = sigSeed == null
        ? forge.generateSignatureKeyPair(algorithm: algorithm)
        : forge.generateSignatureKeyPairFromSeed(
            sigSeed,
            algorithm: algorithm,
          );
    final algo = AuthenticatedContextPqdga(
      campaignId: campaignId,
      tld: tld,
      charset: charset,
      domainSeparator: domainSeparator,
      kdf: kdf,
      kmacCustomization: kmacCustomization,
      secretMaterial: secretMaterial,
      signatureAlgorithm: algorithm,
      signatureSecretKey: kp.secretKey,
      signaturePublicKey: kp.publicKey,
      signContext: signContext,
      requireSignature: requireSignature,
    );
    return AuthenticatedContextLabSession(
      algorithm: algo,
      signatureSecretKey: kp.secretKey,
      signaturePublicKey: kp.publicKey,
      signatureAlgorithm: algorithm,
    );
  }
}

/// Lab materials for [AuthenticatedContextPqdga].
class AuthenticatedContextLabSession {
  final AuthenticatedContextPqdga algorithm;
  final Uint8List signatureSecretKey;
  final Uint8List signaturePublicKey;
  final PqSignatureAlgorithm signatureAlgorithm;

  const AuthenticatedContextLabSession({
    required this.algorithm,
    required this.signatureSecretKey,
    required this.signaturePublicKey,
    required this.signatureAlgorithm,
  });

  /// Authenticity-only (no secret material).
  AuthenticatedContextPqdga get asAuthOnlyConfig => AuthenticatedContextPqdga(
        campaignId: algorithm.campaignId,
        tld: algorithm.tld,
        charset: algorithm.charset,
        domainSeparator: algorithm.domainSeparator,
        kdf: algorithm.kdf,
        kmacCustomization: algorithm.kmacCustomization,
        signatureAlgorithm: signatureAlgorithm,
        signatureSecretKey: signatureSecretKey,
        signaturePublicKey: signaturePublicKey,
        signContext: algorithm.signContext,
        requireSignature: algorithm.requireSignature,
      );

  /// Authenticity + confidentiality.
  AuthenticatedContextPqdga withSecret(Uint8List secret) =>
      AuthenticatedContextPqdga(
        campaignId: algorithm.campaignId,
        tld: algorithm.tld,
        charset: algorithm.charset,
        domainSeparator: algorithm.domainSeparator,
        kdf: algorithm.kdf,
        kmacCustomization: algorithm.kmacCustomization,
        secretMaterial: secret,
        signatureAlgorithm: signatureAlgorithm,
        signatureSecretKey: signatureSecretKey,
        signaturePublicKey: signaturePublicKey,
        signContext: algorithm.signContext,
        requireSignature: algorithm.requireSignature,
      );
}
