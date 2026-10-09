import 'dart:convert';
import 'dart:typed_data';

import 'package:pqdga/src/post_quantum/crypto/dns_label_codec.dart';
import 'package:pqdga/src/post_quantum/crypto/kmac256.dart';
import 'package:pqdga/src/post_quantum/crypto/shake_xof.dart';
import 'package:pqdga/src/post_quantum/pqdga_core.dart';

/// Hierarchical delegated-namespace PQDGA (binding ladder R9d).
///
/// ```
/// root
///  ├── region-a
///  │     └── team-1
///  └── region-b
/// ```
///
/// Each path segment derives child material from the parent. Research:
/// delegation, compartmentalization, revocation, and per-subtree epoch rotate.
///
/// Provide either:
/// * [leafKey] already derived for [hierarchyPath], or
/// * [rootSecret] + [hierarchyPath] to derive in-lab.
///
/// Never log root or node keys.
class HierarchicalPqdga extends PQDGAAlgorithm {
  final String campaignId;
  final List<String> tld;
  final String charset;
  final String domainSeparator;
  final String kdf;
  final String kmacCustomization;

  /// Path segments from root child downward, e.g. `['region-a', 'team-1']`.
  final List<String> hierarchyPath;

  /// Pre-derived leaf key for [hierarchyPath].
  final Uint8List? leafKey;

  /// Root secret for lab derivation.
  final Uint8List? rootSecret;

  /// Public tree id for notebooks.
  final String hierarchyId;

  const HierarchicalPqdga({
    this.campaignId = 'toy-campaign',
    this.tld = const ['.com', '.net', '.org'],
    this.charset = DnsLabelCodec.defaultCharset,
    this.domainSeparator = 'pqdga/v1/hierarchy',
    this.kdf = 'KMAC256',
    this.kmacCustomization = 'pqdga/v1/hierarchy',
    this.hierarchyPath = const ['region-a', 'team-1'],
    this.leafKey,
    this.rootSecret,
    this.hierarchyId = 'lab-tree',
  });

  /// Derive child key from [parentKey] for one path [segment].
  static Uint8List deriveChild({
    required Uint8List parentKey,
    required String segment,
    String kdf = 'KMAC256',
    String kmacCustomization = 'pqdga/v1/hierarchy',
    String domainSeparator = 'pqdga/v1/hierarchy',
  }) {
    if (segment.isEmpty) {
      throw ArgumentError('hierarchy segment must be non-empty');
    }
    final info = Uint8List.fromList([
      ...utf8.encode(domainSeparator),
      0x00,
      ...utf8.encode('node'),
      0x00,
      ...utf8.encode(segment),
    ]);
    final k = kdf.toUpperCase();
    if (k == 'KMAC256') {
      return Kmac256.macUtf8(
        key: parentKey,
        data: info,
        outputLengthBytes: 32,
        customization: kmacCustomization,
      );
    }
    if (k == 'SHAKE256') {
      return ShakeXof.shake256(
        Uint8List.fromList([...parentKey, 0x00, ...info]),
        32,
      );
    }
    throw ArgumentError('unsupported kdf "$kdf"; use KMAC256 or SHAKE256');
  }

  /// Walk [path] from [root] to leaf key.
  static Uint8List deriveLeaf({
    required Uint8List root,
    required List<String> path,
    String kdf = 'KMAC256',
    String kmacCustomization = 'pqdga/v1/hierarchy',
    String domainSeparator = 'pqdga/v1/hierarchy',
  }) {
    if (path.isEmpty) {
      throw ArgumentError('hierarchyPath must be non-empty');
    }
    var key = Uint8List.fromList(root);
    for (final segment in path) {
      key = deriveChild(
        parentKey: key,
        segment: segment,
        kdf: kdf,
        kmacCustomization: kmacCustomization,
        domainSeparator: domainSeparator,
      );
    }
    return key;
  }

  /// Lab helper with fixed root and default path.
  static HierarchicalLabSession labEstablish({
    Uint8List? rootSecret,
    List<String> hierarchyPath = const ['region-a', 'team-1'],
    String campaignId = 'toy-campaign',
    List<String> tld = const ['.com', '.net', '.org'],
    String charset = DnsLabelCodec.defaultCharset,
    String domainSeparator = 'pqdga/v1/hierarchy',
    String kdf = 'KMAC256',
    String kmacCustomization = 'pqdga/v1/hierarchy',
    String hierarchyId = 'lab-tree',
  }) {
    final fixedRoot =
        rootSecret ??
        Uint8List.fromList(List<int>.generate(32, (i) => 0xD0 + (i & 0x0f)));
    final leaf = deriveLeaf(
      root: fixedRoot,
      path: hierarchyPath,
      kdf: kdf,
      kmacCustomization: kmacCustomization,
      domainSeparator: domainSeparator,
    );
    final algo = HierarchicalPqdga(
      campaignId: campaignId,
      tld: tld,
      charset: charset,
      domainSeparator: domainSeparator,
      kdf: kdf,
      kmacCustomization: kmacCustomization,
      hierarchyPath: hierarchyPath,
      leafKey: leaf,
      rootSecret: fixedRoot,
      hierarchyId: hierarchyId,
    );
    return HierarchicalLabSession(
      algorithm: algo,
      rootSecret: fixedRoot,
      leafKey: leaf,
      hierarchyPath: List<String>.from(hierarchyPath),
    );
  }
}

/// Lab materials for [HierarchicalPqdga].
class HierarchicalLabSession {
  final HierarchicalPqdga algorithm;
  final Uint8List rootSecret;
  final Uint8List leafKey;
  final List<String> hierarchyPath;

  const HierarchicalLabSession({
    required this.algorithm,
    required this.rootSecret,
    required this.leafKey,
    required this.hierarchyPath,
  });

  /// Leaf-only config (parent/root deleted — compartment drill).
  HierarchicalPqdga get asLeafOnlyConfig => HierarchicalPqdga(
    campaignId: algorithm.campaignId,
    tld: algorithm.tld,
    charset: algorithm.charset,
    domainSeparator: algorithm.domainSeparator,
    kdf: algorithm.kdf,
    kmacCustomization: algorithm.kmacCustomization,
    hierarchyPath: hierarchyPath,
    leafKey: leafKey,
    hierarchyId: algorithm.hierarchyId,
  );

  /// Sibling path under same root (different compartment).
  HierarchicalLabSession deriveSibling(List<String> path) {
    final leaf = HierarchicalPqdga.deriveLeaf(
      root: rootSecret,
      path: path,
      kdf: algorithm.kdf,
      kmacCustomization: algorithm.kmacCustomization,
      domainSeparator: algorithm.domainSeparator,
    );
    final algo = HierarchicalPqdga(
      campaignId: algorithm.campaignId,
      tld: algorithm.tld,
      charset: algorithm.charset,
      domainSeparator: algorithm.domainSeparator,
      kdf: algorithm.kdf,
      kmacCustomization: algorithm.kmacCustomization,
      hierarchyPath: path,
      leafKey: leaf,
      rootSecret: rootSecret,
      hierarchyId: algorithm.hierarchyId,
    );
    return HierarchicalLabSession(
      algorithm: algo,
      rootSecret: rootSecret,
      leafKey: leaf,
      hierarchyPath: List<String>.from(path),
    );
  }
}
