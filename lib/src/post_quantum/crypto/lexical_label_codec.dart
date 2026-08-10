import 'dart:typed_data';

import 'package:pqdga/src/post_quantum/crypto/dns_label_codec.dart';

/// Encode XOF/KDF bytes into pronounceable or dictionary-looking DNS labels.
///
/// Used for H5 experiments: secret-bound material can still emit low-entropy-
/// looking labels so entropy-only detectors struggle. Defenders need lexical /
/// LM features (`needs_lexical_model`).
class LexicalLabelCodec {
  LexicalLabelCodec._();

  /// Default lowercase a–z alphabet for Markov emission.
  static const String alpha = 'abcdefghijklmnopqrstuvwxyz';

  /// Built-in lab wordlist (toy only — not an operational dictionary).
  static const List<String> defaultWordlist = [
    'alpha',
    'bravo',
    'charlie',
    'delta',
    'echo',
    'foxtrot',
    'golf',
    'hotel',
    'india',
    'juliet',
    'kilo',
    'lima',
    'mike',
    'november',
    'oscar',
    'papa',
    'quebec',
    'romeo',
    'sierra',
    'tango',
    'uniform',
    'victor',
    'whiskey',
    'xray',
    'yankee',
    'zulu',
    'amber',
    'birch',
    'cedar',
    'drift',
    'ember',
    'frost',
    'grove',
    'haven',
    'ivory',
    'jade',
  ];

  /// Simple CV consonant/vowel sets for pronounceable mode.
  static const String consonants = 'bcdfghjklmnpqrstvwxyz';
  static const String vowels = 'aeiou';

  /// Map entropy [stream] into a label of length in [[minLen], [maxLen]].
  ///
  /// [mode]:
  /// * `markov` — bigram-ish walk over [alpha]
  /// * `dictionary` — concatenate words from [wordlist]
  /// * `pronounceable` — alternating C/V
  /// * `charset` — fallback to [DnsLabelCodec.mapBytesToCharset]
  static (String label, int length) encode({
    required Uint8List stream,
    required int minLen,
    required int maxLen,
    required String mode,
    String charset = alpha,
    List<String> wordlist = defaultWordlist,
    List<String> tlds = const ['.com'],
  }) {
    if (stream.length < 4) {
      throw ArgumentError('stream too short for lexical encode');
    }
    final span = maxLen - minLen + 1;
    if (span < 1) {
      throw ArgumentError('maxLen must be >= minLen');
    }
    final target = minLen + (stream[0] % span);
    final m = mode.toLowerCase();
    late final String label;
    switch (m) {
      case 'markov':
        label = _markov(stream, target, charset);
        break;
      case 'dictionary':
        label = _dictionary(stream, target, wordlist);
        break;
      case 'pronounceable':
        label = _pronounceable(stream, target);
        break;
      case 'charset':
        if (stream.length < 1 + target) {
          throw ArgumentError('need ${1 + target} bytes for charset mode');
        }
        label = DnsLabelCodec.mapBytesToCharset(
          Uint8List.sublistView(stream, 1, 1 + target),
          charset,
          target,
        );
        break;
      default:
        throw ArgumentError(
          'unsupported lexical mode "$mode"; '
          'use markov, dictionary, pronounceable, or charset',
        );
    }
    final check = DnsLabelCodec.validateLabel(label);
    if (check.isFailure) {
      throw StateError(
        'lexical label invalid "$label": ${check.errorOrNull}',
      );
    }
    return (check.valueOrNull!, label.length);
  }

  /// Full FQDN: lexical label + TLD chosen from stream tail.
  static (String fqdn, int labelLength) encodeFqdn({
    required Uint8List stream,
    required int minLen,
    required int maxLen,
    required String mode,
    required List<String> tlds,
    String charset = alpha,
    List<String> wordlist = defaultWordlist,
  }) {
    if (tlds.isEmpty) {
      throw ArgumentError('tlds must be non-empty');
    }
    final pair = encode(
      stream: stream,
      minLen: minLen,
      maxLen: maxLen,
      mode: mode,
      charset: charset,
      wordlist: wordlist,
      tlds: tlds,
    );
    // Use a late stream byte for TLD selection when available.
    final tldIdx = stream.length > 2
        ? stream[stream.length - 1] % tlds.length
        : 0;
    final tld = DnsLabelCodec.normalizeTld(tlds[tldIdx]);
    final fqdn = '${pair.$1}$tld';
    final fqdnCheck = DnsLabelCodec.validateFqdn(fqdn);
    if (fqdnCheck.isFailure) {
      throw StateError(
        'lexical FQDN invalid "$fqdn": ${fqdnCheck.errorOrNull}',
      );
    }
    return (fqdnCheck.valueOrNull!, pair.$2);
  }

  static String _markov(Uint8List stream, int target, String charset) {
    if (charset.isEmpty) {
      throw ArgumentError('charset must be non-empty');
    }
    final buf = StringBuffer();
    var state = stream[1] % charset.length;
    buf.write(charset[state]);
    var i = 2;
    while (buf.length < target) {
      final b = stream[i % stream.length];
      // Prefer nearby letters for English-ish bigrams (lab heuristic).
      final delta = (b % 7) - 3;
      state = (state + delta + charset.length) % charset.length;
      // Occasional jump keeps labels from collapsing.
      if (b & 0x80 != 0) {
        state = b % charset.length;
      }
      buf.write(charset[state]);
      i++;
    }
    return buf.toString();
  }

  static String _dictionary(
    Uint8List stream,
    int target,
    List<String> wordlist,
  ) {
    if (wordlist.isEmpty) {
      throw ArgumentError('wordlist must be non-empty');
    }
    final cleaned = wordlist
        .map((w) => w.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''))
        .where((w) => w.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) {
      throw ArgumentError('wordlist has no usable LDH words');
    }
    final buf = StringBuffer();
    var i = 1;
    while (buf.length < target) {
      final w = cleaned[stream[i % stream.length] % cleaned.length];
      if (buf.isEmpty) {
        buf.write(w);
      } else if (buf.length + w.length <= target) {
        buf.write(w);
      } else {
        final need = target - buf.length;
        buf.write(w.substring(0, need.clamp(0, w.length)));
      }
      i++;
      if (i > stream.length * 8 + cleaned.length) break;
    }
    var out = buf.toString();
    if (out.length > target) out = out.substring(0, target);
    while (out.length < target) {
      out = '$out${cleaned[out.length % cleaned.length][0]}';
    }
    return out;
  }

  static String _pronounceable(Uint8List stream, int target) {
    final buf = StringBuffer();
    var useConsonant = (stream[1] & 1) == 0;
    var i = 2;
    while (buf.length < target) {
      final set = useConsonant ? consonants : vowels;
      buf.write(set[stream[i % stream.length] % set.length]);
      useConsonant = !useConsonant;
      i++;
    }
    return buf.toString();
  }
}
