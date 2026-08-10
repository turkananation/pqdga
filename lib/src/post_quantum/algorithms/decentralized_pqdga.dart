import 'dart:typed_data';

import 'package:pqforge/pqforge.dart';
import 'package:pqdga/src/post_quantum/algorithms/signature_authenticated_pqdga.dart';
import 'package:pqdga/src/post_quantum/pqdga_core.dart';

/// Decentralized / content-addressed rendezvous ids (R6).
///
/// **SOC lesson (P7):** Pure DNS RPZ is incomplete — ids may be base32 DNS
/// labels **or** non-DNS abstract handles derived from SHAKE(vk‖epoch‖i).
/// Extend monitoring notes beyond classic domain blocklists.
///
/// [namespaceKey] is typically an ML-DSA vk (predictable once extracted).
class DecentralizedPqdga extends PQDGAAlgorithm {
  /// Toy campaign identifier (never a live operator secret).
  final String campaignId;

  /// Optional TLD list when [dnsMode] is true.
  final List<String> tld;

  /// Namespace public key (vk/pk) bound into the XOF. Required.
  final Uint8List? namespaceKey;

  /// Domain-separation prefix absorbed into the XOF input.
  final String domainSeparator;

  /// XOF algorithm id (`SHAKE256` or `SHAKE128`).
  final String xof;

  /// Encoding of XOF bytes: `base32`, `hex`, or `ldh` (mod charset).
  final String encoding;

  /// When true, emit FQDN-style labels with [tld]; when false, abstract ids.
  final bool dnsMode;

  /// Raw entropy bytes squeezed before encoding (clamped for DNS label limits).
  final int idByteLength;

  /// Kind tag for IOC templates.
  final String namespaceKind;

  const DecentralizedPqdga({
    this.campaignId = 'toy-campaign',
    this.tld = const ['.com', '.net', '.org'],
    this.namespaceKey,
    this.domainSeparator = 'pqdga/v1/decentralized',
    this.xof = 'SHAKE256',
    this.encoding = 'base32',
    this.dnsMode = true,
    this.idByteLength = 16,
    this.namespaceKind = 'ml-dsa-vk',
  });

  /// Lab helper: ephemeral ML-DSA vk as namespace.
  static DecentralizedLabSession labEstablish({
    PqSignatureAlgorithm algorithm = PqSignatureAlgorithm.mlDsa65,
    Uint8List? sigSeed,
    String campaignId = 'toy-campaign',
    List<String> tld = const ['.com', '.net', '.org'],
    String domainSeparator = 'pqdga/v1/decentralized',
    String xof = 'SHAKE256',
    String encoding = 'base32',
    bool dnsMode = true,
    int idByteLength = 16,
  }) {
    final forge = const PqForge();
    final kp = sigSeed == null
        ? forge.generateSignatureKeyPair(algorithm: algorithm)
        : forge.generateSignatureKeyPairFromSeed(sigSeed, algorithm: algorithm);
    final algo = DecentralizedPqdga(
      campaignId: campaignId,
      tld: tld,
      namespaceKey: kp.publicKey,
      domainSeparator: domainSeparator,
      xof: xof,
      encoding: encoding,
      dnsMode: dnsMode,
      idByteLength: idByteLength,
      namespaceKind: 'ml-dsa-vk',
    );
    return DecentralizedLabSession(
      algorithm: algo,
      namespaceKey: kp.publicKey,
      signatureSecretKey: kp.secretKey,
    );
  }

  /// Hex fingerprint of [namespaceKey].
  String? get pubkeyFingerprint {
    final pk = namespaceKey;
    if (pk == null || pk.isEmpty) return null;
    return SignatureAuthenticatedPqdga.pubkeyFingerprintOf(pk);
  }
}

/// Ephemeral lab materials from [DecentralizedPqdga.labEstablish].
class DecentralizedLabSession {
  final DecentralizedPqdga algorithm;
  final Uint8List namespaceKey;
  final Uint8List signatureSecretKey;

  const DecentralizedLabSession({
    required this.algorithm,
    required this.namespaceKey,
    required this.signatureSecretKey,
  });

  String get pubkeyFingerprint =>
      SignatureAuthenticatedPqdga.pubkeyFingerprintOf(namespaceKey);

  /// Abstract (non-DNS) id mode for channel-agility drills.
  DecentralizedPqdga get asAbstractConfig => DecentralizedPqdga(
        campaignId: algorithm.campaignId,
        tld: algorithm.tld,
        namespaceKey: namespaceKey,
        domainSeparator: algorithm.domainSeparator,
        xof: algorithm.xof,
        encoding: algorithm.encoding,
        dnsMode: false,
        idByteLength: algorithm.idByteLength,
        namespaceKind: algorithm.namespaceKind,
      );
}

/// Minimal RFC 4648 base32 (lowercase, no padding) for DNS-safe labels.
class Base32Codec {
  static const String alphabet = 'abcdefghijklmnopqrstuvwxyz234567';

  /// Encode [bytes] to unpadded lowercase base32.
  static String encode(Uint8List bytes) {
    if (bytes.isEmpty) return '';
    final out = StringBuffer();
    var buffer = 0;
    var bitsLeft = 0;
    for (final b in bytes) {
      buffer = (buffer << 8) | b;
      bitsLeft += 8;
      while (bitsLeft >= 5) {
        bitsLeft -= 5;
        out.write(alphabet[(buffer >> bitsLeft) & 0x1f]);
      }
    }
    if (bitsLeft > 0) {
      out.write(alphabet[(buffer << (5 - bitsLeft)) & 0x1f]);
    }
    return out.toString();
  }

  /// Encode [bytes] to lowercase hex.
  static String encodeHex(Uint8List bytes) {
    final buffer = StringBuffer();
    for (final b in bytes) {
      buffer.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
