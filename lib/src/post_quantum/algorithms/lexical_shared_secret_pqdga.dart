import 'dart:typed_data';

import 'package:pqforge/pqforge.dart';
import 'package:pqdga/src/post_quantum/crypto/lexical_label_codec.dart';
import 'package:pqdga/src/post_quantum/pqdga_core.dart';

/// Secret-bound PQDGA with dictionary/Markov/pronounceable label encoding (H5).
///
/// Same cryptographic binding as [SharedSecretPqdga] (ML-KEM ss → SHAKE/KMAC),
/// but maps XOF output through [LexicalLabelCodec] so labels look English-ish.
///
/// **SOC lesson:** secret-bound ≠ high entropy on the wire. Defenders need
/// lexical/LM models in addition to behavior and secret extraction.
///
/// Never log [sharedSecret] or KEM secret keys.
class LexicalSharedSecretPqdga extends PQDGAAlgorithm {
  final String campaignId;
  final List<String> tld;

  /// Lexical mode: `markov`, `dictionary`, `pronounceable`, or `charset`.
  final String lexicalMode;

  /// Charset for markov/charset modes.
  final String charset;

  /// Wordlist for dictionary mode (lab toy list by default).
  final List<String> wordlist;

  final String domainSeparator;

  /// Expand KDF: `SHAKE256` (default) or `KMAC256`.
  final String kdf;

  /// KMAC customization when [kdf] is KMAC256.
  final String kmacCustomization;

  final Uint8List? sharedSecret;
  final PqKemAlgorithm kemAlgorithm;
  final Uint8List? kemCiphertext;
  final Uint8List? kemSecretKey;
  final Uint8List? kemPublicKey;
  final Uint8List? encapsNonce;

  const LexicalSharedSecretPqdga({
    this.campaignId = 'toy-campaign',
    this.tld = const ['.com', '.net', '.org'],
    this.lexicalMode = 'markov',
    this.charset = LexicalLabelCodec.alpha,
    this.wordlist = LexicalLabelCodec.defaultWordlist,
    this.domainSeparator = 'pqdga/v1/lexical-ss',
    this.kdf = 'SHAKE256',
    this.kmacCustomization = 'pqdga/v1/lexical-ss',
    this.sharedSecret,
    this.kemAlgorithm = PqKemAlgorithm.mlKem768,
    this.kemCiphertext,
    this.kemSecretKey,
    this.kemPublicKey,
    this.encapsNonce,
  });

  /// Lab helper: ephemeral ML-KEM encaps → ready lexical secret-bound config.
  static LexicalSharedSecretLabSession labEstablish({
    PqKemAlgorithm algorithm = PqKemAlgorithm.mlKem768,
    Uint8List? encapsNonce,
    Uint8List? kemSeed,
    String campaignId = 'toy-campaign',
    List<String> tld = const ['.com', '.net', '.org'],
    String lexicalMode = 'markov',
    String charset = LexicalLabelCodec.alpha,
    List<String> wordlist = LexicalLabelCodec.defaultWordlist,
    String domainSeparator = 'pqdga/v1/lexical-ss',
    String kdf = 'SHAKE256',
    String kmacCustomization = 'pqdga/v1/lexical-ss',
  }) {
    final forge = const PqForge();
    final kp = forge.generateKemKeyPair(algorithm: algorithm, seed: kemSeed);
    final enc = forge.encapsulate(
      kp.publicKey,
      algorithm: algorithm,
      nonce: encapsNonce,
    );
    return LexicalSharedSecretLabSession(
      algorithm: LexicalSharedSecretPqdga(
        campaignId: campaignId,
        tld: tld,
        lexicalMode: lexicalMode,
        charset: charset,
        wordlist: wordlist,
        domainSeparator: domainSeparator,
        kdf: kdf,
        kmacCustomization: kmacCustomization,
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

/// Ephemeral lab materials from [LexicalSharedSecretPqdga.labEstablish].
class LexicalSharedSecretLabSession {
  final LexicalSharedSecretPqdga algorithm;
  final Uint8List kemSecretKey;
  final Uint8List sharedSecret;
  final Uint8List kemCiphertext;
  final Uint8List kemPublicKey;
  final PqKemAlgorithm kemAlgorithm;

  const LexicalSharedSecretLabSession({
    required this.algorithm,
    required this.kemSecretKey,
    required this.sharedSecret,
    required this.kemCiphertext,
    required this.kemPublicKey,
    required this.kemAlgorithm,
  });

  LexicalSharedSecretPqdga get asDecapsConfig => LexicalSharedSecretPqdga(
        campaignId: algorithm.campaignId,
        tld: algorithm.tld,
        lexicalMode: algorithm.lexicalMode,
        charset: algorithm.charset,
        wordlist: algorithm.wordlist,
        domainSeparator: algorithm.domainSeparator,
        kdf: algorithm.kdf,
        kmacCustomization: algorithm.kmacCustomization,
        kemAlgorithm: kemAlgorithm,
        kemCiphertext: kemCiphertext,
        kemSecretKey: kemSecretKey,
        kemPublicKey: kemPublicKey,
      );
}
