import 'dart:typed_data';

import 'package:pqdga/src/classical/dga_core.dart';

/// Seed-from-public-oracle DGA (research generic, R8).
///
/// Names expand from an external public stream (blockchain tip, trend hash,
/// weather API digest, …) rather than pure wall-clock date.
/// **SOC lesson:** pure date sinkholing fails — need the oracle feed or
/// first-seen PDNS.
///
/// Difficulty: [oracle-seeded].
class OracleSeedDGA extends DGAAlgorithm {
  /// Oracle material (e.g. block hash bytes). Required for generation.
  final Uint8List? oracleMaterial;

  /// Human-readable oracle id for metadata (`btc-tip`, `twitter-trend`, …).
  final String oracleId;

  /// TLD list.
  final List<String> tld;

  /// Label length bounds.
  final int minDomainLength;
  final int maxDomainLength;

  /// Charset for LDH labels.
  final String charset;

  /// Optional domain-separation string mixed into seed packing.
  final String domainSeparator;

  const OracleSeedDGA({
    this.oracleMaterial,
    this.oracleId = 'lab-oracle',
    this.tld = const ['.com', '.net', '.org'],
    this.minDomainLength = 10,
    this.maxDomainLength = 18,
    this.charset = 'abcdefghijklmnopqrstuvwxyz0123456789',
    this.domainSeparator = 'pqdga/v1/oracle',
  });
}
