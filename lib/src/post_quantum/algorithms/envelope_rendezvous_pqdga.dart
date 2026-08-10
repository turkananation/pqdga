import 'dart:typed_data';

import 'package:pqforge/pqforge.dart';
import 'package:pqdga/src/post_quantum/crypto/dns_label_codec.dart';
import 'package:pqdga/src/post_quantum/pqdga_core.dart';

/// Envelope rendezvous PQ DGA: short domain id + KEM-DEM sealed payload (R6 extra).
///
/// **SOC lesson:** The FQDN is a decoy rendezvous handle. Real config lives in
/// an ML-KEM-DEM envelope — hunt CT/payload sizes and envelope metadata, not
/// only names. Never log DEM keys or plaintext config.
///
/// Provide [kemPublicKey] (encrypt) or [kemSecretKey] + prebuilt materials.
class EnvelopeRendezvousPqdga extends PQDGAAlgorithm {
  /// Toy campaign identifier.
  final String campaignId;

  /// TLD list for short decoy domains.
  final List<String> tld;

  /// Charset for short id labels.
  final String charset;

  /// Domain-separation prefix for the short-id XOF.
  final String domainSeparator;

  /// XOF id recorded in results.
  final String xof;

  /// KEM parameter set (IOC).
  final PqKemAlgorithm kemAlgorithm;

  /// Recipient KEM public key (encrypt path).
  final Uint8List? kemPublicKey;

  /// Recipient KEM secret key (decrypt drills only).
  final Uint8List? kemSecretKey;

  /// Optional pre-established shared secret for label expand (lab).
  final Uint8List? sharedSecret;

  /// Optional encaps ciphertext (length IOC).
  final Uint8List? kemCiphertext;

  /// Lab plaintext "config" sealed into the envelope (never a live secret).
  final Uint8List? configPlaintext;

  /// Optional 32-byte encaps nonce for deterministic labs.
  final Uint8List? encapsNonce;

  /// Short id length (default 8).
  final int shortIdLength;

  const EnvelopeRendezvousPqdga({
    this.campaignId = 'toy-envelope',
    this.tld = const ['.com', '.net', '.org'],
    this.charset = DnsLabelCodec.defaultCharset,
    this.domainSeparator = 'pqdga/v1/envelope',
    this.xof = 'SHAKE256',
    this.kemAlgorithm = PqKemAlgorithm.mlKem768,
    this.kemPublicKey,
    this.kemSecretKey,
    this.sharedSecret,
    this.kemCiphertext,
    this.configPlaintext,
    this.encapsNonce,
    this.shortIdLength = 8,
  });

  /// Lab helper: ephemeral ML-KEM + default toy config plaintext.
  static EnvelopeLabSession labEstablish({
    PqKemAlgorithm algorithm = PqKemAlgorithm.mlKem768,
    Uint8List? kemSeed,
    Uint8List? encapsNonce,
    String campaignId = 'toy-envelope',
    List<String> tld = const ['.com', '.net', '.org'],
    String charset = DnsLabelCodec.defaultCharset,
    String domainSeparator = 'pqdga/v1/envelope',
    String xof = 'SHAKE256',
    int shortIdLength = 8,
    Uint8List? configPlaintext,
  }) {
    final forge = const PqForge();
    final kp = forge.generateKemKeyPair(algorithm: algorithm, seed: kemSeed);
    final plain =
        configPlaintext ??
        Uint8List.fromList(List<int>.generate(32, (i) => (i * 7 + 3) & 0xFF));
    final enc = forge.encapsulate(
      kp.publicKey,
      algorithm: algorithm,
      nonce: encapsNonce,
    );
    final algo = EnvelopeRendezvousPqdga(
      campaignId: campaignId,
      tld: tld,
      charset: charset,
      domainSeparator: domainSeparator,
      xof: xof,
      kemAlgorithm: algorithm,
      kemPublicKey: kp.publicKey,
      kemSecretKey: kp.secretKey,
      sharedSecret: enc.sharedSecret,
      kemCiphertext: enc.ciphertext,
      configPlaintext: plain,
      encapsNonce: encapsNonce,
      shortIdLength: shortIdLength,
    );
    return EnvelopeLabSession(
      algorithm: algo,
      kemSecretKey: kp.secretKey,
      kemPublicKey: kp.publicKey,
      sharedSecret: enc.sharedSecret,
      kemCiphertext: enc.ciphertext,
      configPlaintext: plain,
      kemAlgorithm: algorithm,
    );
  }
}

/// Ephemeral lab materials from [EnvelopeRendezvousPqdga.labEstablish].
class EnvelopeLabSession {
  final EnvelopeRendezvousPqdga algorithm;
  final Uint8List kemSecretKey;
  final Uint8List kemPublicKey;
  final Uint8List sharedSecret;
  final Uint8List kemCiphertext;
  final Uint8List configPlaintext;
  final PqKemAlgorithm kemAlgorithm;

  const EnvelopeLabSession({
    required this.algorithm,
    required this.kemSecretKey,
    required this.kemPublicKey,
    required this.sharedSecret,
    required this.kemCiphertext,
    required this.configPlaintext,
    required this.kemAlgorithm,
  });
}
