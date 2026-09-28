import 'paged.dart';

/// The shift names and boundaries, read from `GET /accounting/settings`.
///
/// The times are never hardcoded in the app. 09:30/19:00 is today's schedule,
/// not a property of the product, and an app that baked them in would start
/// lying the day the owner changes them.
class AccountingSettings {
  const AccountingSettings({this.shifts = const []});

  final List<ShiftDefinition> shifts;

  factory AccountingSettings.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return const AccountingSettings();
    final raw = json['shifts'];
    return AccountingSettings(
      shifts: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(ShiftDefinition.fromJson)
              .toList()
          : const [],
    );
  }

  /// The configured name for `first`/`second`, or null when the settings have
  /// not been read — callers fall back to a generic label rather than to an
  /// invented time.
  String? nameFor(String slot) {
    for (final shift in shifts) {
      if (shift.slot == slot) return shift.name;
    }
    return null;
  }
}

class ShiftDefinition {
  const ShiftDefinition({
    required this.slot,
    this.name,
    this.startsAt,
    this.endsAt,
  });

  /// `first` or `second`, the half of `shiftKey` after the colon.
  final String slot;
  final String? name;
  final String? startsAt;
  final String? endsAt;

  factory ShiftDefinition.fromJson(Map<String, dynamic> json) => ShiftDefinition(
        slot: (json['slot'] ?? json['key'] ?? '').toString(),
        name: json['name'] as String?,
        startsAt: json['startsAt'] as String?,
        endsAt: json['endsAt'] as String?,
      );

  String get window =>
      startsAt == null || endsAt == null ? '' : '$startsAt – $endsAt';
}

/// One shift in a range — `GET /accounting/shifts`.
class ShiftSummary {
  const ShiftSummary({
    required this.shiftKey,
    this.name,
    this.date,
    this.startsAt,
    this.endsAt,
    this.expectedAmount,
    this.collectedAmount,
    this.orderCount,
    this.handoff,
  });

  /// `2025-02-01:first` — replaces the calendar range wherever it is accepted.
  /// `/report` and `/shifts` do **not** take it.
  final String shiftKey;
  final String? name;
  final DateTime? date;
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// What the shift is expected to hand over, as the server computed it.
  final double? expectedAmount;
  final double? collectedAmount;
  final int? orderCount;

  /// The money packet for this shift, once one exists.
  final CashHandoff? handoff;

  factory ShiftSummary.fromJson(Map<String, dynamic> json) => ShiftSummary(
        shiftKey: (json['shiftKey'] ?? '').toString(),
        name: json['name'] as String?,
        date: DateTime.tryParse(json['date'] as String? ?? ''),
        startsAt: DateTime.tryParse(json['startsAt'] as String? ?? ''),
        endsAt: DateTime.tryParse(json['endsAt'] as String? ?? ''),
        expectedAmount: asDouble(json['expectedAmount']),
        collectedAmount: asDouble(json['collectedAmount']),
        orderCount: asInt(json['orderCount']),
        handoff: CashHandoff.fromJson(json['handoff']),
      );

  /// The calendar day half of the key, for grouping two shifts under one day.
  String get dayKey =>
      shiftKey.contains(':') ? shiftKey.split(':').first : shiftKey;

  String get slot =>
      shiftKey.contains(':') ? shiftKey.split(':').last : '';
}

/// A handed-over money packet. Its own boundaries are frozen when it is
/// submitted — a later change to the schedule does not rewrite them.
class CashHandoff {
  const CashHandoff({
    required this.id,
    this.status,
    this.expectedAmount,
    this.declaredAmount,
    this.settlementCount,
    this.submittedBy,
    this.confirmedBy,
    this.submittedAt,
    this.confirmedAt,
    this.note,
    this.confirmationNote,
    this.shiftKey,
  });

  final String id;

  /// `SUBMITTED`, `CONFIRMED`, … as the server names it.
  final String? status;
  final double? expectedAmount;
  final double? declaredAmount;
  final int? settlementCount;
  final Actor? submittedBy;
  final Actor? confirmedBy;
  final DateTime? submittedAt;
  final DateTime? confirmedAt;
  final String? note;
  final String? confirmationNote;
  final String? shiftKey;

  bool get isConfirmed => (status ?? '').toUpperCase() == 'CONFIRMED';

  /// Declared minus expected. Negative is a shortfall. It is not a fee and
  /// not proof that anybody counted the notes.
  double? get discrepancy => declaredAmount == null || expectedAmount == null
      ? null
      : declaredAmount! - expectedAmount!;

  static CashHandoff? fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    if (id == null) return null;
    return CashHandoff(
      id: id.toString(),
      status: json['status'] as String?,
      expectedAmount: asDouble(json['expectedAmount']),
      declaredAmount: asDouble(json['declaredAmount']),
      settlementCount: asInt(json['settlementCount']),
      submittedBy: Actor.fromJson(json['submittedBy']),
      confirmedBy: Actor.fromJson(json['confirmedBy']),
      submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? ''),
      confirmedAt: DateTime.tryParse(json['confirmedAt'] as String? ?? ''),
      note: json['note'] as String?,
      confirmationNote: json['confirmationNote'] as String?,
      shiftKey: json['shiftKey'] as String?,
    );
  }
}
