import 'dart:typed_data';

import 'package:pqforge/pqforge.dart';
import 'package:pqdga/src/post_quantum/algorithms/shared_secret_pqdga.dart';
import 'package:pqdga/src/post_quantum/crypto/dns_label_codec.dart';
import 'package:pqdga/src/post_quantum/pqdga_core.dart';

/// KMAC-bound shared-secret PQDGA (binding ladder R9a).
///
/// Same secret acquisition as [SharedSecretPqdga] (ML-KEM ss), but expands
/// labels with **KMAC256(key=ss, data=context, S=customization)** instead of
/// absorb-all SHAKE. Research question: does keyed SP 800-185 domain
/// separation yield a cleaner secret-bound construction than raw XOF absorb?
///
/// Never log [sharedSecret] or secret keys. Ciphertext length + KEM id are OK IOCs.
class KmacSharedSecretPqdga extends PQDGAAlgorithm {
  /// Toy campaign identifier (never a live operator secret).
  final String campaignId;

  /// TLD list; entries may include or omit the leading dot.
  final List<String> tld;

  /// Label charset (default LDH alphanumeric lowercase).
  final String charset;

  /// Customization string `S` for KMAC (domain separation / purpose).
  final String kmacCustomization;

  /// Context domain-separation prefix packed into KMAC data `X`.
  final String domainSeparator;

  /// KDF / MAC id recorded in results (`KMAC256`).
  final String kdf;

  /// Pre-established ML-KEM shared secret (typically 32 bytes). Lab only.
  final Uint8List? sharedSecret;

  /// KEM parameter set for IOC templates and encaps/decaps.
  final PqKemAlgorithm kemAlgorithm;

  /// Optional encaps ciphertext (non-secret wire artifact / length IOC).
  final Uint8List? kemCiphertext;

  /// Bot-side KEM secret key used with [kemCiphertext] to recover ss.
  final Uint8List? kemSecretKey;

  /// Operator/bot public key; when set without [sharedSecret], generator encaps.
  final Uint8List? kemPublicKey;

  /// Optional 32-byte encaps entropy for deterministic lab encapsulate.
  final Uint8List? encapsNonce;

  const KmacSharedSecretPqdga({
    this.campaignId = 'toy-campaign',
    this.tld = const ['.com', '.net', '.org'],
    this.charset = DnsLabelCodec.defaultCharset,
    this.kmacCustomization = 'pqdga/v1/kmac-ss',
    this.domainSeparator = 'pqdga/v1/kmac-ss',
    this.kdf = 'KMAC256',
    this.sharedSecret,
    this.kemAlgorithm = PqKemAlgorithm.mlKem768,
    this.kemCiphertext,
    this.kemSecretKey,
    this.kemPublicKey,
    this.encapsNonce,
  });

  /// Lab helper: ephemeral ML-KEM keygen + encapsulate → ready algorithm config.
  static KmacSharedSecretLabSession labEstablish({
    PqKemAlgorithm algorithm = PqKemAlgorithm.mlKem768,
    Uint8List? encapsNonce,
    Uint8List? kemSeed,
    String campaignId = 'toy-campaign',
    List<String> tld = const ['.com', '.net', '.org'],
    String charset = DnsLabelCodec.defaultCharset,
    String kmacCustomization = 'pqdga/v1/kmac-ss',
    String domainSeparator = 'pqdga/v1/kmac-ss',
    String kdf = 'KMAC256',
  }) {
    final base = SharedSecretPqdga.labEstablish(
      algorithm: algorithm,
      encapsNonce: encapsNonce,
      kemSeed: kemSeed,
      campaignId: campaignId,
      tld: tld,
      charset: charset,
      domainSeparator: domainSeparator,
    );
    final algo = KmacSharedSecretPqdga(
      campaignId: campaignId,
      tld: tld,
      charset: charset,
      kmacCustomization: kmacCustomization,
      domainSeparator: domainSeparator,
      kdf: kdf,
      sharedSecret: base.sharedSecret,
      kemAlgorithm: algorithm,
      kemCiphertext: base.kemCiphertext,
      kemPublicKey: base.kemPublicKey,
    );
    return KmacSharedSecretLabSession(
      algorithm: algo,
      kemSecretKey: base.kemSecretKey,
      sharedSecret: base.sharedSecret,
      kemCiphertext: base.kemCiphertext,
      kemPublicKey: base.kemPublicKey,
      kemAlgorithm: algorithm,
    );
  }
}

/// Ephemeral lab materials from [KmacSharedSecretPqdga.labEstablish].
class KmacSharedSecretLabSession {
  final KmacSharedSecretPqdga algorithm;
  final Uint8List kemSecretKey;
  final Uint8List sharedSecret;
  final Uint8List kemCiphertext;
  final Uint8List kemPublicKey;
  final PqKemAlgorithm kemAlgorithm;

  const KmacSharedSecretLabSession({
    required this.algorithm,
    required this.kemSecretKey,
    required this.sharedSecret,
    required this.kemCiphertext,
    required this.kemPublicKey,
    required this.kemAlgorithm,
  });

  /// Algorithm view that recovers ss via decaps only.
  KmacSharedSecretPqdga get asDecapsConfig => KmacSharedSecretPqdga(
        campaignId: algorithm.campaignId,
        tld: algorithm.tld,
        charset: algorithm.charset,
        kmacCustomization: algorithm.kmacCustomization,
        domainSeparator: algorithm.domainSeparator,
        kdf: algorithm.kdf,
        kemAlgorithm: kemAlgorithm,
        kemCiphertext: kemCiphertext,
        kemSecretKey: kemSecretKey,
        kemPublicKey: kemPublicKey,
      );
}
