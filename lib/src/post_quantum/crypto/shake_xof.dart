import 'dart:typed_data';

// pqforge exposes its own algorithm vocabulary (PqKemAlgorithm, PqSlhDsaAlgorithm,
// PqKemPrimitives, PqSignaturePrimitives) but does not re-export pqcrypto's
// implementation types. Shake128/Shake256 are pqcrypto's, and are exported
// from its barrel.
import 'package:pqcrypto/pqcrypto.dart' show Shake128, Shake256;

// SHAKE is implemented in pqcrypto but not re-exported from the public barrel
// in 0.3.1 — direct import is the documented R3 path (see doc/04).
// ignore: implementation_imports

/// Thin domain-expander helper over pqcrypto SHAKE XOFs.
class ShakeXof {
  const ShakeXof._();

  /// One-shot SHAKE256 expand of [input] to exactly [outputLength] bytes.
  static Uint8List shake256(Uint8List input, int outputLength) {
    if (outputLength < 0) {
      throw ArgumentError.value(outputLength, 'outputLength', 'must be >= 0');
    }
    return Shake256.shake(input, outputLength);
  }

  /// One-shot SHAKE128 expand (alternate profile).
  static Uint8List shake128(Uint8List input, int outputLength) {
    if (outputLength < 0) {
      throw ArgumentError.value(outputLength, 'outputLength', 'must be >= 0');
    }
    return Shake128.shake(input, outputLength);
  }
}
