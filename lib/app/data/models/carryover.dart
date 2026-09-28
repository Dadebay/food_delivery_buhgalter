import 'order.dart';
import 'paged.dart';

/// An order carried across a shift boundary — `GET /accounting/carryover`.
///
/// Carried states are `COOKING`, `READY`, `ASSIGNED_TO_COURIER`,
/// `OUT_FOR_DELIVERY` and `DELIVERED`: the food is still being made or
/// delivered, or the money has not come back. `CASH_RETURNED`, `RECONCILED`
/// and `CANCELLED` do not carry over. An order created exactly on the
/// boundary belongs to the new shift and is not incoming from the previous
/// one. Handing over creates neither a second order nor a second payment.
class CarryoverEntry {
  const CarryoverEntry({
    required this.order,
    this.statusAtBoundary,
    this.snapshot,
    this.historicalSnapshotAvailable = true,
  });

  /// Current top-level values. Deliberately kept apart from [snapshot]:
  /// using these for a historical comparison would show today's contents
  /// under yesterday's boundary.
  final OrderSummary order;

  /// The status at the boundary, rebuilt from the transitions. [order.status]
  /// is the state right now, which can be different.
  final String? statusAtBoundary;

  /// Contents, address and amounts as they stood at the boundary. Null when
  /// the old change did not store a full snapshot.
  final Map<String, dynamic>? snapshot;

  /// False when no snapshot was stored. The screen has to say so rather than
  /// quietly show current values in its place.
  final bool historicalSnapshotAvailable;

  factory CarryoverEntry.fromJson(Map<String, dynamic> json) => CarryoverEntry(
        order: OrderSummary.fromJson(json),
        statusAtBoundary: json['statusAtBoundary'] as String?,
        snapshot: json['snapshot'] is Map<String, dynamic>
            ? json['snapshot'] as Map<String, dynamic>
            : null,
        historicalSnapshotAvailable:
            json['historicalSnapshotAvailable'] as bool? ?? true,
      );
}

/// The carryover listing, plus the two flags that describe the cut itself.
class CarryoverPage {
  const CarryoverPage({
    required this.page,
    this.boundary,
    this.isProvisional = false,
  });

  final Paged<CarryoverEntry> page;

  /// The instant of the cut. For a period that has not finished this is
  /// "as of now".
  final DateTime? boundary;

  /// True while the period is still running: this is a running snapshot, not
  /// the final hand-over.
  final bool isProvisional;

  factory CarryoverPage.fromJson(dynamic json) {
    final map = json is Map<String, dynamic> ? json : <String, dynamic>{};
    return CarryoverPage(
      page: Paged<CarryoverEntry>.fromJson(map, CarryoverEntry.fromJson),
      boundary: DateTime.tryParse(map['boundary'] as String? ?? ''),
      isProvisional: map['isProvisional'] as bool? ?? false,
    );
  }
}
