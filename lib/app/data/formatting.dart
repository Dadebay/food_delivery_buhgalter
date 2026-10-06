import 'package:intl/intl.dart';

import 'strings.dart';

/// What a missing value is called. The spec is explicit that absent names,
/// staff and dates are shown as unknown rather than filled in with today's
/// date or the nearest plausible person.
String get kUnknown => S.unknown;

/// Language-neutral placeholder for a value that has no meaning here at all.
const String kDash = '—';

class Fmt {
  const Fmt._();

  static final NumberFormat _money = NumberFormat('#,##0.00', 'ru');
  static final NumberFormat _count = NumberFormat('#,##0', 'ru');

  /// All amounts in the API are numbers in TMT.
  static String money(double? value) =>
      value == null ? kDash : '${_money.format(value)} TMT';

  /// Signed, for the hand-over discrepancy: a minus sign there is a shortfall
  /// and has to stay visible.
  static String signedMoney(double? value) {
    if (value == null) return kDash;
    final sign = value > 0 ? '+' : '';
    return '$sign${_money.format(value)} TMT';
  }

  static String count(int? value) =>
      value == null ? kDash : _count.format(value);

  /// `cancellationRate` is shown as a percentage. The API sends a share, so a
  /// value at or below 1 is read as a fraction; anything larger is already in
  /// percent and is printed as it came.
  static String percent(double? rate) {
    if (rate == null) return kDash;
    final value = rate <= 1 ? rate * 100 : rate;
    return '${NumberFormat('#,##0.#', 'ru').format(value)} %';
  }

  /// A share already measured in percent (0–100), printed as it is. Unlike
  /// [percent] it never guesses whether the number was a fraction.
  static String percentValue(double value) =>
      '${NumberFormat('#,##0.#', 'ru').format(value)} %';

  /// `preparationMinutes` is 0…1440 and 520 is a legal value: it is printed
  /// in full, never clamped back to the old 240 ceiling.
  static String minutes(int? value) {
    if (value == null) return kDash;
    if (value < 60) return '$value ${S.minutesShort}';
    final hours = value ~/ 60;
    final rest = value % 60;
    return rest == 0
        ? '$hours ${S.hoursShort}'
        : '$hours ${S.hoursShort} $rest ${S.minutesShort}';
  }

  static String text(String? value) =>
      (value == null || value.trim().isEmpty) ? kUnknown : value.trim();

  /// «Заказ №27» — the visible number, which is not the UUID used for details.
  static String orderNumber(int? number) =>
      number == null ? S.order : S.orderNo(number);
}
