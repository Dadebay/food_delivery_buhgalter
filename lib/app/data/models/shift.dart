import 'paged.dart';

/// One calendar day of the cash book — `GET /accounting/days`.
///
/// The JSON and Swagger names (`shiftKey`, `AccountingShiftResponseDto`) are
/// kept by the server for compatibility; in this app it is a **day**,
/// 00:00–00:00 in Ashgabat, and its key always ends in `:day`.
class CashDay {
  const CashDay({
    required this.shiftKey,
    this.shiftName,
    this.periodStart,
    this.periodEnd,
    this.isComplete = false,
    this.expectedAmount,
    this.availableAmount,
    this.settlementCount,
    this.canSubmit = false,
    this.state,
    this.handoff,
    this.historicalHandoffs = const [],
  });

  /// `2026-10-04:day` — replaces the calendar range wherever it is accepted.
  /// `/report` and `/days` do **not** take it.
  final String shiftKey;
  final String? shiftName;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  /// The day has already ended by the server's clock.
  final bool isComplete;

  /// All food money counted for the day, including what is already in a
  /// packet or reconciled.
  final double? expectedAmount;

  /// Confirmed money not yet included in any packet.
  final double? availableAmount;

  /// Money records of the day — not the number of orders created that day.
  final int? settlementCount;

  /// There is something to hand over. Not a personal permission.
  final bool canSubmit;

  /// `OPEN`, `EMPTY`, `READY`, `SUBMITTED`, `CONFIRMED`.
  final String? state;

  final CashHandoff? handoff;
  final List<CashHandoff> historicalHandoffs;

  factory CashDay.fromJson(Map<String, dynamic> json) => CashDay(
        shiftKey: (json['shiftKey'] ?? '').toString(),
        shiftName: json['shiftName'] as String?,
        periodStart: DateTime.tryParse(json['periodStart'] as String? ?? ''),
        periodEnd: DateTime.tryParse(json['periodEnd'] as String? ?? ''),
        isComplete: json['isComplete'] as bool? ?? false,
        expectedAmount: asDouble(json['expectedAmount']),
        availableAmount: asDouble(json['availableAmount']),
        settlementCount: asInt(json['settlementCount']),
        canSubmit: json['canSubmit'] as bool? ?? false,
        state: json['state'] as String?,
        handoff: CashHandoff.fromJson(json['handoff']),
        historicalHandoffs: (json['historicalHandoffs'] as List<dynamic>? ??
                const [])
            .map(CashHandoff.fromJson)
            .whereType<CashHandoff>()
            .toList(),
      );

  /// The calendar date half of the key, `2026-10-04`.
  String get dayKey =>
      shiftKey.contains(':') ? shiftKey.split(':').first : shiftKey;

  /// The new daily packet and the old ones, without nulls or duplicates.
  List<CashHandoff> get packets {
    final seen = <String>{};
    return [
      if (handoff != null) handoff!,
      ...historicalHandoffs,
    ].where((packet) => seen.add(packet.id)).toList();
  }

  /// What the accountant can act on. Decided by each packet's own status, not
  /// by [state]: a day can keep old packets while its own `handoff` is null.
  List<CashHandoff> get pending =>
      packets.where((packet) => packet.isSubmitted).toList();

  /// Today's day may only be handed over once it has ended; the server
  /// refuses it either way.
  bool get canCreatePacket => isComplete && canSubmit && handoff == null;
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
    this.shiftName,
    this.periodStart,
    this.periodEnd,
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
  final String? shiftName;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  bool get isSubmitted => (status ?? '').toUpperCase() == 'SUBMITTED';
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
      shiftName: json['shiftName'] as String?,
      periodStart: DateTime.tryParse(json['periodStart'] as String? ?? ''),
      periodEnd: DateTime.tryParse(json['periodEnd'] as String? ?? ''),
    );
  }
}
