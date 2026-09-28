import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/constants.dart';
import '../../data/accounting_service.dart';
import '../../data/app_state.dart';
import '../../data/labels.dart';
import '../../data/models/audit.dart';
import '../../data/strings.dart';
import '../../widgets/paged_list.dart';
import '../../widgets/ui.dart';
import '../orders/order_detail_page.dart';
import 'audit_tile.dart';

/// «Кто что сделал» for a period.
///
/// The log records business actions, not taps or navigation. It supports an
/// inspection; it does not replace counting the cash and the stock, or
/// controlling who can reach the database itself — which is why the screen
/// says so at the bottom rather than presenting itself as proof.
class AuditPage extends StatefulWidget {
  const AuditPage({
    super.key,
    required this.period,
    required this.title,
    this.subtitle,
  });

  final Period period;
  final String title;
  final String? subtitle;

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  String? _action;
  String? _entityType;

  String get _requestKey =>
      '${widget.period.query}|$_action|$_entityType';

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: widget.title,
        subtitle: widget.subtitle,
        child: PagedList<AuditEntry>(
          requestKey: _requestKey,
          storageKey: 'audit-${widget.period.query}',
          emptyTitle: S.noActions,
          emptyMessage: S.noActionsMessage,
          fetch: (page) => App.instance.accounting.audit(
            period: widget.period,
            page: page,
            action: _action,
            entityType: _entityType,
          ),
          header: _filters(),
          itemBuilder: (context, entry, _) => AuditTile(
            entry: entry,
            onOpenOrder: (orderId) => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => OrderDetailPage(orderId: orderId),
              ),
            ),
          ),
        ),
      );

  Widget _filters() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _FilterMenu(
                    icon: AppIcons.journal,
                    label: _action == null
                        ? S.allActions
                        : Labels.auditAction(_action),
                    active: _action != null,
                    entries: {
                      for (final entry in Labels.auditActions.entries)
                        entry.key: entry.value,
                    },
                    onSelected: (value) => setState(() => _action = value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterMenu(
                    icon: AppIcons.details,
                    label: _entityType == null
                        ? S.allSections
                        : Labels.entity(_entityType),
                    active: _entityType != null,
                    entries: Labels.entities,
                    onSelected: (value) =>
                        setState(() => _entityType = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            NoticeBox(S.journalNote, color: kPrimaryColor),
          ],
        ),
      );
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.icon,
    required this.label,
    required this.active,
    required this.entries,
    required this.onSelected,
  });

  final List<List<dynamic>> icon;
  final String label;
  final bool active;

  /// Exact values, as the API matches them.
  final Map<String, String> entries;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => Container(
        height: 46,
        decoration: BoxDecoration(
          color: active ? kPrimaryColor : Colors.white,
          border: Border.all(color: kBorderColor),
          borderRadius: borderRadius10,
        ),
        child: PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          onSelected: (value) => onSelected(value.isEmpty ? null : value),
          itemBuilder: (context) => [
            PopupMenuItem<String>(value: '', child: Text(S.noFilter)),
            for (final entry in entries.entries)
              PopupMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                AppIcon(icon,
                    size: 16, color: active ? Colors.white : kPrimaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: gilroySemiBold,
                      fontSize: 12.5,
                      color: active ? Colors.white : kBlackColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
