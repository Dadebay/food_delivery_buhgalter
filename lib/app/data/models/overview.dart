import 'paged.dart';

/// `GET /accounting/overview` — demand and actions, by the time the order was
/// **created** (and, for the event counters, by the time of the action).
class AccountingOverview {
  const AccountingOverview({
    required this.summary,
    this.daily = const [],
    this.districts = const [],
    this.branches = const [],
    this.mostOrderedProducts = const [],
    this.leastOrderedProducts = const [],
    this.cancellationReasons = const [],
  });

  final OverviewSummary summary;
  final List<DailyOrders> daily;
  final List<NamedCount> districts;
  final List<NamedCount> branches;

  /// Ten most and ten least ordered, counted in portions rather than money.
  /// Dishes nobody ordered are not in "least"; a renamed dish can appear as
  /// its own historical row.
  final List<ProductDemand> mostOrderedProducts;
  final List<ProductDemand> leastOrderedProducts;
  final List<NamedCount> cancellationReasons;

  factory AccountingOverview.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return const AccountingOverview(summary: OverviewSummary());
    }
    List<T> list<T>(String key, T Function(Map<String, dynamic>) item) =>
        (json[key] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(item)
            .toList();
    return AccountingOverview(
      summary: OverviewSummary.fromJson(json['summary']),
      daily: list('daily', DailyOrders.fromJson),
      districts: list('districts', NamedCount.fromJson),
      branches: list('branches', NamedCount.fromJson),
      mostOrderedProducts: list('mostOrderedProducts', ProductDemand.fromJson),
      leastOrderedProducts: list('leastOrderedProducts', ProductDemand.fromJson),
      cancellationReasons: list('cancellationReasons', NamedCount.fromJson),
    );
  }
}

class OverviewSummary {
  const OverviewSummary({
    this.createdOrders,
    this.cancelledOrders,
    this.cancellationRate,
    this.editEvents,
    this.cancellationEvents,
    this.foodAmount,
  });

  final int? createdOrders;

  /// Orders created in the period that are cancelled **now** — a state, not
  /// an event count.
  final int? cancelledOrders;
  final double? cancellationRate;

  /// Content edits, and transitions into cancellation, that happened during
  /// the period — including to orders from an earlier shift.
  final int? editEvents;
  final int? cancellationEvents;

  final double? foodAmount;

  factory OverviewSummary.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return const OverviewSummary();
    return OverviewSummary(
      createdOrders: asInt(json['createdOrders']),
      cancelledOrders: asInt(json['cancelledOrders']),
      cancellationRate: asDouble(json['cancellationRate']),
      editEvents: asInt(json['editEvents']),
      cancellationEvents: asInt(json['cancellationEvents']),
      foodAmount: asDouble(json['foodAmount']),
    );
  }
}

class DailyOrders {
  const DailyOrders({required this.date, this.orders, this.cancelled});

  final String date;
  final int? orders;
  final int? cancelled;

  factory DailyOrders.fromJson(Map<String, dynamic> json) => DailyOrders(
        date: (json['date'] ?? '').toString(),
        orders: asInt(json['orders']),
        cancelled: asInt(json['cancelled']),
      );
}

/// A district, a kitchen, or a cancellation reason: a saved name with a count
/// and the food money behind it. Districts come from the names stored on the
/// order — an unknown one is shown as such, never guessed from the address.
class NamedCount {
  const NamedCount({required this.name, this.count, this.foodAmount});

  final String? name;
  final int? count;
  final double? foodAmount;

  factory NamedCount.fromJson(Map<String, dynamic> json) => NamedCount(
        name: json['name'] as String?,
        count: asInt(json['count']),
        foodAmount: asDouble(json['foodAmount']),
      );
}

class ProductDemand {
  const ProductDemand({this.productId, this.name, this.quantity});

  final String? productId;
  final String? name;

  /// Portions, not money.
  final int? quantity;

  factory ProductDemand.fromJson(Map<String, dynamic> json) => ProductDemand(
        productId: json['productId']?.toString(),
        name: json['name'] as String?,
        quantity: asInt(json['quantity']),
      );
}
