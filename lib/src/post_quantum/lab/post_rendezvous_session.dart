// Prefixed deliberately: pqcrypto also exports a symbol named secureZero,
// and its implementation is a plain loop without the DSE guard. Under
// 'pub downgrade' both become visible through pqforge and the plain
// import becomes AMBIGUOUS_IMPORT. This must be the hardened one.
import 'package:zeroize/zeroize.dart' as zeroize;
import 'dart:convert';
import 'dart:typed_data';

import 'package:pqforge/pqforge.dart';
import 'package:pqdga/src/post_quantum/pqdga_result.dart';

/// Post-rendezvous AEAD lab phase using [PqForgeSecureSession].
///
/// **Not a DGA family.** After both sides derive the same domain list / shared
/// secret, application traffic is protected with AES-256-GCM or
/// ChaCha20-Poly1305. This models H7 “anti-sinkhole” beyond DNS: resolving a
/// sinkhole IP is insufficient if the bot requires an authenticated session.
///
/// Lab only — ephemeral keys, toy AAD, never operational C2.
class PostRendezvousSession {
  /// 32-byte session key (typically ML-KEM ss or hybrid combiner output).
  final Uint8List sessionKey;

  /// AEAD suite for the secure session.
  final PqForgeCipherSuite cipherSuite;

  /// Engine backend (pure-Dart PointyCastle by default).
  final PqForgeEngineProvider engineProvider;

  /// Domain / epoch AAD binder (non-secret routing context).
  final String associatedContext;

  PqForgeSecureSession? _session;

  PostRendezvousSession({
    required Uint8List sessionKey,
    this.cipherSuite = PqForgeCipherSuite.aes256Gcm,
    this.engineProvider = PqForgeEngineProvider.pureDart,
    this.associatedContext = 'pqdga/v1/post-rendezvous',
  }) : sessionKey = Uint8List.fromList(sessionKey) {
    if (this.sessionKey.length != 32) {
      throw ArgumentError.value(
        this.sessionKey.length,
        'sessionKey.length',
        'must be 32 bytes for PqForgeSecureSession',
      );
    }
  }

  /// Build from a SharedSecret-style 32-byte ss after name generation.
  factory PostRendezvousSession.fromSharedSecret(
    Uint8List sharedSecret, {
    PqForgeCipherSuite cipherSuite = PqForgeCipherSuite.aes256Gcm,
    String associatedContext = 'pqdga/v1/post-rendezvous',
    String? domainBinder,
    String? epoch,
  }) {
    final ctx = [
      associatedContext,
      if (epoch != null) 'epoch=$epoch',
      if (domainBinder != null) 'domain=$domainBinder',
    ].join('|');
    return PostRendezvousSession(
      sessionKey: sharedSecret,
      cipherSuite: cipherSuite,
      associatedContext: ctx,
    );
  }

  /// Bind AAD to the first generated domain + epoch from a PQ result.
  factory PostRendezvousSession.fromPqdgaResult(
    PQDGAResult result,
    Uint8List sessionKey, {
    PqForgeCipherSuite cipherSuite = PqForgeCipherSuite.aes256Gcm,
  }) {
    final domain = result.domains.isEmpty ? '' : result.domains.first;
    return PostRendezvousSession.fromSharedSecret(
      sessionKey,
      cipherSuite: cipherSuite,
      domainBinder: domain,
      epoch: result.epoch,
    );
  }

  PqForgeSecureSession get session {
    return _session ??= PqForgeSecureSession(
      secretKey: sessionKey,
      cipherSuite: cipherSuite,
      engineProvider: engineProvider,
    );
  }

  Uint8List get associatedData =>
      Uint8List.fromList(utf8.encode(associatedContext));

  /// Encrypt a lab application payload after rendezvous.
  Future<Uint8List> seal(Uint8List payload) =>
      session.encrypt(payload, associatedData: associatedData);

  /// Decrypt a peer packet; fails closed on AAD/tag mismatch.
  Future<Uint8List> open(Uint8List packet) =>
      session.decrypt(packet, associatedData: associatedData);

  /// Round-trip drill: seal → open must recover [payload].
  Future<bool> roundTripOk(Uint8List payload) async {
    final packet = await seal(payload);
    final clear = await open(packet);
    if (clear.length != payload.length) return false;
    for (var i = 0; i < clear.length; i++) {
      if (clear[i] != payload[i]) return false;
    }
    return true;
  }

  /// Non-secret IOC / notebook summary (never includes key bytes).
  Map<String, dynamic> iocTemplate({int? lastPacketLength}) => {
    'phase': 'post_rendezvous',
    'not_a_dga': true,
    'cipher_suite': cipherSuite.id,
    'cipher_suite_display': cipherSuite.displayName,
    'engine': engineProvider.name,
    'key_length': 32,
    'aad_context': associatedContext,
    'nonce_length': cipherSuite.nonceLength,
    'tag_length': cipherSuite.tagLength,
    'last_packet_length': ?lastPacketLength,
    'soc_lesson':
        'Sinkhole IP alone fails if bot requires AEAD session after DGA',
    'hardness_h7': 2,
  };

  /// Wipe session key material.
  ///
  /// Uses `package:zeroize`'s `secureZero`, which is
  /// `@pragma('vm:never-inline')` and anchors the writes with opaque reads, so
  /// they survive Dead Store Elimination in AOT. A `fillRange(0, n, 0)` loop
  /// does not, which is what this replaced.
  ///
  /// Safe to call more than once.
  void dispose() {
    _session?.dispose();
    _session = null;
    zeroize.secureZero(sessionKey);
  }
}
