/// The API's paging envelope: `{items, total, page, limit}`.
///
/// `page` starts at 1 and `limit` is 25 by default, 100 at most. The first
/// page is never the whole report, so [hasMore] is what the lists trust
/// rather than "fewer items than asked for".
class Paged<T> {
  const Paged({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<T> items;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;

  const Paged.empty()
      : items = const [],
        total = 0,
        page = 1,
        limit = 25;

  factory Paged.fromJson(
    dynamic json,
    T Function(Map<String, dynamic>) item,
  ) {
    if (json is! Map<String, dynamic>) return Paged<T>.empty();
    final raw = json['items'];
    return Paged<T>(
      items: raw is List
          ? raw.whereType<Map<String, dynamic>>().map(item).toList()
          : const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 25,
    );
  }

  Paged<T> merge(Paged<T> next) => Paged<T>(
        items: [...items, ...next.items],
        total: next.total,
        page: next.page,
        limit: next.limit,
      );
}

/// A person who did something, as the audit and order details name them.
///
/// The id is permanent; the name and role are whatever the account says
/// **now**, not what it said when the action happened. Both names are
/// nullable and are shown as "unknown" rather than filled in.
class Actor {
  const Actor({required this.id, this.firstName, this.lastName, this.role});

  final String id;
  final String? firstName;
  final String? lastName;
  final String? role;

  String? get fullName {
    final parts = [firstName, lastName]
        .whereType<String>()
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? null : parts.join(' ');
  }

  static Actor? fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    if (id == null) return null;
    return Actor(
      id: id.toString(),
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      role: json['role'] as String?,
    );
  }
}

double? asDouble(dynamic value) => (value as num?)?.toDouble();
int? asInt(dynamic value) => (value as num?)?.toInt();
