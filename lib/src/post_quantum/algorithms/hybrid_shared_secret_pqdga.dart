import 'dart:convert';
import 'dart:typed_data';

import 'package:pqforge/pqforge.dart';
import 'package:pqdga/src/post_quantum/crypto/dns_label_codec.dart';
import 'package:pqdga/src/post_quantum/pqdga_core.dart';

/// Hybrid shared-secret PQ DGA: classical ‖ ML-KEM combiner → SHAKE labels.
///
/// **SOC lesson:** Same defender shift as SharedSecret (P4), but document that
/// breaking classical **or** PQ alone is insufficient — both shares bind the
/// hybrid session key via [PqForgeCombiner].
///
/// Provide either:
/// * [hybridSessionKey] directly, or
/// * [classicalSharedSecret] + [postQuantumSharedSecret] (combined in generator).
///
/// Never log session keys or component secrets. KEM CT length remains an IOC.
class HybridSharedSecretPqdga extends PQDGAAlgorithm {
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

  /// Pre-combined hybrid session key (typically 32 bytes). Lab only.
  final Uint8List? hybridSessionKey;

  /// Classical KEX shared secret (e.g. X25519, 32 bytes).
  final Uint8List? classicalSharedSecret;

  /// ML-KEM shared secret (32 bytes).
  final Uint8List? postQuantumSharedSecret;

  /// KEM parameter set for IOC templates.
  final PqKemAlgorithm kemAlgorithm;

  /// Optional encaps ciphertext (length IOC).
  final Uint8List? kemCiphertext;

  /// Classical algorithm id for metadata (`x25519`).
  final String classicalAlgorithm;

  /// HKDF info domain-separation for [PqForgeCombiner] (non-empty UTF-8).
  final String combinerInfo;

  /// Optional HKDF salt (deployment / transcript).
  final Uint8List? combinerSalt;

  /// Combiner profile name (`balanced` or `heavy`).
  final String combinerProfile;

  const HybridSharedSecretPqdga({
    this.campaignId = 'toy-campaign',
    this.tld = const ['.com', '.net', '.org'],
    this.charset = DnsLabelCodec.defaultCharset,
    this.domainSeparator = 'pqdga/v1/hybrid-ss',
    this.xof = 'SHAKE256',
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

  /// Lab helper: fixed classical + ML-KEM ss → hybrid session (deterministic).
  ///
  /// Prefer this for golden tests. For full X25519 handshake labs, supply
  /// real classical shares from [PqForgeHybridKeyAgreement] outside.
  static HybridSharedSecretLabSession labEstablish({
    Uint8List? classicalSharedSecret,
    Uint8List? postQuantumSharedSecret,
    PqKemAlgorithm kemAlgorithm = PqKemAlgorithm.mlKem768,
    Uint8List? kemSeed,
    Uint8List? encapsNonce,
    String campaignId = 'toy-campaign',
    List<String> tld = const ['.com', '.net', '.org'],
    String charset = DnsLabelCodec.defaultCharset,
    String domainSeparator = 'pqdga/v1/hybrid-ss',
    String xof = 'SHAKE256',
    String classicalAlgorithm = 'x25519',
    String combinerInfo = 'pqdga/v1/hybrid',
    Uint8List? combinerSalt,
    String combinerProfile = 'balanced',
  }) {
    final classical = classicalSharedSecret ??
        Uint8List.fromList(List<int>.generate(32, (i) => 0xA0 + (i & 0x0f)));
    late final Uint8List pqSs;
    late final Uint8List? ct;
    late final Uint8List? kemPk;
    if (postQuantumSharedSecret != null && postQuantumSharedSecret.isNotEmpty) {
      pqSs = Uint8List.fromList(postQuantumSharedSecret);
      ct = null;
      kemPk = null;
    } else {
      final forge = const PqForge();
      final kp =
          forge.generateKemKeyPair(algorithm: kemAlgorithm, seed: kemSeed);
      final enc = forge.encapsulate(
        kp.publicKey,
        algorithm: kemAlgorithm,
        nonce: encapsNonce,
      );
      pqSs = enc.sharedSecret;
      ct = enc.ciphertext;
      kemPk = kp.publicKey;
    }

    final combiner = combinerProfile == 'heavy'
        ? const PqForgeCombiner.heavy()
        : const PqForgeCombiner.balanced();
    final sessionKey = combiner.combine(
      classicalSharedSecret: classical,
      postQuantumSharedSecret: pqSs,
      info: Uint8List.fromList(utf8.encode(combinerInfo)),
      salt: combinerSalt,
    );

    final algo = HybridSharedSecretPqdga(
      campaignId: campaignId,
      tld: tld,
      charset: charset,
      domainSeparator: domainSeparator,
      xof: xof,
      hybridSessionKey: sessionKey,
      classicalSharedSecret: classical,
      postQuantumSharedSecret: pqSs,
      kemAlgorithm: kemAlgorithm,
      kemCiphertext: ct,
      classicalAlgorithm: classicalAlgorithm,
      combinerInfo: combinerInfo,
      combinerSalt: combinerSalt,
      combinerProfile: combinerProfile,
    );
    return HybridSharedSecretLabSession(
      algorithm: algo,
      hybridSessionKey: sessionKey,
      classicalSharedSecret: classical,
      postQuantumSharedSecret: pqSs,
      kemCiphertext: ct,
      kemPublicKey: kemPk,
      kemAlgorithm: kemAlgorithm,
    );
  }
}

/// Ephemeral lab materials from [HybridSharedSecretPqdga.labEstablish].
///
/// Keep [hybridSessionKey] and component secrets out of logs.
class HybridSharedSecretLabSession {
  final HybridSharedSecretPqdga algorithm;
  final Uint8List hybridSessionKey;
  final Uint8List classicalSharedSecret;
  final Uint8List postQuantumSharedSecret;
  final Uint8List? kemCiphertext;
  final Uint8List? kemPublicKey;
  final PqKemAlgorithm kemAlgorithm;

  const HybridSharedSecretLabSession({
    required this.algorithm,
    required this.hybridSessionKey,
    required this.classicalSharedSecret,
    required this.postQuantumSharedSecret,
    required this.kemCiphertext,
    required this.kemPublicKey,
    required this.kemAlgorithm,
  });

  /// Config that re-derives the session key via combiner (no embedded session).
  HybridSharedSecretPqdga get asCombinerConfig => HybridSharedSecretPqdga(
        campaignId: algorithm.campaignId,
        tld: algorithm.tld,
        charset: algorithm.charset,
        domainSeparator: algorithm.domainSeparator,
        xof: algorithm.xof,
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
