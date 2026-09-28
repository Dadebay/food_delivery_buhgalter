import 'package:intl/intl.dart';

/// Everything in this app is measured in Ashgabat time, UTC+5, with no
/// daylight saving.
///
/// The phone's own timezone is never used to decide which day or which shift
/// a record belongs to: an accountant checking the books from another country
/// must see the same month boundaries as the office. Dates are formatted for
/// display from the server's instants converted into this offset, and the
/// calendar parameters sent back (`fromDate`, `toDate`) are plain dates in it.
class Ashgabat {
  const Ashgabat._();

  static const Duration offset = Duration(hours: 5);

  /// The given instant as an Ashgabat wall clock, carried as a "local" value
  /// purely so the formatters below read its fields directly.
  static DateTime toLocal(DateTime instant) =>
      instant.toUtc().add(offset);

  /// Right now, in Ashgabat.
  static DateTime now() => toLocal(DateTime.now());

  /// `2026-09-01` — the shape `fromDate`/`toDate` take.
  static String date(DateTime day) =>
      DateFormat('yyyy-MM-dd').format(DateTime(day.year, day.month, day.day));

  static DateTime? parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static DateTime firstOfMonth(DateTime day) => DateTime(day.year, day.month, 1);

  /// The last day of [day]'s month — 28, 29, 30 or 31, worked out by stepping
  /// back from the first of the next month rather than by a table.
  static DateTime lastOfMonth(DateTime day) =>
      DateTime(day.year, day.month + 1, 1).subtract(const Duration(days: 1));

  /// Every day of the month, so a chart can show the whole axis and fill the
  /// days the server had nothing for. A money response legitimately omits
  /// days with no takings; those are zeros, and a failed request is not.
  static List<DateTime> daysOfMonth(DateTime month) {
    final last = lastOfMonth(month).day;
    return [for (var d = 1; d <= last; d++) DateTime(month.year, month.month, d)];
  }

  static String monthLabel(DateTime month, String locale) =>
      DateFormat('LLLL yyyy', locale).format(month);

  static String dayLabel(DateTime day, String locale) =>
      DateFormat('d MMMM yyyy', locale).format(day);

  static String shortDay(DateTime day) => DateFormat('d.MM').format(day);

  /// An instant from the API, shown in Ashgabat time. Returns null for null
  /// so callers can print "unknown" rather than today's date.
  static String? dateTimeLabel(DateTime? instant, String locale) {
    if (instant == null) return null;
    return DateFormat('d MMM yyyy, HH:mm', locale).format(toLocal(instant));
  }

  static String? timeLabel(DateTime? instant) {
    if (instant == null) return null;
    return DateFormat('HH:mm').format(toLocal(instant));
  }
}
