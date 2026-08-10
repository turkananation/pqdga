import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/digests/cshake.dart';
import 'package:pointycastle/digests/xof_utils.dart';

/// NIST SP 800-185 KMAC256 built on PointyCastle [CSHAKEDigest].
///
/// Research/lab primitive for keyed, domain-separated expansion of
/// secret-bound PQDGA namespaces (binding ladder R9a/R9b/…).
///
/// ```
/// KMAC256(K, X, L, S) =
///   cSHAKE256(bytepad(encode_string(K), 136) || X || right_encode(L),
///             L, N="KMAC", S)
/// ```
/// where `L` is the **output length in bits**.
class Kmac256 {
  Kmac256._();

  /// Rate of cSHAKE256 / KMAC256 in bytes (1088-bit rate → 136 bytes).
  static const int rateBytes = 136;

  /// NIST function name string N = "KMAC".
  static final Uint8List functionName = Uint8List.fromList(utf8.encode('KMAC'));

  /// Compute KMAC256.
  ///
  /// * [key] — key `K` (shared secret / session key; never log).
  /// * [data] — message `X` (context: epoch, campaign, counter, …).
  /// * [outputLengthBytes] — desired MAC/XOF output length in **bytes**.
  /// * [customization] — optional customization string `S` (domain separation).
  static Uint8List mac({
    required Uint8List key,
    required Uint8List data,
    required int outputLengthBytes,
    Uint8List? customization,
  }) {
    if (outputLengthBytes < 0) {
      throw ArgumentError.value(
        outputLengthBytes,
        'outputLengthBytes',
        'must be >= 0',
      );
    }
    if (outputLengthBytes == 0) {
      return Uint8List(0);
    }

    final outBits = outputLengthBytes * 8;
    final s = customization ?? Uint8List(0);

    // newX = bytepad(encode_string(K), 136) || X || right_encode(L)
    final paddedKey = bytepad(encodeString(key), rateBytes);
    final rightL = XofUtils.rightEncode(outBits);

    final cshake = CSHAKEDigest(256, functionName, s);
    cshake.update(paddedKey, 0, paddedKey.length);
    if (data.isNotEmpty) {
      cshake.update(data, 0, data.length);
    }
    cshake.update(rightL, 0, rightL.length);

    final out = Uint8List(outputLengthBytes);
    cshake.doOutput(out, 0, outputLengthBytes);
    return out;
  }

  /// SP 800-185 `encode_string(S)` = `left_encode(len(S) in bits) || S`.
  static Uint8List encodeString(Uint8List s) {
    if (s.isEmpty) {
      return XofUtils.leftEncode(0);
    }
    final bitLen = s.length * 8;
    final le = XofUtils.leftEncode(bitLen);
    final out = Uint8List(le.length + s.length);
    out.setAll(0, le);
    out.setAll(le.length, s);
    return out;
  }

  /// SP 800-185 `bytepad(X, w)` — pad `X` to a multiple of `w` bytes.
  static Uint8List bytepad(Uint8List x, int w) {
    if (w <= 0) {
      throw ArgumentError.value(w, 'w', 'must be > 0');
    }
    final wenc = XofUtils.leftEncode(w);
    final total = wenc.length + x.length;
    final padLen = (total + w - 1) ~/ w * w;
    final out = Uint8List(padLen);
    out.setAll(0, wenc);
    out.setAll(wenc.length, x);
    return out;
  }

  /// Convenience: UTF-8 customization string.
  static Uint8List macUtf8({
    required Uint8List key,
    required Uint8List data,
    required int outputLengthBytes,
    String customization = '',
  }) {
    return mac(
      key: key,
      data: data,
      outputLengthBytes: outputLengthBytes,
      customization: customization.isEmpty
          ? null
          : Uint8List.fromList(utf8.encode(customization)),
    );
  }
}
