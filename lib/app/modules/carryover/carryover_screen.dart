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

/// Unfinished orders at the edge of a day — «Принято с прошлого дня» and
/// «Передано на следующий день».
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

  /// The cut itself, in one quiet line — its date is the only thing this
  /// header has to say.
  Widget _header() => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardBox(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  AppIconBadge(
                    widget.incoming ? AppIcons.carryIn : AppIcons.carryOut,
                    color: kWarningColor,
                    size: 44,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.boundary,
                          style: const TextStyle(
                            fontFamily: gilroyRegular,
                            fontSize: 13,
                            color: kMutedColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Ashgabat.dateTimeLabel(_boundary) ?? kUnknown,
                          style: const TextStyle(
                            fontFamily: gilroyBold,
                            fontSize: 17,
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

/// One carried order, read left to right: which order and how much, then
/// where it stood at the cut and where it stands now.
///
/// The colour strip on the left is the order's status **now**, so a glance
/// down the list says how many are still open. The snapshot's amount is the
/// one figure that is historical — everything else on the order is on its
/// own screen.
class _CarryoverCard extends StatelessWidget {
  const _CarryoverCard({required this.entry});

  final CarryoverEntry entry;

  @override
  Widget build(BuildContext context) {
    final order = entry.order;
    final snapshot = entry.snapshot;
    final total = snapshot == null ? null : _amount(snapshot['total']);
    final items = snapshot?['items'];
    final accent = Labels.orderStatusColor(order.status);
    final changed = (entry.statusAtBoundary ?? '').toUpperCase() !=
        (order.status ?? '').toUpperCase();

    return Material(
      color: Colors.white,
      borderRadius: borderRadius15,
      child: InkWell(
        borderRadius: borderRadius15,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => OrderDetailPage(orderId: order.id),
          ),
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: borderRadius15,
            border: Border.all(color: kBorderColor),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Fmt.orderNumber(order.number),
                                    style: const TextStyle(
                                      fontFamily: gilroyBold,
                                      fontSize: 18,
                                      color: kBlackColor,
                                    ),
                                  ),
                                  if (items is List) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '${S.itemsCount}: ${items.length}',
                                      style: const TextStyle(
                                        fontFamily: gilroyRegular,
                                        fontSize: 12.5,
                                        color: kMutedColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (total != null)
                              Text(
                                Fmt.money(total),
                                style: const TextStyle(
                                  fontFamily: gilroyBold,
                                  fontSize: 17,
                                  color: kBlackColor,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatusStep(
                                caption: S.wasLabel,
                                status: entry.statusAtBoundary,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: AppIcon(
                                AppIcons.forward,
                                size: 16,
                                color: changed ? kPrimaryColor : kBorderColor,
                              ),
                            ),
                            Expanded(
                              child: _StatusStep(
                                caption: S.nowLabel,
                                status: order.status,
                              ),
                            ),
                          ],
                        ),
                        if (!entry.historicalSnapshotAvailable) ...[
                          const SizedBox(height: 10),
                          NoticeBox(S.noSnapshotNote),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static double? _amount(dynamic value) =>
      value is num ? value.toDouble() : null;
}

/// A small caption over a status pill: «Было» / «Сейчас».
class _StatusStep extends StatelessWidget {
  const _StatusStep({required this.caption, required this.status});

  final String caption;
  final String? status;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caption,
            style: const TextStyle(
              fontFamily: gilroyMedium,
              fontSize: 11.5,
              color: kMutedColor,
            ),
          ),
          const SizedBox(height: 4),
          Pill(
            Labels.orderStatus(status),
            color: Labels.orderStatusColor(status),
          ),
        ],
      );
}
