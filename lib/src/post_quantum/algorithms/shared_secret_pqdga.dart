import 'package:zeroize/zeroize.dart';
import 'dart:typed_data';

import 'package:pqforge/pqforge.dart';
import 'package:pqdga/src/post_quantum/crypto/dns_label_codec.dart';
import 'package:pqdga/src/post_quantum/pqdga_core.dart';

/// Shared-secret PQ DGA: ML-KEM shared secret bound into SHAKE expand.
///
/// **SOC lesson:** Without the shared secret, offline precompute fails.
/// Defenders shift to behavior (resolution bursts, DoH), registration
/// telemetry, and sinkhole-after-first-observe — not pure date precompute.
///
/// Provide exactly one way to obtain the secret:
/// * [sharedSecret] directly (both sides already hold ss), or
/// * [kemSecretKey] + [kemCiphertext] (decapsulate), or
/// * [kemPublicKey] (encapsulate; supply [encapsNonce] for deterministic labs).
///
/// Never log [sharedSecret] or secret keys. Ciphertext length + KEM id are OK IOCs.
class SharedSecretPqdga extends PQDGAAlgorithm {
  /// Toy campaign identifier (never a live operator secret).
  final String campaignId;

  /// TLD list; entries may include or omit the leading dot.
  final List<String> tld;

  /// Label charset (default LDH alphanumeric lowercase).
  final String charset;

  /// Domain-separation prefix absorbed into the XOF input.
  final String domainSeparator;

  /// XOF algorithm id recorded in results (`SHAKE256` or `SHAKE128`).
  final String xof;

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

  const SharedSecretPqdga({
    this.campaignId = 'toy-campaign',
    this.tld = const ['.com', '.net', '.org'],
    this.charset = DnsLabelCodec.defaultCharset,
    this.domainSeparator = 'pqdga/v1/shared-secret',
    this.xof = 'SHAKE256',
    this.sharedSecret,
    this.kemAlgorithm = PqKemAlgorithm.mlKem768,
    this.kemCiphertext,
    this.kemSecretKey,
    this.kemPublicKey,
    this.encapsNonce,
  });

  /// Lab helper: ephemeral ML-KEM keygen + encapsulate → ready algorithm config.
  ///
  /// Returns algorithm with [sharedSecret] + [kemCiphertext] filled (never logs ss).
  /// [kemSecretKey] is returned separately for decaps round-trip drills only.
  static SharedSecretLabSession labEstablish({
    PqKemAlgorithm algorithm = PqKemAlgorithm.mlKem768,
    Uint8List? encapsNonce,
    Uint8List? kemSeed,
    String campaignId = 'toy-campaign',
    List<String> tld = const ['.com', '.net', '.org'],
    String charset = DnsLabelCodec.defaultCharset,
    String domainSeparator = 'pqdga/v1/shared-secret',
    String xof = 'SHAKE256',
  }) {
    final forge = const PqForge();
    final kp = forge.generateKemKeyPair(algorithm: algorithm, seed: kemSeed);
    final enc = forge.encapsulate(
      kp.publicKey,
      algorithm: algorithm,
      nonce: encapsNonce,
    );
    return SharedSecretLabSession(
      algorithm: SharedSecretPqdga(
        campaignId: campaignId,
        tld: tld,
        charset: charset,
        domainSeparator: domainSeparator,
        xof: xof,
        sharedSecret: enc.sharedSecret,
        kemAlgorithm: algorithm,
        kemCiphertext: enc.ciphertext,
        kemPublicKey: kp.publicKey,
      ),
      kemSecretKey: kp.secretKey,
      sharedSecret: enc.sharedSecret,
      kemCiphertext: enc.ciphertext,
      kemPublicKey: kp.publicKey,
      kemAlgorithm: algorithm,
    );
  }
}

/// Ephemeral lab materials from [SharedSecretPqdga.labEstablish].
///
/// Keep [sharedSecret] / [kemSecretKey] out of logs and SOC summaries.
class SharedSecretLabSession {
  /// Generator-ready algorithm (includes ss — treat as sensitive in process).
  final SharedSecretPqdga algorithm;

  /// Decaps secret key for round-trip verification drills.
  final Uint8List kemSecretKey;

  /// Same ss bound into [algorithm] (convenience; do not log).
  final Uint8List sharedSecret;

  /// Encaps ciphertext (safe length/IOC artifact).
  final Uint8List kemCiphertext;

  /// KEM public key used for encaps.
  final Uint8List kemPublicKey;

  /// Parameter set.
  final PqKemAlgorithm kemAlgorithm;

  /// Wipes [kemSecretKey] and [sharedSecret].
  ///
  /// Both fields are live key material for as long as this session exists, and
  /// the class documentation already warns not to log them. There was previously
  /// no way to clear them at all.
  ///
  /// Uses `package:zeroize`'s `secureZero`, which is
  /// `@pragma('vm:never-inline')` and anchors the writes with opaque reads so
  /// they survive Dead Store Elimination in AOT.
  ///
  /// Safe to call more than once. [kemPublicKey] and [kemCiphertext] are not
  /// wiped: both are public artifacts.
  ///
  /// This is best-effort erasure, not a memory-erasure guarantee. Pure Dart
  /// cannot stop the GC from copying a buffer, and has no `mlock` equivalent.
  void dispose() {
    secureZero(kemSecretKey);
    secureZero(sharedSecret);
  }

  const SharedSecretLabSession({
    required this.algorithm,
    required this.kemSecretKey,
    required this.sharedSecret,
    required this.kemCiphertext,
    required this.kemPublicKey,
    required this.kemAlgorithm,
  });

  /// Algorithm view that recovers ss via decaps only (no embedded ss field).
  SharedSecretPqdga get asDecapsConfig => SharedSecretPqdga(
        campaignId: algorithm.campaignId,
        tld: algorithm.tld,
        charset: algorithm.charset,
        domainSeparator: algorithm.domainSeparator,
        xof: algorithm.xof,
        kemAlgorithm: kemAlgorithm,
        kemCiphertext: kemCiphertext,
        kemSecretKey: kemSecretKey,
        kemPublicKey: kemPublicKey,
      );
}
