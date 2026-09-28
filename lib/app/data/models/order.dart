import 'paged.dart';

/// One row in `GET /accounting/orders`.
///
/// `number` is the visible "Заказ №27" and is **not** the `:id` path
/// parameter — details are fetched with the UUID [id].
class OrderSummary {
  const OrderSummary({
    required this.id,
    this.number,
    this.status,
    this.createdAt,
    this.customerName,
    this.branchName,
    this.deliveryEtrapName,
    this.foodAmount,
    this.deliveryFee,
    this.total,
    this.cashReturnedAt,
  });

  final String id;
  final int? number;
  final String? status;
  final DateTime? createdAt;
  final String? customerName;
  final String? branchName;
  final String? deliveryEtrapName;

  /// `total - deliveryFee`, already after the discount — the server's own
  /// figure, not recomputed here.
  final double? foodAmount;
  final double? deliveryFee;
  final double? total;

  /// When the money came back, for the `basis=cashReturned` listing. Null on
  /// a historically reconciled order whose real hand-over date is unknown.
  final DateTime? cashReturnedAt;

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
        id: (json['id'] ?? '').toString(),
        number: asInt(json['number']),
        status: json['status'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        customerName: json['customerName'] as String?,
        branchName: json['branchName'] as String?,
        deliveryEtrapName: json['deliveryEtrapName'] as String?,
        foodAmount: asDouble(json['foodAmount']),
        deliveryFee: asDouble(json['deliveryFee']),
        total: asDouble(json['total']),
        cashReturnedAt:
            DateTime.tryParse(json['operatorTakenAt'] as String? ?? json['cashReturnedAt'] as String? ?? ''),
      );
}

/// `GET /accounting/orders/:id`.
class OrderDetail {
  const OrderDetail({
    required this.id,
    this.number,
    this.status,
    this.source,
    this.createdAt,
    this.customerName,
    this.customerPhone,
    this.customerNote,
    this.address,
    this.entrance,
    this.floor,
    this.apartment,
    this.branchName,
    this.deliveryEtrapName,
    this.items = const [],
    this.gifts = const [],
    this.loyaltyPointsEarned,
    this.loyaltyPointsSpent,
    this.rating,
    this.subtotal,
    this.discount,
    this.foodAmount,
    this.deliveryFee,
    this.total,
    this.courier,
    this.cook,
    this.participants = const [],
    this.actualCourierUnknown = false,
    this.assignedAt,
    this.packingConfirmedAt,
    this.deliveredAt,
    this.completedAt,
    this.transitions = const [],
    this.settlement,
  });

  final String id;
  final int? number;
  final String? status;
  final String? source;
  final DateTime? createdAt;

  final String? customerName;
  final String? customerPhone;
  final String? customerNote;

  final String? address;
  final String? entrance;
  final String? floor;
  final String? apartment;
  final String? branchName;
  final String? deliveryEtrapName;

  final List<OrderLine> items;
  final List<OrderGift> gifts;
  final int? loyaltyPointsEarned;
  final int? loyaltyPointsSpent;
  final int? rating;

  final double? subtotal;
  final double? discount;
  final double? foodAmount;
  final double? deliveryFee;
  final double? total;

  final Actor? courier;
  final Actor? cook;
  final List<Participant> participants;

  /// True when the courier on the order is a technical assignment made while
  /// closing an old order. The screen must say "the actual courier is
  /// unknown" rather than present that person as the confirmed deliverer.
  final bool actualCourierUnknown;

  final DateTime? assignedAt;
  final DateTime? packingConfirmedAt;
  final DateTime? deliveredAt;
  final DateTime? completedAt;

  final List<OrderTransition> transitions;

  /// The money record, when there is one.
  final Settlement? settlement;

  factory OrderDetail.fromJson(dynamic json) {
    final map = json is Map<String, dynamic> ? json : <String, dynamic>{};
    List<T> list<T>(String key, T Function(Map<String, dynamic>) item) =>
        (map[key] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(item)
            .toList();
    return OrderDetail(
      id: (map['id'] ?? '').toString(),
      number: asInt(map['number']),
      status: map['status'] as String?,
      source: map['source'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
      customerName: map['customerName'] as String?,
      customerPhone: map['customerPhone'] as String?,
      customerNote: map['customerNote'] as String?,
      address: map['address'] as String?,
      entrance: map['entrance']?.toString(),
      floor: map['floor']?.toString(),
      apartment: map['apartment']?.toString(),
      branchName: map['branchName'] as String?,
      deliveryEtrapName: map['deliveryEtrapName'] as String?,
      items: list('items', OrderLine.fromJson),
      gifts: list('gifts', OrderGift.fromJson),
      loyaltyPointsEarned: asInt(map['loyaltyPointsEarned']),
      loyaltyPointsSpent: asInt(map['loyaltyPointsSpent']),
      rating: asInt(map['rating'] is Map ? (map['rating'] as Map)['score'] : map['rating']),
      subtotal: asDouble(map['subtotal']),
      discount: asDouble(map['discount']),
      foodAmount: asDouble(map['foodAmount']),
      deliveryFee: asDouble(map['deliveryFee']),
      total: asDouble(map['total']),
      courier: Actor.fromJson(map['courier']),
      cook: Actor.fromJson(map['cook']),
      participants: list('participants', Participant.fromJson),
      actualCourierUnknown: map['actualCourierUnknown'] as bool? ?? false,
      assignedAt: DateTime.tryParse(map['assignedAt'] as String? ?? ''),
      packingConfirmedAt:
          DateTime.tryParse(map['packingConfirmedAt'] as String? ?? ''),
      deliveredAt: DateTime.tryParse(map['deliveredAt'] as String? ?? ''),
      completedAt: DateTime.tryParse(map['completedAt'] as String? ?? ''),
      transitions: list('transitions', OrderTransition.fromJson),
      settlement: Settlement.fromJson(map['settlement']),
    );
  }

  String get addressLine {
    final parts = <String>[
      if ((address ?? '').trim().isNotEmpty) address!.trim(),
    ];
    return parts.join(', ');
  }
}

class OrderLine {
  const OrderLine({
    this.productName,
    this.variantName,
    this.quantity,
    this.unitPrice,
    this.lineTotal,
    this.preparationMinutes,
  });

  final String? productName;
  final String? variantName;
  final int? quantity;
  final double? unitPrice;
  final double? lineTotal;

  /// 0…1440 minutes, stored on the dish and copied onto the order line.
  /// Shown exactly as it arrives — 520 is a legal value and must not be
  /// clamped back to the old 240 ceiling.
  final int? preparationMinutes;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        productName: json['productName'] as String?,
        variantName: json['variantName'] as String?,
        quantity: asInt(json['quantity']),
        unitPrice: asDouble(json['unitPrice']),
        lineTotal: asDouble(json['lineTotal']),
        preparationMinutes: asInt(json['preparationMinutes']),
      );
}

class OrderGift {
  const OrderGift({this.name, this.quantity, this.pointsCost, this.totalPoints});

  final String? name;
  final int? quantity;
  final int? pointsCost;
  final int? totalPoints;

  factory OrderGift.fromJson(Map<String, dynamic> json) => OrderGift(
        name: json['name'] as String?,
        quantity: asInt(json['quantity']),
        pointsCost: asInt(json['pointsCost']),
        totalPoints: asInt(json['totalPoints']),
      );
}

/// Somebody who touched the order, with what they did.
///
/// The actions are assembled from stored events and transitions
/// (`transition:<OrderStatus>`). A person's role alone is not evidence that
/// they cooked or delivered it.
class Participant {
  const Participant({this.actor, this.actions = const []});

  final Actor? actor;
  final List<String> actions;

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
        actor: Actor.fromJson(json['actor']),
        actions: (json['actions'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

class OrderTransition {
  const OrderTransition({
    this.actor,
    this.createdAt,
    this.fromStatus,
    this.toStatus,
    this.note,
  });

  final Actor? actor;
  final DateTime? createdAt;
  final String? fromStatus;
  final String? toStatus;
  final String? note;

  factory OrderTransition.fromJson(Map<String, dynamic> json) => OrderTransition(
        actor: Actor.fromJson(json['actor']),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        fromStatus: json['fromStatus'] as String?,
        toStatus: json['toStatus'] as String?,
        note: json['note'] as String?,
      );
}

/// The money record attached to an order.
class Settlement {
  const Settlement({
    this.amount,
    this.status,
    this.operatorTakenAt,
    this.reconciledAt,
    this.operatorName,
    this.accountantName,
    this.cashHandoffId,
  });

  final double? amount;
  final String? status;

  /// When the operator took the money back. Null on a historically
  /// reconciled order: the real date is unknown and must not be replaced by
  /// `reconciledAt`, which would drop the order into today's shift.
  final DateTime? operatorTakenAt;
  final DateTime? reconciledAt;

  final String? operatorName;
  final String? accountantName;

  /// Links this record to the shift's money packet.
  final String? cashHandoffId;

  bool get isReconciled => (status ?? '').toUpperCase() == 'RECONCILED';

  /// "Reconciled; hand-over date unknown" — a real state for old records,
  /// not a loading gap.
  bool get isHandoverDateUnknown => isReconciled && operatorTakenAt == null;

  static Settlement? fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    return Settlement(
      amount: asDouble(json['amount']),
      status: json['status'] as String?,
      operatorTakenAt:
          DateTime.tryParse(json['operatorTakenAt'] as String? ?? ''),
      reconciledAt: DateTime.tryParse(json['reconciledAt'] as String? ?? ''),
      operatorName: json['operator'] is Map
          ? Actor.fromJson(json['operator'])?.fullName
          : json['operatorName'] as String?,
      accountantName: json['accountant'] is Map
          ? Actor.fromJson(json['accountant'])?.fullName
          : json['accountantName'] as String?,
      cashHandoffId: json['cashHandoffId']?.toString(),
    );
  }
}
