import 'dart:convert';
import 'dart:typed_data';

import 'package:swissarmyknife/swissarmyknife.dart';
import 'package:pqdga/src/classical/dga_result.dart';
import 'package:pqdga/src/common/hardness_scorecard.dart';
import 'package:pqdga/src/common/soc_features.dart';
import 'package:pqdga/src/post_quantum/crypto/epoch_bucket.dart';
import 'package:pqdga/src/post_quantum/pqdga_result.dart';

/// Deeper `swissarmyknife` lab harness for notebooks and detector drills.
///
/// Surfaces cron-style epoch buckets, [CodecPipeline] bulk encoding, [Memoized]
/// feature extraction, [RateLimiter], [DateRange], structured [Log] capture,
/// and [SafeJson] walks — research plumbing only (no crypto secrets in logs).
class LabHarness {
  LabHarness._();

  static const _tag = 'pqdga.lab';

  /// In-memory structured log sink for notebook assertions (cleared on demand).
  static final List<Map<String, dynamic>> logCapture = [];

  static bool _captureEnabled = false;
  static bool _logHookInstalled = false;
  static LogOutput? _previousOutput;

  /// Enable capturing [Log] lines into [logCapture] (idempotent).
  static void enableLogCapture({bool clear = true}) {
    if (clear) logCapture.clear();
    _captureEnabled = true;
    if (!_logHookInstalled) {
      _logHookInstalled = true;
      _previousOutput = Log.currentConfig.output;
      Log.config(
        minLevel: Log.currentConfig.minLevel,
        showTimestamp: Log.currentConfig.showTimestamp,
        useColors: Log.currentConfig.useColors,
        enabledTags: Log.currentConfig.enabledTags,
        output: (line) {
          if (_captureEnabled) {
            logCapture.add({
              'line': line,
              'ts': DateTime.now().toUtc().toIso8601String(),
            });
          }
          final prev = _previousOutput;
          if (prev != null) {
            prev(line);
          } else {
            // Default sink when none configured.
            // ignore: avoid_print
            print(line);
          }
        },
      );
    }
  }

  /// Stop appending to [logCapture] (hook remains installed).
  static void disableLogCapture() => _captureEnabled = false;

  /// Cron-like bucket id for a wall clock (delegates to [EpochBucket]).
  static String cronEpochBucket(
    DateTime date, {
    int rotationDays = 1,
  }) =>
      EpochBucket.idFor(date, rotationDays);

  /// Date-range coverage of epoch buckets between [start] and [end] inclusive.
  static List<String> epochBucketsInRange(
    DateTime start,
    DateTime end, {
    int rotationDays = 1,
  }) {
    if (end.isBefore(start)) {
      throw ArgumentError('end must be >= start');
    }
    final days = rotationDays < 1 ? 1 : rotationDays;
    final out = <String>[];
    var cursor = DateTime.utc(start.year, start.month, start.day);
    final last = DateTime.utc(end.year, end.month, end.day);
    final seen = <String>{};
    while (!cursor.isAfter(last)) {
      final id = EpochBucket.idFor(cursor, days);
      if (seen.add(id)) out.add(id);
      cursor = cursor.add(Duration(days: days));
    }
    return out;
  }

  /// swissarmyknife [DateRange] inclusive day count for notebook schedule cells.
  static int dateRangeDayCount(DateTime start, DateTime end) {
    final range = DateRange(
      DateTime.utc(start.year, start.month, start.day),
      DateTime.utc(end.year, end.month, end.day),
    );
    return range.days;
  }

  /// Parse a five-field cron and list matching instants in [start]..[end].
  ///
  /// Example: `0 0 */3 * *` → every 3rd day-of-month at 00:00 UTC
  /// (minute hour dom mon dow).
  static List<DateTime> cronMatchesInRange(
    String cronExpression,
    DateTime start,
    DateTime end, {
    int maxMatches = 366,
  }) {
    final expr = CronExpression.parse(cronExpression);
    final out = <DateTime>[];
    var cursor = DateTime.utc(start.year, start.month, start.day);
    final last = DateTime.utc(end.year, end.month, end.day, 23, 59);
    while (!cursor.isAfter(last) && out.length < maxMatches) {
      if (expr.matches(cursor)) {
        out.add(cursor);
        // Advance to next day after a match at midnight-style schedules.
        cursor = DateTime.utc(cursor.year, cursor.month, cursor.day)
            .add(const Duration(days: 1));
      } else {
        cursor = cursor.add(const Duration(minutes: 1));
      }
    }
    return out;
  }

  /// Bulk-encode domain labels through a multi-stage [CodecPipeline].
  static List<Map<String, dynamic>> codecPipelineBulk(List<String> domains) {
    final pipeline = CodecPipeline<String, String>(
      (d) => d.trim().toLowerCase(),
      name: 'lower_trim',
    )
        .then<Map<String, dynamic>>(
          (d) => <String, dynamic>{
            'domain': d,
            'utf8_len': utf8.encode(d).length,
            'label': d.contains('.') ? d.split('.').first : d,
            'tld': d.contains('.') ? d.substring(d.indexOf('.')) : '',
          },
          name: 'split_map',
        )
        .then<Map<String, dynamic>>(
          (m) {
            final label = m['label'] as String;
            final feats = SocFeatures.forDomain(m['domain'] as String);
            return {
              ...m,
              'entropy': feats.entropy,
              'hex_ratio': feats.hexRatio,
              'label_len': label.length,
              'vowel_consonant_transitions': feats.vowelConsonantTransitions,
              'digit_ratio': feats.digitRatio,
            };
          },
          name: 'soc_features',
        );
    return [for (final d in domains) pipeline.convert(d)];
  }

  /// JSON-safe bulk export via [SafeJson] (missing keys → defaults).
  static List<Map<String, dynamic>> safeJsonDomainRows(
    List<Map<String, dynamic>> pipelineRows,
  ) {
    return [
      for (final row in pipelineRows)
        {
          'domain': SafeJson(row).at('domain').asStringOr(''),
          'entropy': SafeJson(row).at('entropy').asDoubleOr(0.0),
          'hex_ratio': SafeJson(row).at('hex_ratio').asDoubleOr(0.0),
          'label_len': SafeJson(row).at('label_len').asIntOr(0),
          'tld': SafeJson(row).at('tld').asStringOr(''),
        },
    ];
  }

  /// Memoized Shannon entropy of a domain (avoids recompute in notebooks).
  static final Memoized<String, double> _entropyMemo = memoize<String, double>(
    (domain) => SocFeatures.forDomain(domain).entropy,
  );

  static double memoizedEntropy(String domain) => _entropyMemo(domain);

  /// Structured one-line log for a classical result (no secrets).
  static void logDgaResult(DGAResult result, {String level = 'info'}) {
    final hard = HardnessScorecard.fromDgaResult(result);
    final line = jsonEncode({
      'type': 'dga',
      'algorithm': result.algorithm,
      'count': result.domains.length,
      'predictability': result.metadata['predictability'],
      'fidelity': result.metadata['fidelity'],
      'literature': result.metadata['literature'],
      'hardness': hard.scores,
      'counters': hard.counters,
    });
    _emit(level, line);
  }

  /// Structured one-line log for a PQ result (never includes keys/ss).
  static void logPqdgaResult(PQDGAResult result, {String level = 'info'}) {
    final hard = HardnessScorecard.fromPqdgaResult(result);
    final line = jsonEncode({
      'type': 'pqdga',
      'algorithm': result.algorithm,
      'count': result.domains.length,
      'predictable': result.predictable,
      'secret_bound': result.secretBound,
      'epoch': result.epoch,
      'xof': result.xof,
      'binding_ladder': result.metadata['binding_ladder'],
      'binding_mode': result.metadata['binding_mode'],
      'hardness': hard.scores,
      'counters': hard.counters,
    });
    _emit(level, line);
  }

  /// Structured notebook event (analysis cell complete, detector hit, …).
  static void logEvent(
    String event, {
    Map<String, dynamic>? fields,
    String level = 'info',
  }) {
    final line = jsonEncode({
      'type': 'event',
      'event': event,
      ...?fields,
    });
    _emit(level, line);
  }

  /// Sliding-window rate limiter (lab emit caps).
  static RateLimiter rateLimiter({
    int maxPerWindow = 10,
    Duration window = const Duration(hours: 1),
  }) =>
      RateLimiter.slidingWindow(maxPerWindow, window);

  static void _emit(String level, String line) {
    switch (level) {
      case 'warn':
      case 'warning':
        Log.w(line, tag: _tag);
        break;
      case 'error':
        Log.e(line, tag: _tag);
        break;
      default:
        Log.i(line, tag: _tag);
    }
  }

  /// Pack arbitrary lab bytes as hex for notebook cells (not secrets).
  static String toHex(Uint8List bytes, {int maxBytes = 32}) {
    final n = bytes.length < maxBytes ? bytes.length : maxBytes;
    final hex = bytes
        .sublist(0, n)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return bytes.length > maxBytes
        ? '$hex…(+${bytes.length - maxBytes}B)'
        : hex;
  }
}
