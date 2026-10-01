import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/constants.dart';
import '../../data/accounting_service.dart';
import '../../data/app_state.dart';
import '../../data/labels.dart';
import '../../data/models/audit.dart';
import '../../data/strings.dart';
import '../../widgets/filter_sheet.dart';
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
                  child: FilterButton(
                    icon: AppIcons.journal,
                    label: _action == null
                        ? S.allActions
                        : Labels.auditAction(_action),
                    active: _action != null,
                    onTap: () async {
                      final choice = await showFilterSheet(
                        context,
                        title: S.chooseAction,
                        entries: Labels.auditActions,
                        selected: _action,
                        noneLabel: S.allActions,
                        iconFor: Labels.auditIcon,
                      );
                      if (choice != null) {
                        setState(() => _action = choice.value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterButton(
                    icon: AppIcons.details,
                    label: _entityType == null
                        ? S.allSections
                        : Labels.entity(_entityType),
                    active: _entityType != null,
                    onTap: () async {
                      final choice = await showFilterSheet(
                        context,
                        title: S.chooseSection,
                        entries: Labels.entities,
                        selected: _entityType,
                        noneLabel: S.allSections,
                      );
                      if (choice != null) {
                        setState(() => _entityType = choice.value);
                      }
                    },
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

