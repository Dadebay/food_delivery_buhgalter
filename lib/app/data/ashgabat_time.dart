import 'package:intl/intl.dart';

import 'app_state.dart';

/// Everything in this app is measured in Ashgabat time, UTC+5, with no
/// daylight saving.
///
/// The phone's own timezone is never used to decide which day or which shift
/// a record belongs to: an accountant checking the books from another country
/// must see the same month boundaries as the office.
///
/// Month names are carried here rather than taken from the `intl` locale
/// database, because the app speaks Turkmen as well and the two languages
/// have to be spelled the same way everywhere.
class Ashgabat {
  const Ashgabat._();

  static const Duration offset = Duration(hours: 5);

  static const List<String> _ruMonths = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  /// Russian needs the genitive for "27 сентября 2026".
  static const List<String> _ruMonthsOfDay = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  static const List<String> _tmMonths = [
    'Ýanwar', 'Fewral', 'Mart', 'Aprel', 'Maý', 'Iýun',
    'Iýul', 'Awgust', 'Sentýabr', 'Oktýabr', 'Noýabr', 'Dekabr',
  ];

  static bool get _turkmen => App.instance.language.isTurkmen;

  /// The given instant as an Ashgabat wall clock, carried as a "local" value
  /// purely so the formatters below read its fields directly.
  static DateTime toLocal(DateTime instant) => instant.toUtc().add(offset);

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

  /// «Сентябрь» / «Sentýabr».
  static String monthName(DateTime month) {
    final index = (month.month - 1).clamp(0, 11);
    return _turkmen ? _tmMonths[index] : _ruMonths[index];
  }

  /// «Сентябрь 2026» / «Sentýabr 2026».
  static String monthLabel(DateTime month) =>
      '${monthName(month)} ${month.year}';

  /// «27 сентября 2026» / «27 sentýabr 2026».
  static String dayLabel(DateTime day) {
    final index = (day.month - 1).clamp(0, 11);
    final name = _turkmen ? _tmMonths[index].toLowerCase() : _ruMonthsOfDay[index];
    return '${day.day} $name ${day.year}';
  }

  static String shortDay(DateTime day) => DateFormat('d.MM').format(day);

  /// An instant from the API, shown in Ashgabat time as `27.09.2026, 14:53`.
  /// Returns null for null so callers can print "unknown" rather than
  /// today's date.
  static String? dateTimeLabel(DateTime? instant) {
    if (instant == null) return null;
    return DateFormat('dd.MM.yyyy, HH:mm').format(toLocal(instant));
  }

  /// A packet's own period, frozen when it was handed over: it may start in
  /// the evening of one day and cross midnight, and is never trimmed to a day.
  static String? periodLabel(DateTime? start, DateTime? end) {
    final from = dateTimeLabel(start);
    final to = dateTimeLabel(end);
    if (from == null || to == null) return null;
    return '$from – $to';
  }

  static String? timeLabel(DateTime? instant) {
    if (instant == null) return null;
    return DateFormat('HH:mm').format(toLocal(instant));
  }
}
