import 'paged.dart';

/// One saved business action — `GET /accounting/audit` and
/// `GET /accounting/orders/:id/audit`.
///
/// The log records business actions, not taps or menu navigation. It helps
/// an inspection; it does not replace a physical count of cash and stock, or
/// control over access to the database itself.
class AuditEntry {
  const AuditEntry({
    required this.id,
    this.orderId,
    this.orderNumber,
    this.actor,
    this.relatedActors = const [],
    this.createdAt,
    this.action,
    this.entityType,
    this.entityId,
    this.metadata,
  });

  final String id;

  /// Both nullable: an event that is not about an order has neither, and the
  /// UI must not draw "Заказ №null" for it.
  final String? orderId;
  final int? orderNumber;

  final Actor? actor;

  /// Lets the saved staff references in [metadata] be shown as names.
  final List<Actor> relatedActors;

  final DateTime? createdAt;

  /// `order.created`, `cash_handoff.confirmed`, … An action this build does
  /// not know is never hidden: it is labelled generically and shown with its
  /// raw content.
  final String? action;
  final String? entityType;
  final String? entityId;

  final Map<String, dynamic>? metadata;

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
        id: (json['id'] ?? '').toString(),
        orderId: json['orderId']?.toString(),
        orderNumber: asInt(json['orderNumber']),
        actor: Actor.fromJson(json['actor']),
        relatedActors: (json['relatedActors'] as List<dynamic>? ?? const [])
            .map(Actor.fromJson)
            .whereType<Actor>()
            .toList(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        action: json['action'] as String?,
        entityType: json['entityType'] as String?,
        entityId: json['entityId']?.toString(),
        metadata: json['metadata'] is Map<String, dynamic>
            ? json['metadata'] as Map<String, dynamic>
            : null,
      );

  /// The before/after pair the server saved, under either of the two names
  /// it uses. Null when this event kind does not carry a comparison — old
  /// events with no snapshot cannot be reconstructed after the fact.
  Map<String, dynamic>? get before => _pair('before', 'previous');
  Map<String, dynamic>? get after => _pair('after', 'current');

  bool get hasComparison => before != null || after != null;

  Map<String, dynamic>? _pair(String a, String b) {
    final meta = metadata;
    if (meta == null) return null;
    final value = meta[a] ?? meta[b];
    return value is Map<String, dynamic> ? value : null;
  }

  /// Every field name that appears on either side, so the two can be shown
  /// as one aligned comparison rather than two loose objects.
  List<String> get changedFields {
    final keys = <String>{...?before?.keys, ...?after?.keys};
    final list = keys.toList()..sort();
    return list;
  }

  /// A saved actor id replaced by the name the log carried with it.
  String? actorName(String? id) {
    if (id == null) return null;
    for (final related in relatedActors) {
      if (related.id == id) return related.fullName ?? related.id;
    }
    if (actor?.id == id) return actor?.fullName ?? id;
    return null;
  }
}
