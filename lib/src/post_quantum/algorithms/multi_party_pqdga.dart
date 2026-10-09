import 'dart:convert';
import 'dart:typed_data';

import 'package:pqdga/src/post_quantum/crypto/dns_label_codec.dart';
import 'package:pqdga/src/post_quantum/crypto/kmac256.dart';
import 'package:pqdga/src/post_quantum/crypto/shake_xof.dart';
import 'package:pqdga/src/post_quantum/pqdga_core.dart';

/// Multi-party joint-secret PQDGA (binding ladder R9e).
///
/// Namespace derivation requires **all** independent participant secrets:
///
/// ```
/// partyA ‖ partyB ‖ … → bindingKey → labels
/// ```
///
/// Distinct from [MultiRecipientPqdga] (one DEM key wrapped for N recipients).
/// Research: can deterministic namespace generation require participation from
/// multiple authorized parties?
///
/// Never log participant secrets or the binding key.
class MultiPartyPqdga extends PQDGAAlgorithm {
  final String campaignId;
  final List<String> tld;
  final String charset;
  final String domainSeparator;
  final String kdf;
  final String kmacCustomization;

  /// Independent party secrets (all required; order stabilized by sort of
  /// length-prefixed encodings inside the combiner).
  final List<Uint8List> partySecrets;

  /// Optional pre-combined binding key (lab shortcut).
  final Uint8List? bindingKey;

  /// Public group id for notebooks.
  final String groupId;

  /// Minimum parties required (== length of [partySecrets] when combining).
  final int minParties;

  const MultiPartyPqdga({
    this.campaignId = 'toy-campaign',
    this.tld = const ['.com', '.net', '.org'],
    this.charset = DnsLabelCodec.defaultCharset,
    this.domainSeparator = 'pqdga/v1/multiparty',
    this.kdf = 'KMAC256',
    this.kmacCustomization = 'pqdga/v1/multiparty',
    this.partySecrets = const [],
    this.bindingKey,
    this.groupId = 'lab-group',
    this.minParties = 2,
  });

  /// Combine independent secrets into one binding key (deterministic).
  static Uint8List combineSecrets({
    required List<Uint8List> secrets,
    String kdf = 'KMAC256',
    String kmacCustomization = 'pqdga/v1/multiparty',
    String domainSeparator = 'pqdga/v1/multiparty',
  }) {
    if (secrets.isEmpty) {
      throw ArgumentError('partySecrets must be non-empty');
    }
    for (final s in secrets) {
      if (s.isEmpty) {
        throw ArgumentError('party secret must be non-empty');
      }
    }
    // Stabilize order: sort by hex of secret so party submission order
    // does not change the namespace (lab model — not a live MPC protocol).
    final ordered = List<Uint8List>.from(secrets)
      ..sort((a, b) {
        final ah = a.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
        final bh = b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
        return ah.compareTo(bh);
      });

    final packed = <int>[
      ...utf8.encode(domainSeparator),
      0x00,
      ordered.length & 0xff,
    ];
    for (final s in ordered) {
      packed.addAll([(s.length >> 8) & 0xff, s.length & 0xff, ...s]);
    }
    final data = Uint8List.fromList(packed);
    final k = kdf.toUpperCase();
    if (k == 'KMAC256') {
      // Key = first secret after sort; data = full packed transcript.
      return Kmac256.macUtf8(
        key: ordered.first,
        data: data,
        outputLengthBytes: 32,
        customization: kmacCustomization,
      );
    }
    if (k == 'SHAKE256') {
      return ShakeXof.shake256(data, 32);
    }
    throw ArgumentError('unsupported kdf "$kdf"; use KMAC256 or SHAKE256');
  }

  /// Lab helper with N synthetic party secrets.
  static MultiPartyLabSession labEstablish({
    int partyCount = 2,
    List<Uint8List>? partySecrets,
    String campaignId = 'toy-campaign',
    List<String> tld = const ['.com', '.net', '.org'],
    String charset = DnsLabelCodec.defaultCharset,
    String domainSeparator = 'pqdga/v1/multiparty',
    String kdf = 'KMAC256',
    String kmacCustomization = 'pqdga/v1/multiparty',
    String groupId = 'lab-group',
  }) {
    if (partyCount < 2 && partySecrets == null) {
      throw ArgumentError('multi-party requires at least 2 parties');
    }
    final secrets =
        partySecrets ??
        List<Uint8List>.generate(
          partyCount,
          (i) => Uint8List.fromList(
            List<int>.generate(32, (j) => ((i + 1) * 17 + j) & 0xff),
          ),
        );
    if (secrets.length < 2) {
      throw ArgumentError('multi-party requires at least 2 secrets');
    }
    final binding = combineSecrets(
      secrets: secrets,
      kdf: kdf,
      kmacCustomization: kmacCustomization,
      domainSeparator: domainSeparator,
    );
    final algo = MultiPartyPqdga(
      campaignId: campaignId,
      tld: tld,
      charset: charset,
      domainSeparator: domainSeparator,
      kdf: kdf,
      kmacCustomization: kmacCustomization,
      partySecrets: secrets,
      bindingKey: binding,
      groupId: groupId,
      minParties: secrets.length,
    );
    return MultiPartyLabSession(
      algorithm: algo,
      partySecrets: secrets,
      bindingKey: binding,
    );
  }
}

/// Lab materials for [MultiPartyPqdga].
class MultiPartyLabSession {
  final MultiPartyPqdga algorithm;
  final List<Uint8List> partySecrets;
  final Uint8List bindingKey;

  const MultiPartyLabSession({
    required this.algorithm,
    required this.partySecrets,
    required this.bindingKey,
  });

  /// Config with secrets only (re-combine in generator).
  MultiPartyPqdga get asSecretsOnlyConfig => MultiPartyPqdga(
    campaignId: algorithm.campaignId,
    tld: algorithm.tld,
    charset: algorithm.charset,
    domainSeparator: algorithm.domainSeparator,
    kdf: algorithm.kdf,
    kmacCustomization: algorithm.kmacCustomization,
    partySecrets: partySecrets,
    groupId: algorithm.groupId,
    minParties: algorithm.minParties,
  );

  /// Drop one party — must fail generation (missing participant).
  MultiPartyPqdga withoutParty(int index) {
    if (index < 0 || index >= partySecrets.length) {
      throw RangeError.index(index, partySecrets, 'index');
    }
    final remaining = <Uint8List>[
      for (var i = 0; i < partySecrets.length; i++)
        if (i != index) partySecrets[i],
    ];
    return MultiPartyPqdga(
      campaignId: algorithm.campaignId,
      tld: algorithm.tld,
      charset: algorithm.charset,
      domainSeparator: algorithm.domainSeparator,
      kdf: algorithm.kdf,
      kmacCustomization: algorithm.kmacCustomization,
      partySecrets: remaining,
      groupId: algorithm.groupId,
      minParties: algorithm.minParties,
    );
  }
}
