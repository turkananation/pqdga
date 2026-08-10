import 'dart:typed_data';

import 'package:pqdga/src/post_quantum/crypto/dns_label_codec.dart';
import 'package:pqdga/src/post_quantum/pqdga_core.dart';

/// Baseline PQ-hard *hash* expander DGA (SHAKE256 over public epoch/campaign).
///
/// **SOC lesson:** PQ hash ≠ secret. With [seedPublic] true (default), names are
/// fully precomputable offline — same sinkhole story as classical date DGAs.
/// Optional [secretMaterial] demonstrates a secret-bound mode for contrast labs.
class QuantumResistantPqdga extends PQDGAAlgorithm {
  /// Toy campaign identifier (never a live operator secret).
  final String campaignId;

  /// TLD list; entries may include or omit the leading dot.
  final List<String> tld;

  /// Label charset (default LDH alphanumeric lowercase).
  final String charset;

  /// When true (default), seed is public epoch+campaign only → [predictable].
  final bool seedPublic;

  /// Optional non-public bytes bound into the XOF input when [seedPublic] is false.
  /// Lab only — never log this value.
  final Uint8List? secretMaterial;

  /// Domain-separation prefix absorbed into the XOF input.
  final String domainSeparator;

  /// XOF algorithm id recorded in results (`SHAKE256` or `SHAKE128`).
  final String xof;

  const QuantumResistantPqdga({
    this.campaignId = 'toy-campaign',
    this.tld = const ['.com', '.net', '.org'],
    this.charset = DnsLabelCodec.defaultCharset,
    this.seedPublic = true,
    this.secretMaterial,
    this.domainSeparator = 'pqdga/v1/label',
    this.xof = 'SHAKE256',
  });
}
