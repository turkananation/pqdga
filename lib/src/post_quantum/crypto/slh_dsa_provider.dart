import 'dart:typed_data';

// pqforge deliberately does NOT re-export pqcrypto's lattice primitives
// (see the note in pqforge's barrel doc), so import pqcrypto directly.
import 'package:pqcrypto/pqcrypto.dart';

/// Primitive preference: **pqforge → pqcrypto → other**.
///
/// pqforge 0.3.x does **not** expose SLH-DSA. When it does, route through
/// pqforge and drop the `pqcrypto` dependency_override if versions align.
class SlhDsaProvider {
  SlhDsaProvider._();

  /// True when pqforge public API exports SLH-DSA (currently always false).
  static bool get pqforgeExposesSlhDsa => false;

  /// Active backend id for metadata / notebooks.
  static String get backendId =>
      pqforgeExposesSlhDsa ? 'pqforge.SlhDsa' : 'pqcrypto.SlhDsa';

  /// Crypto status string for IOC catalogs.
  static String get cryptoStatus =>
      pqforgeExposesSlhDsa ? 'fips-205-pqforge' : 'fips-205-pqcrypto';

  /// Keygen via preferred backend (today: pqcrypto).
  static (Uint8List, Uint8List) generateKeyPair(SlhDsaParams params) {
    // Prefer pqforge when available — gated until upstream ships SLH-DSA.
    return SlhDsa.generateKeyPair(params);
  }

  static Uint8List sign(
    Uint8List secretKey,
    Uint8List message,
    SlhDsaParams params, {
    Uint8List? context,
    bool allowSlowSigning = false,
  }) {
    return SlhDsa.sign(
      secretKey,
      message,
      params,
      context: context ?? Uint8List(0),
      allowSlowSigning: allowSlowSigning,
    );
  }

  static bool verify(
    Uint8List publicKey,
    Uint8List message,
    Uint8List signature,
    SlhDsaParams params, {
    Uint8List? context,
  }) {
    return SlhDsa.verify(
      publicKey,
      message,
      signature,
      params,
      context: context ?? Uint8List(0),
    );
  }
}
