import 'dart:convert';

import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/constants.dart';
import '../../data/ashgabat_time.dart';
import '../../data/formatting.dart';
import '../../data/labels.dart';
import '../../data/models/audit.dart';
import '../../data/strings.dart';
import '../../widgets/ui.dart';

/// One line of «Кто что сделал».
///
/// The main line reads **action → order № → who → when → what changed**, and
/// tapping it opens the before/after comparison. An event with no order
/// leaves the number out rather than drawing «Заказ №null».
class AuditTile extends StatelessWidget {
  const AuditTile({
    super.key,
    required this.entry,
    this.onOpenOrder,
  });

  final AuditEntry entry;

  /// Journal rows jump to the order; the order's own history does not need
  /// to jump back to itself.
  final void Function(String orderId)? onOpenOrder;

  @override
  Widget build(BuildContext context) {
    final when = Ashgabat.dateTimeLabel(entry.createdAt);
    final actor = entry.actor?.fullName;
    return CardBox(
      onTap: () => showAuditDetails(context, entry, onOpenOrder: onOpenOrder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIconBadge(Labels.auditIcon(entry.action), size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Labels.auditAction(entry.action),
                      style: const TextStyle(
                        fontFamily: gilroySemiBold,
                        fontSize: 14.5,
                        color: kBlackColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (entry.orderNumber != null)
                          Text(
                            Fmt.orderNumber(entry.orderNumber),
                            style: const TextStyle(
                              fontFamily: gilroySemiBold,
                              fontSize: 12.5,
                              color: kPrimaryColor,
                            ),
                          ),
                        Text(
                          actor ?? kUnknown,
                          style: const TextStyle(
                            fontFamily: gilroyMedium,
                            fontSize: 12.5,
                            color: kBlackColor,
                          ),
                        ),
                        Text(
                          when ?? kUnknown,
                          style: const TextStyle(
                            fontFamily: gilroyRegular,
                            fontSize: 12,
                            color: kMutedColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const AppIcon(AppIcons.forward, size: 16, color: kMutedColor),
            ],
          ),
          if (entry.hasComparison) ...[
            const SizedBox(height: 8),
            Text(
              S.changedFields(
                  entry.changedFields.map(Labels.field).join(', ')),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: gilroyRegular,
                fontSize: 12,
                color: kMutedColor,
              ),
            ),
          ] else if (!Labels.isKnownAction(entry.action)) ...[
            const SizedBox(height: 8),
            Text(
              S.eventNamed(entry.action ?? kUnknown),
              style: const TextStyle(
                fontFamily: gilroyRegular,
                fontSize: 12,
                color: kMutedColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// «До изменения / После изменения», with the raw payload kept behind a
/// technical section rather than thrown away.
Future<void> showAuditDetails(
  BuildContext context,
  AuditEntry entry, {
  void Function(String orderId)? onOpenOrder,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (context, controller) => _AuditDetails(
          entry: entry,
          controller: controller,
          onOpenOrder: onOpenOrder,
        ),
      ),
    );

class _AuditDetails extends StatelessWidget {
  const _AuditDetails({
    required this.entry,
    required this.controller,
    this.onOpenOrder,
  });

  final AuditEntry entry;
  final ScrollController controller;
  final void Function(String orderId)? onOpenOrder;

  @override
  Widget build(BuildContext context) {
    final fields = entry.changedFields;
    final orderId = entry.orderId;
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Center(
          child: Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: kBorderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          Labels.auditAction(entry.action),
          style: const TextStyle(
            fontFamily: gilroyBold,
            fontSize: 19,
            color: kBlackColor,
          ),
        ),
        const SizedBox(height: 12),
        CardBox(
          child: Column(
            children: [
              if (entry.orderNumber != null)
                InfoRow(
                  label: S.order,
                  value: Fmt.orderNumber(entry.orderNumber),
                  icon: AppIcons.orders,
                ),
              InfoRow(
                label: S.staff,
                value: entry.actor?.fullName ?? kUnknown,
                icon: AppIcons.person,
              ),
              InfoRow(
                label: S.time,
                value: Ashgabat.dateTimeLabel(entry.createdAt) ??
                    kUnknown,
                icon: AppIcons.day,
              ),
              InfoRow(
                label: S.section,
                value: Labels.entity(entry.entityType),
                icon: AppIcons.details,
              ),
            ],
          ),
        ),
        if (orderId != null && onOpenOrder != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 46,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: kPrimaryColor,
                shape:
                    const RoundedRectangleBorder(borderRadius: borderRadius15),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onOpenOrder!(orderId);
              },
              icon: const AppIcon(AppIcons.orders,
                  size: 18, color: Colors.white),
              label: Text(
                S.openOrder,
                style: const TextStyle(
                    fontFamily: gilroySemiBold, color: Colors.white),
              ),
            ),
          ),
        ],
        if (!entry.hasComparison) ...[
          const SizedBox(height: 14),
          NoticeBox(S.noComparison),
        ] else ...[
          SectionTitle(S.whatChanged, icon: AppIcons.edited),
          for (final field in fields)
            if (field == 'items')
              _ItemsComparison(entry: entry)
            else
              _FieldComparison(
                label: Labels.field(field),
                before: _render(entry, field, entry.before?[field]),
                after: _render(entry, field, entry.after?[field]),
              ),
        ],
        if (entry.relatedActors.isNotEmpty) ...[
          SectionTitle(S.recordParticipants, icon: AppIcons.person),
          CardBox(
            child: Column(
              children: [
                for (final actor in entry.relatedActors)
                  InfoRow(
                    // The role is whatever the account says now, not what it
                    // said when the action happened.
                    label: actor.role ?? S.staff,
                    value: actor.fullName ?? kUnknown,
                    icon: AppIcons.person,
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        _TechnicalDetails(entry: entry),
      ],
    );
  }

  /// A saved value in the words the screen uses. Ids become names where the
  /// log carried them; everything else keeps its own shape.
  static String _render(AuditEntry entry, String field, dynamic value) {
    if (value == null) return S.empty;
    switch (field) {
      case 'status':
        return Labels.orderStatus(value.toString());
      case 'total':
      case 'subtotal':
      case 'discount':
      case 'foodAmount':
      case 'deliveryFee':
      case 'price':
      case 'declaredAmount':
      case 'expectedAmount':
        return value is num ? Fmt.money(value.toDouble()) : value.toString();
      case 'preparationMinutes':
        return value is num ? Fmt.minutes(value.toInt()) : value.toString();
      case 'courierId':
      case 'cookId':
      case 'actorId':
        return entry.actorName(value.toString()) ?? value.toString();
      default:
        if (value is bool) return value ? S.yes : S.no;
        if (value is Map || value is List) {
          return const JsonEncoder.withIndent('  ').convert(value);
        }
        return value.toString();
    }
  }
}

class _FieldComparison extends StatelessWidget {
  const _FieldComparison({
    required this.label,
    required this.before,
    required this.after,
  });

  final String label;
  final String before;
  final String after;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: gilroySemiBold,
                  fontSize: 14,
                  color: kBlackColor,
                ),
              ),
              const SizedBox(height: 8),
              _Side(
                title: S.beforeChange,
                value: before,
                color: kNegativeColor,
              ),
              const SizedBox(height: 6),
              _Side(
                title: S.afterChange,
                value: after,
                color: kPositiveColor,
              ),
            ],
          ),
        ),
      );
}

class _Side extends StatelessWidget {
  const _Side({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: color.withOpacity(0.06),
          borderRadius: borderRadius10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: gilroyMedium,
                fontSize: 11.5,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontFamily: gilroySemiBold,
                fontSize: 13,
                color: kBlackColor,
              ),
            ),
          ],
        ),
      );
}

/// The composition is compared line by line, which is the only comparison
/// that answers "what actually changed in this order".
class _ItemsComparison extends StatelessWidget {
  const _ItemsComparison({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final before = _lines(entry.before?['items']);
    final after = _lines(entry.after?['items']);
    final names = {...before.keys, ...after.keys}.toList()..sort();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CardBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Labels.field('items'),
              style: TextStyle(
                fontFamily: gilroySemiBold,
                fontSize: 14,
                color: kBlackColor,
              ),
            ),
            const SizedBox(height: 4),
            for (final name in names)
              () {
                final was = before[name];
                final now = after[name];
                final color = was == null
                    ? kPositiveColor
                    : now == null
                        ? kNegativeColor
                        : was == now
                            ? kMutedColor
                            : kWarningColor;
                final text = was == null
                    ? '${S.changedItemAdded} × ${now ?? 0}'
                    : now == null
                        ? S.itemRemoved('$was')
                        : was == now
                            ? S.itemUnchanged('$now')
                            : '× $was → × $now';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppIcon(AppIcons.dish, size: 15, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontFamily: gilroySemiBold,
                            fontSize: 13,
                            color: kBlackColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        text,
                        style: TextStyle(
                          fontFamily: gilroyMedium,
                          fontSize: 12,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }(),
          ],
        ),
      ),
    );
  }

  static Map<String, int> _lines(dynamic value) {
    final result = <String, int>{};
    if (value is! List) return result;
    for (final line in value) {
      if (line is! Map) continue;
      final name = [
        line['productName'] ?? line['name'],
        line['variantName'],
      ].whereType<String>().where((p) => p.trim().isNotEmpty).join(' · ');
      final quantity = (line['quantity'] as num?)?.toInt() ?? 1;
      final key = name.isEmpty ? kUnknown : name;
      result[key] = (result[key] ?? 0) + quantity;
    }
    return result;
  }
}

/// UUIDs and the original payload, folded away. Secret metadata keys are
/// hidden by the server before they ever reach this screen.
class _TechnicalDetails extends StatelessWidget {
  const _TechnicalDetails({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) => Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: Text(
            S.technicalDetails,
            style: TextStyle(
              fontFamily: gilroySemiBold,
              fontSize: 13.5,
              color: kMutedColor,
            ),
          ),
          children: [
            CardBox(
              color: kSurfaceColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    'id: ${entry.id}\n'
                    'action: ${entry.action ?? kDash}\n'
                    'entityType: ${entry.entityType ?? kDash}\n'
                    'entityId: ${entry.entityId ?? kDash}\n'
                    'orderId: ${entry.orderId ?? kDash}\n'
                    'actorId: ${entry.actor?.id ?? kDash}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      color: kBlackColor,
                    ),
                  ),
                  if (entry.metadata != null) ...[
                    const SizedBox(height: 10),
                    SelectableText(
                      const JsonEncoder.withIndent('  ')
                          .convert(entry.metadata),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        color: kBlackColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}
