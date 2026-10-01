import '../constants/constants.dart';
import 'api_client.dart';
import 'models/audit.dart';
import 'models/carryover.dart';
import 'models/order.dart';
import 'models/overview.dart';
import 'models/paged.dart';
import 'models/report.dart';
import 'models/shift.dart';

/// Which population a list of orders is drawn from.
///
/// They are genuinely different sets, not two sorts of the same one: an
/// order created on the day shift can have its cash returned at night.
enum OrderBasis { created, cashReturned }

extension OrderBasisValue on OrderBasis {
  String get value =>
      this == OrderBasis.created ? 'created' : 'cashReturned';
}

/// A period to ask about: either a calendar range or one shift.
///
/// `/report` and `/shifts` take **only** calendar dates; the rest accept
/// either. Keeping both in one object is what stops a shift key from being
/// sent to an endpoint that cannot read it.
class Period {
  const Period.range(this.fromDate, this.toDate) : shiftKey = null;
  const Period.shift(this.shiftKey)
      : fromDate = null,
        toDate = null;

  /// `2026-09-01`
  final String? fromDate;

  /// `2026-09-30`, inclusive.
  final String? toDate;

  /// `2026-09-27:first`
  final String? shiftKey;

  bool get isShift => shiftKey != null;

  Map<String, dynamic> get query => isShift
      ? {'shiftKey': shiftKey}
      : {'fromDate': fromDate, 'toDate': toDate};
}

/// Every `/accounting` endpoint this app reads.
///
/// Nothing here derives financial or status truth: each method hands back
/// what the server said. There is no `/monthly` endpoint — a month is the
/// three range calls made together, which is what [month] does.
class AccountingService {
  AccountingService(this._api);

  final ApiClient _api;

  Future<AccountingSettings> settings() async =>
      AccountingSettings.fromJson(await _api.get('accounting/settings'));

  /// Shifts of a calendar range, with what each owes and its money packet.
  /// Calendar dates only.
  Future<List<ShiftSummary>> shifts({
    required String fromDate,
    required String toDate,
  }) async {
    final data = await _api.get(
      'accounting/shifts',
      query: {'fromDate': fromDate, 'toDate': toDate},
    );
    final raw = data is Map<String, dynamic> ? data['items'] ?? data['shifts'] : data;
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ShiftSummary.fromJson)
        .toList();
  }

  /// Money returned in a calendar range. Calendar dates only — a whole day's
  /// report must never be labelled as one shift's takings; those come from
  /// the matching entry of [shifts].
  Future<AccountingReport> report({
    required String fromDate,
    required String toDate,
  }) async =>
      AccountingReport.fromJson(await _api.get(
        'accounting/report',
        query: {'fromDate': fromDate, 'toDate': toDate},
      ));

  /// Demand, cancellations and edits. Takes a shift key or a calendar range.
  Future<AccountingOverview> overview(Period period) async =>
      AccountingOverview.fromJson(
        await _api.get('accounting/overview', query: period.query),
      );

  Future<Paged<OrderSummary>> orders({
    required Period period,
    required OrderBasis basis,
    int page = 1,
    int limit = kPageSize,
    int? number,
    String? status,
  }) async =>
      Paged<OrderSummary>.fromJson(
        await _api.get('accounting/orders', query: {
          ...period.query,
          'basis': basis.value,
          'page': page,
          'limit': limit,
          // Exact match, and still limited to the chosen period.
          'number': number,
          'status': status,
        }),
        OrderSummary.fromJson,
      );

  /// Details by UUID. The visible `number` is not this parameter.
  Future<OrderDetail> order(String id) async =>
      OrderDetail.fromJson(await _api.get('accounting/orders/$id'));

  /// The whole history of one order, regardless of the dates chosen
  /// elsewhere in the app.
  Future<Paged<AuditEntry>> orderAudit(
    String id, {
    int page = 1,
    int limit = kPageSize,
  }) async =>
      Paged<AuditEntry>.fromJson(
        await _api.get('accounting/orders/$id/audit',
            query: {'page': page, 'limit': limit}),
        AuditEntry.fromJson,
      );

  Future<CarryoverPage> carryover({
    required Period period,
    required bool incoming,
    int page = 1,
    int limit = kPageSize,
  }) async =>
      CarryoverPage.fromJson(await _api.get('accounting/carryover', query: {
        ...period.query,
        'direction': incoming ? 'in' : 'out',
        'page': page,
        'limit': limit,
      }));

  /// The general log of saved actions across all sections.
  Future<Paged<AuditEntry>> audit({
    required Period period,
    int page = 1,
    int limit = kPageSize,
    String? actorId,
    String? action,
    String? entityType,
  }) async =>
      Paged<AuditEntry>.fromJson(
        await _api.get('accounting/audit', query: {
          ...period.query,
          'page': page,
          'limit': limit,
          'actorId': actorId,
          'action': action,
          'entityType': entityType,
        }),
        AuditEntry.fromJson,
      );

  /// The accountant confirms an existing packet after checking the amount.
  ///
  /// Orders are never moved to `RECONCILED` by separate requests: the server
  /// does that for the contents of the confirmed packet. On a 409 the caller
  /// reloads and shows the server's answer instead of retrying.
  Future<CashHandoff?> confirmHandoff(String handoffId, {String? note}) async {
    final trimmed = note?.trim();
    return CashHandoff.fromJson(
      await _api.patch(
        'accounting/handoffs/$handoffId/confirm',
        body: {
          if (trimmed != null && trimmed.isNotEmpty)
            'note': trimmed.length > 500 ? trimmed.substring(0, 500) : trimmed,
        },
      ),
    );
  }

  /// Creating a money packet is an administrator/owner action, never the
  /// accountant's: the screens hide the button for anyone else and the
  /// server refuses it regardless.
  Future<CashHandoff?> createHandoff({
    required String shiftKey,
    double? declaredAmount,
    String? note,
  }) async {
    final trimmed = note?.trim();
    return CashHandoff.fromJson(
      await _api.post('accounting/handoffs', body: {
        'shiftKey': shiftKey,
        if (declaredAmount != null) 'declaredAmount': declaredAmount,
        if (trimmed != null && trimmed.isNotEmpty)
          'note': trimmed.length > 500 ? trimmed.substring(0, 500) : trimmed,
      }),
    );
  }

  /// The super-admin marks an order's cash as returned, for a `DELIVERED`
  /// order the courier's own app never confirmed. This is the same
  /// `/orders/:id/transition` the courier app uses, not an `/accounting`
  /// endpoint — the server creates the money record itself from
  /// `total - deliveryFee`; nothing else is sent in the body. [version] must
  /// be the order's current version, not its visible number, or the server
  /// answers with a 409.
  Future<void> markCashReturned(String orderId, {required int version}) =>
      _api.patch(
        'orders/$orderId/transition',
        body: {'status': 'CASH_RETURNED', 'version': version},
      );

  /// A month, built from the three range calls the spec prescribes. There is
  /// no `/monthly`; the rest of the pages load when their section is opened
  /// rather than being downloaded to build charts.
  Future<MonthBundle> month({
    required String fromDate,
    required String toDate,
  }) async {
    final results = await Future.wait([
      overview(Period.range(fromDate, toDate)),
      report(fromDate: fromDate, toDate: toDate),
      shifts(fromDate: fromDate, toDate: toDate),
    ]);
    return MonthBundle(
      overview: results[0] as AccountingOverview,
      report: results[1] as AccountingReport,
      shifts: results[2] as List<ShiftSummary>,
    );
  }
}

class MonthBundle {
  const MonthBundle({
    required this.overview,
    required this.report,
    required this.shifts,
  });

  final AccountingOverview overview;
  final AccountingReport report;
  final List<ShiftSummary> shifts;
}
