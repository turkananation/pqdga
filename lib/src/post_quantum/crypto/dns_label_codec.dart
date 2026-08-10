import 'dart:typed_data';

import 'package:swissarmyknife/swissarmyknife.dart';

/// DNS-safe label mapping from XOF bytes + light validation.
///
/// Crypto stays in pqcrypto; this module is research plumbing only.
class DnsLabelCodec {
  /// Default LDH-ish lowercase alphanumeric charset (no hyphen leading/trailing rules).
  static const String defaultCharset =
      'abcdefghijklmnopqrstuvwxyz0123456789';

  /// Map [bytes] into [charset] for exactly [length] characters (rejection-free mod).
  static String mapBytesToCharset(
    Uint8List bytes,
    String charset,
    int length,
  ) {
    if (charset.isEmpty) {
      throw ArgumentError('charset must be non-empty');
    }
    if (length <= 0) {
      throw ArgumentError.value(length, 'length', 'must be > 0');
    }
    if (bytes.length < length) {
      throw ArgumentError(
        'need at least $length entropy bytes, got ${bytes.length}',
      );
    }
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(charset[bytes[i] % charset.length]);
    }
    return buffer.toString();
  }

  /// RFC-style single label checks: 1–63 chars, LDH, no leading/trailing hyphen.
  static Result<String, List<String>> validateLabel(String label) {
    final errors = <String>[];
    if (label.isEmpty) {
      errors.add('label empty');
    }
    if (label.length > 63) {
      errors.add('label length ${label.length} > 63');
    }
    if (label.startsWith('-') || label.endsWith('-')) {
      errors.add('label must not start or end with hyphen');
    }
    final ok = RegExp(r'^[a-z0-9-]+$').hasMatch(label);
    if (!ok) {
      errors.add('label has characters outside [a-z0-9-]');
    }
    if (errors.isEmpty) {
      return Result.success(label);
    }
    return Result.failure(errors);
  }

  /// FQDN length ≤ 253 (excluding trailing root dot).
  static Result<String, List<String>> validateFqdn(String fqdn) {
    final errors = <String>[];
    final cleaned = fqdn.endsWith('.') ? fqdn.substring(0, fqdn.length - 1) : fqdn;
    if (cleaned.length > 253) {
      errors.add('fqdn length ${cleaned.length} > 253');
    }
    final labels = cleaned.split('.');
    if (labels.length < 2) {
      errors.add('fqdn needs at least one label + TLD');
    }
    for (final label in labels) {
      final r = validateLabel(label);
      r.fold((_) {}, errors.addAll);
    }
    if (errors.isEmpty) {
      return Result.success(cleaned);
    }
    return Result.failure(errors);
  }

  /// Ensure TLD string starts with `.` for concatenation after a label.
  static String normalizeTld(String tld) {
    if (tld.isEmpty) return '.com';
    return tld.startsWith('.') ? tld : '.$tld';
  }
}
