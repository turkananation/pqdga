import 'dart:math' as math;

import 'package:pqdga/src/classical/dga_result.dart';
import 'package:pqdga/src/common/predictability.dart';
import 'package:pqdga/src/post_quantum/pqdga_result.dart';

/// Per-domain lexical / structural features for SOC notebooks and detectors.
///
/// Pure functions — no I/O. Designed for lab training sets, not production IDS.
class DomainFeatures {
  /// Original input string (FQDN or abstract id).
  final String domain;

  /// FQDN length (no trailing root dot).
  final int fqdnLength;

  /// Left-most label length (or full string if no dots).
  final int labelLength;

  /// Shannon entropy of the full domain string (bits/char).
  final double entropy;

  /// Fraction of hex digits `[0-9a-f]` in the left-most label.
  final double hexRatio;

  /// Fraction of decimal digits in the left-most label.
  final double digitRatio;

  /// Count of vowel↔consonant transitions in the left-most label.
  final int vowelConsonantTransitions;

  /// Public suffix-ish last label (TLD), lowercased; empty if none.
  final String tld;

  /// Number of labels separated by `.` (1 for abstract single-token ids).
  final int subdomainDepth;

  /// `true` if any label starts with `xn--` (punycode/IDN).
  final bool idn;

  /// Coarse charset class of the left-most label.
  final String charsetClass;

  const DomainFeatures({
    required this.domain,
    required this.fqdnLength,
    required this.labelLength,
    required this.entropy,
    required this.hexRatio,
    required this.digitRatio,
    required this.vowelConsonantTransitions,
    required this.tld,
    required this.subdomainDepth,
    required this.idn,
    required this.charsetClass,
  });

  Map<String, dynamic> toJson() => {
    'domain': domain,
    'fqdn_length': fqdnLength,
    'label_length': labelLength,
    'entropy': entropy,
    'hex_ratio': hexRatio,
    'digit_ratio': digitRatio,
    'vowel_consonant_transitions': vowelConsonantTransitions,
    'tld': tld,
    'subdomain_depth': subdomainDepth,
    'idn': idn,
    'charset_class': charsetClass,
  };
}

/// Batch / campaign-level features over a domain list.
class BatchFeatures {
  /// Number of domains in the batch.
  final int domainCount;

  /// Distinct TLDs observed.
  final int tldDiversity;

  /// Histogram of left-most label lengths.
  final Map<int, int> lengthHistogram;

  /// Mean Shannon entropy across domains.
  final double meanEntropy;

  /// Mean digit ratio across left-most labels.
  final double meanDigitRatio;

  /// Fraction of IDN/punycode names.
  final double idnRatio;

  /// Optional hook: expected NXDOMAIN ratio for pre-registration noise labs.
  final double? expectedNxdomainRatio;

  /// Playbook / predictability summary if provided by caller.
  final String? predictability;

  /// `true` if offline precompute is viable (when known).
  final bool? predictable;

  /// `true` if secret material is required (when known).
  final bool? secretBound;

  const BatchFeatures({
    required this.domainCount,
    required this.tldDiversity,
    required this.lengthHistogram,
    required this.meanEntropy,
    required this.meanDigitRatio,
    required this.idnRatio,
    this.expectedNxdomainRatio,
    this.predictability,
    this.predictable,
    this.secretBound,
  });

  Map<String, dynamic> toJson() => {
    'domain_count': domainCount,
    'tld_diversity': tldDiversity,
    'length_histogram': {
      for (final e in lengthHistogram.entries) '${e.key}': e.value,
    },
    'mean_entropy': meanEntropy,
    'mean_digit_ratio': meanDigitRatio,
    'idn_ratio': idnRatio,
    if (expectedNxdomainRatio != null)
      'expected_nxdomain_ratio': expectedNxdomainRatio,
    if (predictability != null) 'predictability': predictability,
    if (predictable != null) 'predictable': predictable,
    if (secretBound != null) 'secret_bound': secretBound,
  };
}

/// SOC feature extraction helpers (R7).
class SocFeatures {
  SocFeatures._();

  static const _vowels = {'a', 'e', 'i', 'o', 'u'};

  /// Extract features for a single domain or abstract id.
  static DomainFeatures forDomain(String domain) {
    final cleaned = domain.endsWith('.')
        ? domain.substring(0, domain.length - 1)
        : domain;
    final labels = cleaned.split('.');
    final label = labels.isNotEmpty ? labels.first : cleaned;
    final tld = labels.length >= 2 ? labels.last.toLowerCase() : '';
    final idn = labels.any((l) => l.toLowerCase().startsWith('xn--'));

    return DomainFeatures(
      domain: cleaned,
      fqdnLength: cleaned.length,
      labelLength: label.length,
      entropy: _shannon(cleaned),
      hexRatio: _ratio(label, _isHex),
      digitRatio: _ratio(label, _isDigit),
      vowelConsonantTransitions: _vcTransitions(label),
      tld: tld,
      subdomainDepth: labels.length,
      idn: idn,
      charsetClass: _charsetClass(label),
    );
  }

  /// Per-domain features for every name in [domains].
  static List<DomainFeatures> forDomains(Iterable<String> domains) =>
      domains.map(forDomain).toList(growable: false);

  /// Batch features from a raw domain list.
  static BatchFeatures forBatch(
    Iterable<String> domains, {
    double? expectedNxdomainRatio,
    String? predictability,
    bool? predictable,
    bool? secretBound,
  }) {
    final list = domains.toList(growable: false);
    if (list.isEmpty) {
      return BatchFeatures(
        domainCount: 0,
        tldDiversity: 0,
        lengthHistogram: const {},
        meanEntropy: 0,
        meanDigitRatio: 0,
        idnRatio: 0,
        expectedNxdomainRatio: expectedNxdomainRatio,
        predictability: predictability,
        predictable: predictable,
        secretBound: secretBound,
      );
    }
    final feats = forDomains(list);
    final tlds = <String>{};
    final hist = <int, int>{};
    var entSum = 0.0;
    var digSum = 0.0;
    var idnCount = 0;
    for (final f in feats) {
      if (f.tld.isNotEmpty) tlds.add(f.tld);
      hist[f.labelLength] = (hist[f.labelLength] ?? 0) + 1;
      entSum += f.entropy;
      digSum += f.digitRatio;
      if (f.idn) idnCount++;
    }
    final n = feats.length;
    return BatchFeatures(
      domainCount: n,
      tldDiversity: tlds.length,
      lengthHistogram: Map.unmodifiable(hist),
      meanEntropy: entSum / n,
      meanDigitRatio: digSum / n,
      idnRatio: idnCount / n,
      expectedNxdomainRatio: expectedNxdomainRatio,
      predictability: predictability,
      predictable: predictable,
      secretBound: secretBound,
    );
  }

  /// Batch features from a classical [DGAResult], pulling predictability metadata.
  static BatchFeatures fromDgaResult(
    DGAResult result, {
    double? expectedNxdomainRatio,
  }) {
    final meta = result.metadata;
    return forBatch(
      result.domains,
      expectedNxdomainRatio: expectedNxdomainRatio,
      predictability: meta['predictability']?.toString(),
      predictable: meta['predictable'] as bool?,
      secretBound:
          meta['secret_bound'] as bool? ?? meta['secretBound'] as bool?,
    );
  }

  /// Batch features from a [PQDGAResult] (includes predictable/secretBound).
  static BatchFeatures fromPqdgaResult(
    PQDGAResult result, {
    double? expectedNxdomainRatio,
  }) {
    final metaPred = result.metadata['predictability']?.toString();
    return forBatch(
      result.domains,
      expectedNxdomainRatio: expectedNxdomainRatio,
      predictability:
          metaPred ??
          (result.secretBound
              ? PredictabilityClass.secretSeeded.wireName
              : result.predictable
              ? PredictabilityClass.trivial.wireName
              : null),
      predictable: result.predictable,
      secretBound: result.secretBound,
    );
  }

  /// Compact IOC-oriented summary for examples / notebooks (PQ path).
  static Map<String, dynamic> iocTemplateFromPqdga(PQDGAResult result) {
    final fromMeta = result.metadata['ioc_template'];
    final meta = result.metadata;
    final Map<String, dynamic> ioc;
    if (fromMeta is Map<String, dynamic>) {
      ioc = Map<String, dynamic>.from(fromMeta);
    } else if (fromMeta is Map) {
      ioc = fromMeta.map((k, v) => MapEntry(k.toString(), v));
    } else {
      ioc = {
        'algorithm': result.algorithm,
        'xof': result.xof,
        'epoch': result.epoch,
        if (result.kemAlgorithm != null) 'kem_algorithm': result.kemAlgorithm,
        if (result.kemCiphertextLength != null)
          'kem_ciphertext_length': result.kemCiphertextLength,
        if (result.sigAlgorithm != null) 'sig_algorithm': result.sigAlgorithm,
        if (result.signatureLength != null)
          'signature_length': result.signatureLength,
        if (result.pubkeyFingerprint != null)
          'pubkey_fingerprint': result.pubkeyFingerprint,
        if (meta['predictability'] != null)
          'predictability': meta['predictability'],
        if (meta['charset'] != null) 'charset': meta['charset'],
        if (meta['binding_ladder'] != null)
          'binding_ladder': meta['binding_ladder'],
        if (meta['binding_mode'] != null) 'binding_mode': meta['binding_mode'],
        if (meta['playbook_flags'] is Map)
          'playbook_flags': Map<String, dynamic>.from(
            (meta['playbook_flags'] as Map).map(
              (k, v) => MapEntry(k.toString(), v),
            ),
          ),
        if (meta['campaign_id'] != null) 'campaign_id': meta['campaign_id'],
      };
    }
    // Always surface result-level flags even when family ioc_template is sparse.
    ioc.putIfAbsent('algorithm', () => result.algorithm);
    ioc.putIfAbsent('predictable', () => result.predictable);
    ioc.putIfAbsent('secret_bound', () => result.secretBound);
    final epoch = result.epoch;
    if (epoch != null) ioc.putIfAbsent('epoch', () => epoch);
    ioc.putIfAbsent('xof', () => result.xof);
    return ioc;
  }

  /// Compact IOC-oriented summary for classical [DGAResult] notebooks.
  static Map<String, dynamic> iocTemplateFromDga(DGAResult result) {
    final fromMeta = result.metadata['ioc_template'];
    if (fromMeta is Map<String, dynamic>) {
      return Map<String, dynamic>.from(fromMeta);
    }
    if (fromMeta is Map) {
      return fromMeta.map((k, v) => MapEntry(k.toString(), v));
    }
    final meta = result.metadata;
    return {
      'algorithm': result.algorithm,
      'seed': result.seed,
      'generation_date': result.generationDate.toUtc().toIso8601String(),
      'domain_count': result.domains.length,
      if (meta['predictability'] != null)
        'predictability': meta['predictability'],
      if (meta['predictable'] != null) 'predictable': meta['predictable'],
      if (meta['secret_bound'] != null) 'secret_bound': meta['secret_bound'],
      if (meta['charset'] != null) 'charset': meta['charset'],
      if (meta['length_min'] != null) 'length_min': meta['length_min'],
      if (meta['length_max'] != null) 'length_max': meta['length_max'],
      if (meta['tld_set'] != null) 'tld_set': meta['tld_set'],
      if (meta['prng'] != null) 'prng': meta['prng'],
      if (meta['seed_packing'] != null) 'seed_packing': meta['seed_packing'],
      if (meta['domains_per_day'] != null)
        'domains_per_day': meta['domains_per_day'],
      if (meta['config_seed'] != null) 'config_seed': meta['config_seed'],
      if (meta['wordlist_id'] != null) 'wordlist_id': meta['wordlist_id'],
      if (meta['playbook_flags'] is Map)
        'playbook_flags': Map<String, dynamic>.from(
          (meta['playbook_flags'] as Map).map(
            (k, v) => MapEntry(k.toString(), v),
          ),
        ),
      if (meta['campaign_id'] != null) 'campaign_id': meta['campaign_id'],
      if (meta['oracle_id'] != null) 'oracle_id': meta['oracle_id'],
    };
  }

  static double _shannon(String s) {
    if (s.isEmpty) return 0;
    final counts = <int, int>{};
    for (final cu in s.codeUnits) {
      counts[cu] = (counts[cu] ?? 0) + 1;
    }
    final n = s.length.toDouble();
    var h = 0.0;
    for (final c in counts.values) {
      final p = c / n;
      h -= p * (math.log(p) / math.ln2);
    }
    return h;
  }

  static double _ratio(String s, bool Function(int cu) pred) {
    if (s.isEmpty) return 0;
    var hit = 0;
    for (final cu in s.codeUnits) {
      if (pred(cu)) hit++;
    }
    return hit / s.length;
  }

  static bool _isHex(int cu) {
    final c = String.fromCharCode(cu).toLowerCase();
    return (c.compareTo('0') >= 0 && c.compareTo('9') <= 0) ||
        (c.compareTo('a') >= 0 && c.compareTo('f') <= 0);
  }

  static bool _isDigit(int cu) => cu >= 0x30 && cu <= 0x39;

  static int _vcTransitions(String label) {
    final chars = label.toLowerCase().split('');
    var prevIsVowel = false;
    var have = false;
    var transitions = 0;
    for (final ch in chars) {
      if (!RegExp(r'[a-z]').hasMatch(ch)) {
        have = false;
        continue;
      }
      final isV = _vowels.contains(ch);
      if (have && isV != prevIsVowel) transitions++;
      prevIsVowel = isV;
      have = true;
    }
    return transitions;
  }

  static String _charsetClass(String label) {
    if (label.isEmpty) return 'empty';
    var hasAlpha = false;
    var hasDigit = false;
    var hasOther = false;
    var allHex = true;
    for (final cu in label.codeUnits) {
      final ch = String.fromCharCode(cu).toLowerCase();
      final isA = RegExp(r'[a-z]').hasMatch(ch);
      final isD = RegExp(r'[0-9]').hasMatch(ch);
      if (isA) hasAlpha = true;
      if (isD) hasDigit = true;
      if (!isA && !isD && ch != '-') hasOther = true;
      if (!_isHex(cu) && ch != '-') allHex = false;
    }
    if (hasOther) return 'mixed';
    if (allHex && (hasDigit || hasAlpha) && !RegExp(r'[g-z]').hasMatch(label)) {
      return 'hex';
    }
    if (hasAlpha && hasDigit) return 'alnum';
    if (hasAlpha) return 'alpha';
    if (hasDigit) return 'digit';
    return 'other';
  }
}
