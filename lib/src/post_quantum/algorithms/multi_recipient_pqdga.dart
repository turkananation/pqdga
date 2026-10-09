// Prefixed deliberately: pqcrypto also exports a symbol named secureZero,
// and its implementation is a plain loop without the DSE guard. Under
// 'pub downgrade' both become visible through pqforge and the plain
// import becomes AMBIGUOUS_IMPORT. This must be the hardened one.
import 'package:zeroize/zeroize.dart' as zeroize;
import 'dart:typed_data';

import 'package:pqforge/pqforge.dart';
import 'package:pqdga/src/post_quantum/crypto/dns_label_codec.dart';
import 'package:pqdga/src/post_quantum/pqdga_core.dart';

/// Multi-recipient / threshold-style compartmentation PQ DGA (R6 extra).
///
/// Session key is established via ML-KEM to a **primary** recipient and
/// optionally wrapped for additional recipients (`PqMultiRecipient`). Labels
/// expand from the shared DEM/session key. **SOC lesson:** partial bot
/// takedown does not yield the key for other compartments.
///
/// Never log session keys or secret keys. CT lengths remain IOCs.
class MultiRecipientPqdga extends PQDGAAlgorithm {
  /// Toy campaign id.
  final String campaignId;

  /// TLD list.
  final List<String> tld;

  /// Label charset.
  final String charset;

  /// Domain-separation prefix.
  final String domainSeparator;

  /// XOF id.
  final String xof;

  /// KEM parameter set.
  final PqKemAlgorithm kemAlgorithm;

  /// Pre-combined session / DEM key (lab). Prefer via [labEstablish].
  final Uint8List? sessionKey;

  /// Primary recipient encaps ciphertext (IOC).
  final Uint8List? primaryKemCiphertext;

  /// Number of additional recipients wrapped (metadata IOC).
  final int additionalRecipientCount;

  /// Optional list of additional wrap entry sizes (bytes) for IOC templates.
  final List<int> additionalWrapEntrySizes;

  const MultiRecipientPqdga({
    this.campaignId = 'toy-multi-recipient',
    this.tld = const ['.com', '.net', '.org'],
    this.charset = DnsLabelCodec.defaultCharset,
    this.domainSeparator = 'pqdga/v1/multi-recipient',
    this.xof = 'SHAKE256',
    this.kemAlgorithm = PqKemAlgorithm.mlKem768,
    this.sessionKey,
    this.primaryKemCiphertext,
    this.additionalRecipientCount = 0,
    this.additionalWrapEntrySizes = const [],
  });

  /// Lab helper: primary + N additional ML-KEM recipients share one session key.
  static MultiRecipientLabSession labEstablish({
    int additionalRecipients = 2,
    PqKemAlgorithm algorithm = PqKemAlgorithm.mlKem768,
    Uint8List? primarySeed,
    Uint8List? encapsNonce,
    String campaignId = 'toy-multi-recipient',
    List<String> tld = const ['.com', '.net', '.org'],
    String charset = DnsLabelCodec.defaultCharset,
    String domainSeparator = 'pqdga/v1/multi-recipient',
    String xof = 'SHAKE256',
  }) {
    if (additionalRecipients < 0) {
      throw ArgumentError.value(
        additionalRecipients,
        'additionalRecipients',
        'must be >= 0',
      );
    }
    final forge = const PqForge();
    final primary = forge.generateKemKeyPair(
      algorithm: algorithm,
      seed: primarySeed,
    );
    final enc = forge.encapsulate(
      primary.publicKey,
      algorithm: algorithm,
      nonce: encapsNonce,
    );
    // Session key = primary shared secret (DEM key stand-in for lab).
    final sessionKey = Uint8List.fromList(enc.sharedSecret);

    final extraKeys = <PqKeyPair>[];
    final wrapSizes = <int>[];
    final wrapEntries = <Map<String, Object?>>[];
    for (var i = 0; i < additionalRecipients; i++) {
      final kp = forge.generateKemKeyPair(algorithm: algorithm);
      extraKeys.add(kp);
      final wrapEnc = forge.encapsulate(kp.publicKey, algorithm: algorithm);
      // Approximate wrap entry size: kem CT + small AEAD overhead (lab IOC).
      final entrySize = wrapEnc.ciphertext.length + 12 + 16 + 32;
      wrapSizes.add(entrySize);
      wrapEntries.add({
        'recipient_index': i,
        'kem_ciphertext_length': wrapEnc.ciphertext.length,
        'approx_entry_bytes': entrySize,
      });
      // Wipe the per-recipient shared secret. Uses package:zeroize rather than
      // fillRange(0, n, 0): secureZero is @pragma('vm:never-inline') with
      // opaque read anchors, so the writes survive Dead Store Elimination in
      // AOT. A bare fillRange does not.
      zeroize.secureZero(wrapEnc.sharedSecret);
    }

    final algo = MultiRecipientPqdga(
      campaignId: campaignId,
      tld: tld,
      charset: charset,
      domainSeparator: domainSeparator,
      xof: xof,
      kemAlgorithm: algorithm,
      sessionKey: sessionKey,
      primaryKemCiphertext: enc.ciphertext,
      additionalRecipientCount: additionalRecipients,
      additionalWrapEntrySizes: wrapSizes,
    );

    return MultiRecipientLabSession(
      algorithm: algo,
      sessionKey: sessionKey,
      primaryKemCiphertext: enc.ciphertext,
      primarySecretKey: primary.secretKey,
      primaryPublicKey: primary.publicKey,
      additionalKeyPairs: extraKeys,
      wrapEntries: wrapEntries,
      kemAlgorithm: algorithm,
    );
  }
}

/// Ephemeral lab materials from [MultiRecipientPqdga.labEstablish].
class MultiRecipientLabSession {
  final MultiRecipientPqdga algorithm;
  final Uint8List sessionKey;
  final Uint8List primaryKemCiphertext;
  final Uint8List primarySecretKey;
  final Uint8List primaryPublicKey;
  final List<PqKeyPair> additionalKeyPairs;
  final List<Map<String, Object?>> wrapEntries;
  final PqKemAlgorithm kemAlgorithm;

  const MultiRecipientLabSession({
    required this.algorithm,
    required this.sessionKey,
    required this.primaryKemCiphertext,
    required this.primarySecretKey,
    required this.primaryPublicKey,
    required this.additionalKeyPairs,
    required this.wrapEntries,
    required this.kemAlgorithm,
  });
}
