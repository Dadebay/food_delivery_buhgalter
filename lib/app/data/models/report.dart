import 'paged.dart';
import 'shift.dart';

/// `GET /accounting/report` — money, by the day it came **back**.
///
/// This is a different population from the orders: an order created on the
/// day shift can have its cash returned at night, and it counts here on the
/// night it returned (`operatorTakenAt`), not on the day it was placed.
class AccountingReport {
  const AccountingReport({
    required this.summary,
    this.daily = const [],
    this.handoffs = const [],
  });

  final ReportSummary summary;
  final List<DailyMoney> daily;
  final List<CashHandoff> handoffs;

  factory AccountingReport.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return const AccountingReport(summary: ReportSummary());
    }
    return AccountingReport(
      summary: ReportSummary.fromJson(json['summary']),
      daily: (json['daily'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DailyMoney.fromJson)
          .toList(),
      handoffs: (json['handoffs'] as List<dynamic>? ?? const [])
          .map(CashHandoff.fromJson)
          .whereType<CashHandoff>()
          .toList(),
    );
  }
}

class ReportSummary {
  const ReportSummary({
    this.collectedAmount,
    this.submittedAmount,
    this.confirmedAmount,
    this.outstandingAmount,
    this.declaredHandoffAmount,
    this.handoffDiscrepancy,
    this.completedOrders,
    this.averageOrderAmount,
  });

  final double? collectedAmount;
  final double? submittedAmount;
  final double? confirmedAmount;

  /// Collected but not yet handed over.
  final double? outstandingAmount;

  /// What the packets whose shifts started in this period declared.
  final double? declaredHandoffAmount;

  /// Declared minus expected for those packets. Negative means a shortfall.
  /// It is not a system fee and not evidence that the notes were recounted.
  final double? handoffDiscrepancy;

  /// Money records in the period, as the server counts them.
  final int? completedOrders;

  /// Average food amount of those records, the server's own figure.
  final double? averageOrderAmount;

  factory ReportSummary.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return const ReportSummary();
    return ReportSummary(
      collectedAmount: asDouble(json['collectedAmount']),
      submittedAmount: asDouble(json['submittedAmount']),
      confirmedAmount: asDouble(json['confirmedAmount']),
      outstandingAmount: asDouble(json['outstandingAmount']),
      declaredHandoffAmount: asDouble(json['declaredHandoffAmount']),
      handoffDiscrepancy: asDouble(json['handoffDiscrepancy']),
      completedOrders: asInt(json['completedOrders']),
      averageOrderAmount: asDouble(json['averageOrderAmount']),
    );
  }
}

/// One day of money returned. Days with no takings may simply be absent from
/// the response; the chart fills them with zero on the month's own axis.
class DailyMoney {
  const DailyMoney({required this.date, this.amount, this.orderCount});

  final String date;
  final double? amount;
  final int? orderCount;

  factory DailyMoney.fromJson(Map<String, dynamic> json) => DailyMoney(
        date: (json['date'] ?? '').toString(),
        amount: asDouble(json['amount']),
        orderCount: asInt(json['orderCount']),
      );
}
