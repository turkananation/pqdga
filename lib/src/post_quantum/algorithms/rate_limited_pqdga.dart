import 'dart:typed_data';

import 'package:pqdga/src/post_quantum/crypto/dns_label_codec.dart';
import 'package:pqdga/src/post_quantum/pqdga_core.dart';

/// Rate-limited adaptive PQ DGA (R6 extra).
///
/// Same public (or optional secret) SHAKE expand as QuantumResistant, but
/// generation is capped at [maxNamesPerHour] for detector training on
/// **low-volume** evasion. **SOC lesson:** longer observation windows; burst
/// sinkhole racing fails when N is tiny.
///
/// Difficulty: [trivial] if seed public; [secret-seeded] if secret bound.
class RateLimitedPqdga extends PQDGAAlgorithm {
  /// Toy campaign id.
  final String campaignId;

  /// TLD list.
  final List<String> tld;

  /// Label charset.
  final String charset;

  /// Domain-separation prefix.
  final String domainSeparator;

  /// XOF algorithm id.
  final String xof;

  /// Soft cap on names emitted per hour (lab policy).
  final int maxNamesPerHour;

  /// When true (default), seed is public epoch+campaign only.
  final bool seedPublic;

  /// Optional secret material when [seedPublic] is false.
  final Uint8List? secretMaterial;

  /// Optional adaptive factor recorded in metadata (1.0 = nominal).
  final double adaptiveFactor;

  const RateLimitedPqdga({
    this.campaignId = 'toy-rate-limit',
    this.tld = const ['.com', '.net', '.org'],
    this.charset = DnsLabelCodec.defaultCharset,
    this.domainSeparator = 'pqdga/v1/rate-limit',
    this.xof = 'SHAKE256',
    this.maxNamesPerHour = 4,
    this.seedPublic = true,
    this.secretMaterial,
    this.adaptiveFactor = 1.0,
  });

  /// Effective cap after adaptive factor (at least 1 when factor > 0).
  int get effectiveCap {
    final scaled = (maxNamesPerHour * adaptiveFactor).floor();
    if (scaled < 1) return 1;
    return scaled;
  }
}
