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
import '../../data/strings.dart';
import '../../widgets/filter_sheet.dart';
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
        emptyTitle: S.noOrders,
        emptyMessage: _basis == OrderBasis.created
            ? S.noOrdersCreated
            : S.noOrdersCash,
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
                        hintText: S.orderNumberHint,
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
                FilterButton(
                  compact: _status == null,
                  active: _status != null,
                  label: Labels.orderStatus(_status),
                  onTap: () async {
                    final choice = await showFilterSheet(
                      context,
                      title: S.status,
                      entries: Labels.orderStatuses,
                      selected: _status,
                      noneLabel: S.allStatuses,
                    );
                    if (choice != null) setState(() => _status = choice.value);
                  },
                ),
              ],
            ),
            if (_numberFilter != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  S.numberSearchNote,
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
              label: S.basisCreated,
              value: OrderBasis.created,
              icon: AppIcons.orders,
            ),
            _tab(
              label: S.basisCash,
              value: OrderBasis.cashReturned,
              icon: AppIcons.money,
            ),
          ],
        ),
      );

  Widget _tab({
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

/// One order in a list: number, state, when, who, and the total.
///
/// Deliberately four lines. Everything else — composition, participants,
/// stages, the money record — belongs on the full-screen card, not here,
/// where a dense block of figures is harder to scan than it is useful.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.showCashReturn = false,
  });

  final OrderSummary order;
  final VoidCallback onTap;

  /// On the cash-return listing the date that matters is the return, not the
  /// creation — and a historically reconciled order has none at all.
  final bool showCashReturn;

  @override
  Widget build(BuildContext context) {
    final created = Ashgabat.dateTimeLabel(order.createdAt);
    final returned = Ashgabat.dateTimeLabel(order.cashReturnedAt);
    final when = showCashReturn ? returned : created;
    final customer = (order.customerName ?? '').trim();

    return CardBox(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
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
                Labels.orderStatus(order.status),
                color: Labels.orderStatusColor(order.status),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              AppIcon(
                showCashReturn ? AppIcons.money : AppIcons.day,
                size: 14,
                color: when == null ? kWarningColor : kMutedColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  [
                    when ?? S.dateUnknown,
                    if (customer.isNotEmpty) customer,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: gilroyMedium,
                    fontSize: 12.5,
                    color: when == null ? kWarningColor : kMutedColor,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: kBorderColor),
          Row(
            children: [
              Text(
                S.total,
                style: const TextStyle(
                  fontFamily: gilroyRegular,
                  fontSize: 13,
                  color: kMutedColor,
                ),
              ),
              const Spacer(),
              Text(
                Fmt.money(order.total),
                style: const TextStyle(
                  fontFamily: gilroyBold,
                  fontSize: 15,
                  color: kBlackColor,
                ),
              ),
              const SizedBox(width: 8),
              const AppIcon(AppIcons.forward, size: 15, color: kMutedColor),
            ],
          ),
        ],
      ),
    );
  }
}
