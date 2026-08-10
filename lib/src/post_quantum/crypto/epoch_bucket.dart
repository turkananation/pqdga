import 'package:swissarmyknife/swissarmyknife.dart';

/// Epoch / rotation bucket helpers for PQ seed material (research plumbing).
class EpochBucket {
  /// Floor [date] (UTC) to a bucket of [rotationDays] starting at Unix epoch days.
  ///
  /// Example: rotationDays=1 → calendar day UTC; rotationDays=7 → week-aligned
  /// buckets from 1970-01-01.
  static DateTime bucketStart(DateTime date, int rotationDays) {
    final days = rotationDays <= 0 ? 1 : rotationDays;
    final utc = date.toUtc();
    final dayIndex = utc.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    final bucketIndex = dayIndex ~/ days;
    final startMs = bucketIndex * days * Duration.millisecondsPerDay;
    return DateTime.fromMillisecondsSinceEpoch(startMs, isUtc: true).startOfDay;
  }

  /// Stable wire form `YYYY-MM-DD` for domain-separated seed packing.
  static String formatDay(DateTime utcDay) {
    final d = utcDay.toUtc();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// Bucket id used in seed material and `PQDGAResult.epoch`.
  static String idFor(DateTime date, int rotationDays) {
    return formatDay(bucketStart(date, rotationDays));
  }
}
