import 'dart:typed_data';

/// Result of post-quantum DGA generation with SOC / lab metadata.
///
/// Never place shared secrets or private keys in [seed] or [metadata].
class PQDGAResult {
  /// Generated FQDNs (or abstract rendezvous ids for decentralized modes).
  final List<String> domains;

  /// Lab date used for epoch bucketing.
  final DateTime generationDate;

  /// Human-readable family name.
  final String algorithm;

  /// Non-secret explainability string (packed epoch, campaign toy id, …).
  final String seed;

  /// `true` if offline precompute works without a secret.
  final bool predictable;

  /// `true` if ML-KEM ss / non-public seed is required to generate names.
  final bool secretBound;

  /// Epoch / date bucket identifier (e.g. `2024-01-01` or rotation id).
  final String? epoch;

  /// Domain expander identifier (e.g. `SHAKE256`).
  final String xof;

  /// KEM algorithm id for IOC templates (e.g. `ML-KEM-768`).
  final String? kemAlgorithm;

  /// Expected KEM ciphertext length in bytes (wire-size IOC).
  final int? kemCiphertextLength;

  /// Signature algorithm id (e.g. `ML-DSA-65`).
  final String? sigAlgorithm;

  /// Expected signature length in bytes (wire-size IOC).
  final int? signatureLength;

  /// Optional detached signatures over canonical(domain‖epoch‖campaign).
  final List<Uint8List>? signatures;

  /// Hex fingerprint of operator verification key (config-extraction target).
  final String? pubkeyFingerprint;

  /// Free-form analyst hooks (charset, playbook flags, campaign toy id).
  final Map<String, dynamic> metadata;

  PQDGAResult({
    required this.domains,
    required this.generationDate,
    required this.algorithm,
    required this.seed,
    required this.predictable,
    required this.secretBound,
    this.epoch,
    this.xof = 'SHAKE256',
    this.kemAlgorithm,
    this.kemCiphertextLength,
    this.sigAlgorithm,
    this.signatureLength,
    this.signatures,
    this.pubkeyFingerprint,
    this.metadata = const {},
  });

  /// Convenience: classical-style summary without PQ-only fields.
  Map<String, dynamic> toSocSummary() => {
        'algorithm': algorithm,
        'domains': domains.length,
        'predictable': predictable,
        'secret_bound': secretBound,
        'epoch': epoch,
        'xof': xof,
        if (kemAlgorithm != null) 'kem_algorithm': kemAlgorithm,
        if (kemCiphertextLength != null)
          'kem_ciphertext_length': kemCiphertextLength,
        if (sigAlgorithm != null) 'sig_algorithm': sigAlgorithm,
        if (signatureLength != null) 'signature_length': signatureLength,
        if (pubkeyFingerprint != null)
          'pubkey_fingerprint': pubkeyFingerprint,
        'metadata': metadata,
      };

  @override
  String toString() {
    return 'PQDGAResult(algo: $algorithm, date: $generationDate, '
        'domains: ${domains.length}, predictable: $predictable, '
        'secretBound: $secretBound)';
  }
}
