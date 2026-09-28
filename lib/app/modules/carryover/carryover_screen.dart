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
import '../../widgets/month_bar.dart';
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
        title: widget.incoming ? 'Принято от смены' : 'Передано смене',
        subtitle: widget.subtitle,
        child: PagedList<CarryoverEntry>(
          requestKey: '${widget.period.query}|${widget.incoming}',
          storageKey: 'carryover-${widget.period.query}-${widget.incoming}',
          emptyTitle: 'Переходящих заказов нет',
          emptyMessage: widget.incoming
              ? 'На входе периода незавершённых заказов не было.'
              : 'На выходе периода незавершённых заказов не осталось.',
          fetch: (page) => _fetch(page),
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
              child: Column(
                children: [
                  InfoRow(
                    label: 'Граница',
                    value: Ashgabat.dateTimeLabel(_boundary, kLocale) ??
                        kUnknown,
                    icon: AppIcons.day,
                  ),
                  InfoRow(
                    label: 'Переходят',
                    value: 'Готовится, готов, у курьера, в доставке, доставлен',
                    icon: widget.incoming
                        ? AppIcons.carryIn
                        : AppIcons.carryOut,
                  ),
                ],
              ),
            ),
            if (_provisional) ...[
              const SizedBox(height: 10),
              const NoticeBox(
                'Период ещё не завершён: это срез на текущий момент, а не '
                'окончательная передача.',
              ),
            ],
          ],
        ),
      );
}

class _CarryoverCard extends StatelessWidget {
  const _CarryoverCard({required this.entry});

  final CarryoverEntry entry;

  @override
  Widget build(BuildContext context) {
    final order = entry.order;
    final snapshot = entry.snapshot;
    return CardBox(
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
              const AppIcon(AppIcons.forward, size: 16, color: kMutedColor),
            ],
          ),
          const SizedBox(height: 8),
          InfoRow(
            label: 'Статус на границе',
            value: Labels.orderStatus(entry.statusAtBoundary),
            valueColor: Labels.orderStatusColor(entry.statusAtBoundary),
          ),
          InfoRow(
            label: 'Статус сейчас',
            value: Labels.orderStatus(order.status),
            valueColor: Labels.orderStatusColor(order.status),
          ),
          InfoRow(
            label: 'Создан',
            value: Ashgabat.dateTimeLabel(order.createdAt, kLocale) ?? kUnknown,
            icon: AppIcons.day,
          ),
          const Divider(height: 18, color: kBorderColor),
          if (!entry.historicalSnapshotAvailable)
            const NoticeBox(
              'Снимок на границе не сохранялся — исторический состав и суммы '
              'этого заказа показать нельзя.',
            )
          else if (snapshot != null) ...[
            const Text(
              'На границе смены',
              style: TextStyle(
                fontFamily: gilroySemiBold,
                fontSize: 13,
                color: kBlackColor,
              ),
            ),
            const SizedBox(height: 4),
            InfoRow(
              label: 'Сумма еды',
              value: Fmt.money(_amount(snapshot['foodAmount'])),
            ),
            InfoRow(
              label: 'Итого',
              value: Fmt.money(_amount(snapshot['total'])),
            ),
            InfoRow(
              label: 'Позиций',
              value: Fmt.count(
                  snapshot['items'] is List ? (snapshot['items'] as List).length : null),
            ),
            if (snapshot['address'] != null)
              InfoRow(
                label: 'Адрес',
                value: snapshot['address'].toString(),
                icon: AppIcons.address,
              ),
            const SizedBox(height: 6),
            const Text(
              'Текущие значения заказа могут отличаться — они показаны в '
              'карточке заказа.',
              style: TextStyle(
                fontFamily: gilroyRegular,
                fontSize: 11.5,
                color: kMutedColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static double? _amount(dynamic value) =>
      value is num ? value.toDouble() : null;
}
