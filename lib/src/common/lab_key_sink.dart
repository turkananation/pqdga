/// Emitting generated key material so the caller can put it somewhere safe.
///
/// Every `labEstablish` helper generates real key material — ML-KEM
/// decapsulation keys, ML-DSA signing keys, KMAC keys — and returns it on a
/// session object. A [LabKeySink] is the seam for handing that material off at
/// the moment it is produced.
///
/// ## Keys are emitted, never stored here
///
/// This package does **not** write key material to disk, and deliberately offers
/// no sink that does. Lab keys are secret material; a plaintext file on disk is
/// a worse custody story than not persisting at all, because it looks durable
/// while being unprotected.
///
/// **Custody belongs to [`pqkeystore`](https://pub.dev/packages/pqkeystore).**
/// Wire [CallbackLabKeySink] to a `PqKeystore.put` call and the key is sealed by
/// the selected provider before it touches storage:
///
/// ```dart
/// final keystore = PqKeystore(backend: createBackend(BackendType.platform), ...);
///
/// final session = SharedSecretPqdga.labEstablish(
///   keySink: CallbackLabKeySink(
///     onKey: (key) => keystore.put(
///       metadataForDgaKey(key),
///       key.bytes,
///       PassphraseUnlock(passphrase),
///     ),
///     onFinish: (count) => print('stored $count keys'),
///   ),
/// );
/// ```
///
/// If you have no custodian wired up, omit the sink. The session still holds the
/// material and still exposes `dispose()`.
library;

import 'dart:typed_data';

/// One piece of key material offered to a [LabKeySink].
///
/// [bytes] is the live buffer the session owns. A sink that needs to keep it must
/// copy.
typedef LabKey = ({
  /// Stable identifier, e.g. `kem-secret` or `signature-secret`.
  String name,

  /// Algorithm id, e.g. `ml-kem-768` or `ml-dsa-65`.
  String algorithm,

  /// Whether this material is secret. Public keys are offered too, so a caller
  /// can record provenance without storing anything sensitive.
  bool secret,

  /// The key bytes.
  Uint8List bytes,
});

/// Receives key material as a lab session is established.
///
/// Implementations must not retain [LabKey.bytes] beyond the call unless they take
/// a copy; the session may wipe it later.
abstract interface class LabKeySink {
  /// Called once per generated key, in generation order.
  ///
  /// Throwing aborts the establishment, so an implementation that cannot store
  /// the key should throw rather than continue silently.
  void record(LabKey key);

  /// Called once after all keys have been recorded.
  ///
  /// Lets a caller flush or report. [count] is how many keys were recorded.
  void finish(int count);
}

/// Collects keys in memory, for a caller that wants to inspect them itself.
///
/// Nothing leaves the process. [clear] wipes the stored copies.
final class InMemoryLabKeySink implements LabKeySink {
  final List<LabKey> _keys = [];

  /// Keys recorded so far, in generation order.
  List<LabKey> get keys => List.unmodifiable(_keys);

  /// How many keys were recorded.
  int get length => _keys.length;

  @override
  void record(LabKey key) => _keys.add(key);

  @override
  void finish(int count) {}

  /// Forgets every recorded key.
  void clear() => _keys.clear();
}

/// Forwards every key to a callback.
///
/// This is the integration seam for `pqkeystore`: pass a callback that seals and
/// stores, and the material never exists unprotected outside the session.
final class CallbackLabKeySink implements LabKeySink {
  /// Creates a sink that calls [onKey] per key and [onFinish] at the end.
  CallbackLabKeySink(this.onKey, this.onFinish);

  /// Invoked once per key.
  final void Function(LabKey key) onKey;

  /// Invoked once at the end.
  final void Function(int count) onFinish;

  @override
  void record(LabKey key) => onKey(key);

  @override
  void finish(int count) => onFinish(count);
}
