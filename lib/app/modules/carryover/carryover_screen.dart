import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/constants.dart';
import '../../data/accounting_service.dart';
import '../../data/app_state.dart';
import '../../data/ashgabat_time.dart';
import '../../data/formatting.dart';
import '../../data/labels.dart';
import '../../data/models/carryover.dart';
import '../../data/models/paged.dart';
import '../../data/strings.dart';
import '../../widgets/paged_list.dart';
import '../../widgets/ui.dart';
import '../orders/order_detail_page.dart';

/// Unfinished orders at the edge of a period — «Принято от смены» and
/// «Передано смене».
///
/// Carrying an order over creates neither a second order nor a second
/// payment: this is the same order, seen from the boundary.
class CarryoverScreen extends StatefulWidget {
  const CarryoverScreen({
    super.key,
    required this.period,
    required this.incoming,
    this.subtitle,
  });

  final Period period;

  /// `direction=in` — what the period received; `out` — what it handed on.
  final bool incoming;
  final String? subtitle;

  @override
  State<CarryoverScreen> createState() => _CarryoverScreenState();
}

class _CarryoverScreenState extends State<CarryoverScreen> {
  DateTime? _boundary;
  bool _provisional = false;

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: widget.incoming ? S.carryIn : S.carryOut,
        subtitle: widget.subtitle,
        child: PagedList<CarryoverEntry>(
          requestKey: '${widget.period.query}|${widget.incoming}',
          storageKey: 'carryover-${widget.period.query}-${widget.incoming}',
          emptyTitle: S.noCarryover,
          emptyMessage: widget.incoming ? S.noCarryIn : S.noCarryOut,
          fetch: _fetch,
          header: _header(),
          itemBuilder: (context, entry, _) => _CarryoverCard(entry: entry),
        ),
      );

  Future<Paged<CarryoverEntry>> _fetch(int page) async {
    final result = await App.instance.accounting.carryover(
      period: widget.period,
      incoming: widget.incoming,
      page: page,
    );
    if (mounted &&
        (result.boundary != _boundary ||
            result.isProvisional != _provisional)) {
      setState(() {
        _boundary = result.boundary;
        _provisional = result.isProvisional;
      });
    }
    return result.page;
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardBox(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  AppIconBadge(
                    widget.incoming ? AppIcons.carryIn : AppIcons.carryOut,
                    color: kWarningColor,
                    size: 38,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.boundary,
                          style: const TextStyle(
                            fontFamily: gilroyRegular,
                            fontSize: 12,
                            color: kMutedColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Ashgabat.dateTimeLabel(_boundary) ?? kUnknown,
                          style: const TextStyle(
                            fontFamily: gilroySemiBold,
                            fontSize: 14,
                            color: kBlackColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_provisional) ...[
              const SizedBox(height: 10),
              NoticeBox(S.provisionalNote),
            ],
          ],
        ),
      );
}

/// One carried order: which order, where it stood at the cut, where it
/// stands now. The snapshot's money is a single line; the rest is on the
/// order's own screen.
class _CarryoverCard extends StatelessWidget {
  const _CarryoverCard({required this.entry});

  final CarryoverEntry entry;

  @override
  Widget build(BuildContext context) {
    final order = entry.order;
    final snapshot = entry.snapshot;
    final total = snapshot == null ? null : _amount(snapshot['total']);
    final items = snapshot?['items'];
    return CardBox(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OrderDetailPage(orderId: order.id),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  Fmt.orderNumber(order.number),
                  style: const TextStyle(
                    fontFamily: gilroyBold,
                    fontSize: 16,
                    color: kBlackColor,
                  ),
                ),
              ),
              Pill(
                Labels.orderStatus(entry.statusAtBoundary),
                color: Labels.orderStatusColor(entry.statusAtBoundary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // The status now can differ from the status at the cut; saying so
          // in one line is the whole point of this list.
          Row(
            children: [
              const AppIcon(AppIcons.transition, size: 14, color: kMutedColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${S.statusNow}: ${Labels.orderStatus(order.status)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: gilroyMedium,
                    fontSize: 12.5,
                    color: kMutedColor,
                  ),
                ),
              ),
            ],
          ),
          if (!entry.historicalSnapshotAvailable) ...[
            const SizedBox(height: 10),
            NoticeBox(S.noSnapshotNote),
          ] else if (snapshot != null) ...[
            const Divider(height: 16, color: kBorderColor),
            Row(
              children: [
                Text(
                  S.atBoundary,
                  style: const TextStyle(
                    fontFamily: gilroyRegular,
                    fontSize: 12.5,
                    color: kMutedColor,
                  ),
                ),
                const Spacer(),
                Text(
                  [
                    Fmt.money(total),
                    if (items is List) '${items.length} · ${S.itemsCount}',
                  ].join(' · '),
                  style: const TextStyle(
                    fontFamily: gilroySemiBold,
                    fontSize: 13,
                    color: kBlackColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static double? _amount(dynamic value) =>
      value is num ? value.toDouble() : null;
}
