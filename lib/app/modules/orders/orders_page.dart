import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_icons.dart';
import '../../constants/constants.dart';
import '../../data/accounting_service.dart';
import '../../data/app_state.dart';
import '../../data/ashgabat_time.dart';
import '../../data/formatting.dart';
import '../../data/labels.dart';
import '../../data/models/order.dart';
import '../../widgets/month_bar.dart';
import '../../widgets/paged_list.dart';
import '../../widgets/ui.dart';
import 'order_detail_page.dart';

/// Orders of a period, on one of the two bases.
///
/// The bases are different populations, not two sorts of one list: `created`
/// is the orders placed in the period, `cashReturned` is the money that came
/// back in it. An order created on the day shift can return its cash at
/// night, so switching the toggle legitimately changes which orders appear.
class OrdersPage extends StatefulWidget {
  const OrdersPage({
    super.key,
    required this.period,
    required this.basis,
    required this.title,
    this.subtitle,
  });

  final Period period;
  final OrderBasis basis;
  final String title;
  final String? subtitle;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late OrderBasis _basis = widget.basis;
  final _number = TextEditingController();
  int? _numberFilter;
  String? _status;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  /// Everything the current question depends on. Changing any of it resets
  /// the list to page 1 and discards the previous answer.
  String get _requestKey =>
      '${widget.period.query}|${_basis.value}|$_numberFilter|$_status';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.title,
      subtitle: widget.subtitle,
      child: PagedList<OrderSummary>(
        requestKey: _requestKey,
        storageKey: 'orders-${widget.period.query}',
        emptyTitle: 'Заказов нет',
        emptyMessage: _basis == OrderBasis.created
            ? 'В выбранном периоде заказы не создавались.'
            : 'В выбранном периоде деньги не возвращали.',
        fetch: (page) => App.instance.accounting.orders(
          period: widget.period,
          basis: _basis,
          page: page,
          number: _numberFilter,
          status: _status,
        ),
        header: _filters(),
        itemBuilder: (context, order, _) => OrderCard(
          order: order,
          showCashReturn: _basis == OrderBasis.cashReturned,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => OrderDetailPage(orderId: order.id),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filters() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BasisSwitch(
              basis: _basis,
              onChanged: (basis) => setState(() => _basis = basis),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _number,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _applyNumber(),
                      style: const TextStyle(
                          fontFamily: gilroySemiBold, fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Номер заказа',
                        hintStyle: const TextStyle(
                          fontFamily: gilroyRegular,
                          fontSize: 14,
                          color: kMutedColor,
                        ),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(10),
                          child: AppIcon(AppIcons.search, size: 18),
                        ),
                        suffixIcon: _numberFilter == null
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _number.clear();
                                  _applyNumber();
                                },
                                icon: const AppIcon(AppIcons.clear,
                                    size: 16, color: kMutedColor),
                              ),
                        border: const OutlineInputBorder(
                          borderRadius: borderRadius10,
                          borderSide: BorderSide(color: kBorderColor),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: borderRadius10,
                          borderSide: BorderSide(color: kBorderColor),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: borderRadius10,
                          borderSide: BorderSide(color: kPrimaryColor),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusButton(
                  status: _status,
                  onChanged: (status) => setState(() => _status = status),
                ),
              ],
            ),
            if (_numberFilter != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Поиск по номеру ограничен выбранным периодом.',
                  style: const TextStyle(
                    fontFamily: gilroyRegular,
                    fontSize: 11.5,
                    color: kMutedColor,
                  ),
                ),
              ),
          ],
        ),
      );

  void _applyNumber() {
    final parsed = int.tryParse(_number.text.trim());
    if (parsed == _numberFilter) return;
    setState(() => _numberFilter = parsed);
  }
}

class _BasisSwitch extends StatelessWidget {
  const _BasisSwitch({required this.basis, required this.onChanged});

  final OrderBasis basis;
  final ValueChanged<OrderBasis> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kBorderColor),
          borderRadius: borderRadius15,
        ),
        child: Row(
          children: [
            _tab(
              context,
              label: 'По созданию',
              value: OrderBasis.created,
              icon: AppIcons.orders,
            ),
            _tab(
              context,
              label: 'По возврату денег',
              value: OrderBasis.cashReturned,
              icon: AppIcons.money,
            ),
          ],
        ),
      );

  Widget _tab(
    BuildContext context, {
    required String label,
    required OrderBasis value,
    required List<List<dynamic>> icon,
  }) {
    final selected = value == basis;
    return Expanded(
      child: Material(
        color: selected ? kPrimaryColor : Colors.transparent,
        borderRadius: borderRadius10,
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: borderRadius10,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(icon,
                    size: 15, color: selected ? Colors.white : kMutedColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: gilroySemiBold,
                      fontSize: 12.5,
                      color: selected ? Colors.white : kMutedColor,
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
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({required this.status, required this.onChanged});

  final String? status;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        height: 44,
        decoration: BoxDecoration(
          color: status == null ? Colors.white : kPrimaryColor,
          border: Border.all(color: kBorderColor),
          borderRadius: borderRadius10,
        ),
        child: PopupMenuButton<String>(
          tooltip: 'Статус',
          padding: EdgeInsets.zero,
          onSelected: (value) => onChanged(value == '' ? null : value),
          itemBuilder: (context) => [
            const PopupMenuItem<String>(value: '', child: Text('Все статусы')),
            for (final entry in Labels.orderStatuses.entries)
              PopupMenuItem<String>(value: entry.key, child: Text(entry.value)),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(AppIcons.filter,
                    size: 17,
                    color: status == null ? kPrimaryColor : Colors.white),
                if (status != null) ...[
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 90),
                    child: Text(
                      Labels.orderStatus(status),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: gilroySemiBold,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

/// One order in a list. Cards rather than a wide table: this is a phone.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.showCashReturn = false,
    this.trailing,
  });

  final OrderSummary order;
  final VoidCallback onTap;
  final bool showCashReturn;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final created = Ashgabat.dateTimeLabel(order.createdAt, kLocale);
    final returned = Ashgabat.dateTimeLabel(order.cashReturnedAt, kLocale);
    return CardBox(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                Labels.orderStatus(order.status),
                color: Labels.orderStatusColor(order.status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InfoRow(
            label: 'Создан',
            value: created ?? kUnknown,
            icon: AppIcons.day,
          ),
          if (showCashReturn)
            InfoRow(
              label: 'Деньги вернули',
              // A historically reconciled order has no real hand-over date;
              // it is said so instead of being given today's.
              value: returned ?? 'дата неизвестна',
              valueColor: returned == null ? kWarningColor : kBlackColor,
              icon: AppIcons.money,
            ),
          InfoRow(
            label: 'Клиент',
            value: Fmt.text(order.customerName),
            icon: AppIcons.customer,
          ),
          if ((order.branchName ?? '').isNotEmpty)
            InfoRow(
              label: 'Кухня',
              value: order.branchName!,
              icon: AppIcons.branch,
            ),
          if ((order.deliveryEtrapName ?? '').isNotEmpty)
            InfoRow(
              label: 'Район',
              value: order.deliveryEtrapName!,
              icon: AppIcons.address,
            ),
          const Divider(height: 18, color: kBorderColor),
          InfoRow(label: 'Еда', value: Fmt.money(order.foodAmount)),
          InfoRow(label: 'Доставка', value: Fmt.money(order.deliveryFee)),
          InfoRow(
            label: 'Итого',
            value: Fmt.money(order.total),
            strong: true,
          ),
          if (trailing != null) ...[
            const SizedBox(height: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
