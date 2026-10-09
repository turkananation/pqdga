/// Key-emission seam, and the pqkeystore wiring it is designed for.
///
/// The contract these tests pin down:
///
/// 1. Passing no sink writes nothing anywhere and changes nothing.
/// 2. Passing a sink emits **every** generated key, marked secret or public.
/// 3. `finish` is called once, with the real count.
/// 4. pqdga offers **no** sink that writes key bytes to disk. Custody belongs to
///    `pqkeystore`, and the whole point of the callback seam is that the
///    material never exists unprotected outside the session.
///
/// That last one is why there is no filesystem test here. The absence is the
/// assertion.
library;

import 'package:pqforge/pqforge.dart' show PqKemAlgorithm;
import 'package:pqdga/pqdga.dart';
import 'package:test/test.dart';

void main() {
  group('SharedSecretPqdga.labEstablish — key emission', () {
    test('emits the KEM secret and public keys, correctly marked', () {
      final sink = InMemoryLabKeySink();

      SharedSecretPqdga.labEstablish(campaignId: 'emit', keySink: sink);

      expect(sink.length, 2);
      final secret = sink.keys.firstWhere((k) => k.name == 'kem-secret');
      final public = sink.keys.firstWhere((k) => k.name == 'kem-public');

      expect(secret.secret, isTrue);
      expect(public.secret, isFalse);
      expect(secret.algorithm, 'ML-KEM-768');
      expect(secret.bytes, isNotEmpty);
      expect(secret.bytes.length, 2400, reason: 'ML-KEM-768 decapsulation key');
      expect(public.bytes.length, 1184, reason: 'ML-KEM-768 encapsulation key');
    });

    test('emitted bytes are the session’s own buffers', () {
      final sink = InMemoryLabKeySink();
      final session = SharedSecretPqdga.labEstablish(keySink: sink);

      final secret = sink.keys.firstWhere((k) => k.name == 'kem-secret');
      // Same instance, so a sink that copies still gets what it needs and the
      // session's dispose() still reaches the original.
      expect(identical(secret.bytes, session.kemSecretKey), isTrue);

      session.dispose();
      expect(
        secret.bytes.every((b) => b == 0),
        isTrue,
        reason: 'dispose must wipe the buffer a sink was handed',
      );
    });

    test('honours the requested algorithm', () {
      final sink = InMemoryLabKeySink();
      SharedSecretPqdga.labEstablish(
        algorithm: PqKemAlgorithm.mlKem512,
        keySink: sink,
      );

      final secret = sink.keys.firstWhere((k) => k.name == 'kem-secret');
      expect(secret.algorithm, 'ML-KEM-512');
      expect(secret.bytes.length, 1632);
    });

    test('with no sink, nothing is recorded and the session still works', () {
      final session = SharedSecretPqdga.labEstablish(campaignId: 'no-sink');

      expect(session.kemSecretKey.any((b) => b != 0), isTrue);
      session.dispose();
    });
  });

  group('IdentityBasedPqdga.labEstablish — key emission', () {
    test('emits the signature secret and identity public keys', () {
      final sink = InMemoryLabKeySink();

      IdentityBasedPqdga.labEstablish(
        campaignId: 'emit',
        requireSignature: true,
        keySink: sink,
      );

      expect(sink.length, 2);
      final secret = sink.keys.firstWhere((k) => k.name == 'signature-secret');
      final public = sink.keys.firstWhere((k) => k.name == 'identity-public');

      expect(secret.secret, isTrue);
      expect(public.secret, isFalse);
      expect(secret.algorithm, 'ML-DSA-65');
      expect(secret.bytes.length, 4032);
      expect(public.bytes.length, 1952);
    });
  });

  group('CallbackLabKeySink — the pqkeystore integration shape', () {
    test('forwards each key and reports the count once', () {
      final seen = <String>[];
      var finished = -1;

      SharedSecretPqdga.labEstablish(
        keySink: CallbackLabKeySink(
          (k) => seen.add(k.name),
          (count) => finished = count,
        ),
      );

      expect(seen, ['kem-secret', 'kem-public']);
      expect(finished, 2);
    });

    test('a throwing callback aborts establishment', () {
      // The contract says an implementation that cannot store must throw
      // rather than continue and silently lose a key.
      expect(
        () => SharedSecretPqdga.labEstablish(
          keySink: CallbackLabKeySink(
            (_) => throw StateError('no custodian configured'),
            (_) {},
          ),
        ),
        throwsStateError,
      );
    });
  });
}
