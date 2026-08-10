import 'dart:typed_data';

// SHAKE is implemented in pqcrypto but not re-exported from the public barrel
// in 0.3.1 — direct import is the documented R3 path (see doc/04).
// ignore: implementation_imports
import 'package:pqcrypto/src/common/shake.dart' as pqc;

/// Thin domain-expander helper over pqcrypto SHAKE XOFs.
class ShakeXof {
  const ShakeXof._();

  /// One-shot SHAKE256 expand of [input] to exactly [outputLength] bytes.
  static Uint8List shake256(Uint8List input, int outputLength) {
    if (outputLength < 0) {
      throw ArgumentError.value(outputLength, 'outputLength', 'must be >= 0');
    }
    return pqc.Shake256.shake(input, outputLength);
  }

  /// One-shot SHAKE128 expand (alternate profile).
  static Uint8List shake128(Uint8List input, int outputLength) {
    if (outputLength < 0) {
      throw ArgumentError.value(outputLength, 'outputLength', 'must be >= 0');
    }
    return pqc.Shake128.shake(input, outputLength);
  }
}
