/// Secret-buffer wipe evidence for the lab sessions.
///
/// The defect: `SharedSecretLabSession` and `IdentityBasedLabSession` hold live
/// private key material in plain public `Uint8List` fields, document them as
/// "do not log", and offer no way to clear them. Two other sites used
/// `fillRange(0, n, 0)` to wipe, which is exactly the loop that
/// `pqkeystore`'s AGENTS rule 10 rejects: it carries no
/// `@pragma('vm:never-inline')` and no opaque read anchor, so Dead Store
/// Elimination can remove the writes in an AOT build.
library;

import 'dart:typed_data';

import 'package:pqdga/pqdga.dart';
import 'package:test/test.dart';

void main() {
  group('SharedSecretLabSession — dispose wipes the secrets', () {
    late SharedSecretLabSession session;

    setUp(() {
      session = SharedSecretPqdga.labEstablish(
        campaignId: 'wipe-evidence',
        tld: const ['.example'],
      );
    });

    test('the secrets are populated before disposal', () {
      expect(session.kemSecretKey.isNotEmpty, isTrue);
      expect(session.sharedSecret.isNotEmpty, isTrue);
      expect(session.kemSecretKey.any((b) => b != 0), isTrue);
      expect(session.sharedSecret.any((b) => b != 0), isTrue);
    });

    test('dispose zeroes kemSecretKey and sharedSecret in place', () {
      session.dispose();

      expect(
        session.kemSecretKey.every((b) => b == 0),
        isTrue,
        reason: 'kemSecretKey must be wiped in the caller\'s buffer',
      );
      expect(
        session.sharedSecret.every((b) => b == 0),
        isTrue,
        reason: 'sharedSecret must be wiped in the caller\'s buffer',
      );
    });

    test('public artifacts are deliberately NOT wiped', () {
      final publicKey = Uint8List.fromList(session.kemPublicKey);
      final ciphertext = Uint8List.fromList(session.kemCiphertext);

      session.dispose();

      expect(session.kemPublicKey, publicKey);
      expect(
        session.kemCiphertext,
        ciphertext,
        reason: 'public key and ciphertext are public artifacts',
      );
    });

    test('dispose is idempotent', () {
      session.dispose();
      expect(session.dispose, returnsNormally);
      expect(session.dispose, returnsNormally);
    });

    test('the wipe writes to the caller-held buffer, not a copy', () {
      // Capture the exact instance handed out by the session, wipe, and assert
      // on that instance — the same discipline a rule-10 regression uses.
      // NB: a real ML-KEM secret key legitimately contains zero bytes, so
      // "populated" means *not all zero*, not "every byte non-zero".
      final captured = session.kemSecretKey;
      expect(captured.any((b) => b != 0), isTrue);

      session.dispose();

      expect(identical(captured, session.kemSecretKey), isTrue);
      expect(captured.every((b) => b == 0), isTrue);
    });
  });

  group('IdentityBasedLabSession — dispose wipes the signing key', () {
    late IdentityBasedLabSession session;

    setUp(() {
      session = IdentityBasedPqdga.labEstablish(
        campaignId: 'wipe-evidence',
        tld: const ['.example'],
        requireSignature: true,
      );
    });

    test('dispose zeroes signatureSecretKey', () {
      // An ML-DSA secret key legitimately contains zero bytes; populated means
      // *not all zero*.
      expect(session.signatureSecretKey.any((b) => b != 0), isTrue);

      session.dispose();

      expect(session.signatureSecretKey.every((b) => b == 0), isTrue);
    });

    test('the identity public key is preserved', () {
      final before = Uint8List.fromList(session.identityPublicKey);

      session.dispose();

      expect(session.identityPublicKey, before);
    });

    test('dispose is idempotent', () {
      session.dispose();
      expect(session.dispose, returnsNormally);
    });
  });
}
