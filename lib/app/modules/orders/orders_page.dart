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
import '../../widgets/paged_list.dart';
import '../../widgets/ui.dart';
import 'order_detail_page.dart';

/// Orders of a period, on one of the two bases.
///
/// The bases are different populations, not two sorts of one list: `created`
/// is the orders placed in the period, `cashReturned` is the money that came
/// back in it. The page is opened on one of them by whoever links here and
/// does not offer to switch — a toggle that quietly changes which orders
/// exist was the most confusing control on it.
///
/// From the top: a search by order number, then one tab per status with how
/// many orders it holds, then the orders themselves. The counts are the
/// `total` the server reports for each status (one request each, limit 1),
/// so they follow the period and the number search, and a status with no
/// orders is not offered.
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
  final _number = TextEditingController();
  int? _numberFilter;
  String? _status;

  /// Orders per status for the current question; the `null` key is "all".
  /// Null while loading or when the counts could not be read.
  Map<String?, int>? _counts;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  /// Everything the list depends on. Changing any of it resets the list to
  /// page 1 and discards the previous answer.
  String get _requestKey =>
      '${widget.period.query}|${widget.basis.value}|$_numberFilter|$_status';

  Future<void> _loadCounts() async {
    final generation = ++_generation;
    setState(() => _counts = null);
    Future<MapEntry<String?, int>?> count(String? status) async {
      try {
        final page = await App.instance.accounting.orders(
          period: widget.period,
          basis: widget.basis,
          limit: 1,
          number: _numberFilter,
          status: status,
        );
        return MapEntry(status, page.total);
      } catch (_) {
        // A count is a convenience: the list below reports its own errors.
        return null;
      }
    }

    final results = await Future.wait([
      count(null),
      for (final status in Labels.orderStatuses.keys) count(status),
    ]);
    if (!mounted || generation != _generation) return;
    final counts = {
      for (final entry in results.whereType<MapEntry<String?, int>>())
        entry.key: entry.value,
    };
    setState(() => _counts = counts.containsKey(null) ? counts : null);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.title,
      subtitle: widget.subtitle,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: _search(),
          ),
          const SizedBox(height: 10),
          _StatusTabs(
            counts: _counts,
            selected: _status,
            onSelected: (status) => setState(() => _status = status),
          ),
          if (_numberFilter != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  S.numberSearchNote,
                  style: const TextStyle(
                    fontFamily: gilroyRegular,
                    fontSize: 11.5,
                    color: kMutedColor,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: PagedList<OrderSummary>(
              requestKey: _requestKey,
              storageKey: 'orders-${widget.period.query}',
              emptyTitle: S.noOrders,
              emptyMessage: widget.basis == OrderBasis.created
                  ? S.noOrdersCreated
                  : S.noOrdersCash,
              fetch: (page) => App.instance.accounting.orders(
                period: widget.period,
                basis: widget.basis,
                page: page,
                number: _numberFilter,
                status: _status,
              ),
              itemBuilder: (context, order, _) => OrderCard(
                order: order,
                showCashReturn: widget.basis == OrderBasis.cashReturned,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OrderDetailPage(orderId: order.id),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _search() => SizedBox(
        height: 46,
        child: TextField(
          controller: _number,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _applyNumber(),
          style: const TextStyle(fontFamily: gilroySemiBold, fontSize: 15),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            hintText: S.orderNumberHint,
            hintStyle: const TextStyle(
              fontFamily: gilroyRegular,
              fontSize: 15,
              color: kMutedColor,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.all(12),
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
              borderRadius: borderRadius15,
              borderSide: BorderSide(color: kBorderColor),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: borderRadius15,
              borderSide: BorderSide(color: kBorderColor),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: borderRadius15,
              borderSide: BorderSide(color: kPrimaryColor),
            ),
          ),
        ),
      );

  void _applyNumber() {
    final parsed = int.tryParse(_number.text.trim());
    if (parsed == _numberFilter) return;
    setState(() => _numberFilter = parsed);
    _loadCounts();
  }
}

/// «Все» and one tab per status that has orders, as one card of equal cells —
/// the count large, the status under it.
///
/// A row of chips has to scroll or to wrap raggedly; equal cells in a grid
/// always line up and every status that exists right now is on the screen at
/// once. Only statuses with orders are in it, so it is usually two rows.
class _StatusTabs extends StatelessWidget {
  const _StatusTabs({
    required this.counts,
    required this.selected,
    required this.onSelected,
  });

  final Map<String?, int>? counts;
  final String? selected;
  final ValueChanged<String?> onSelected;

  static const _columns = 3;
  static const _gap = 6.0;

  @override
  Widget build(BuildContext context) {
    final known = counts;
    final statuses = [
      for (final status in Labels.orderStatuses.keys)
        if (known == null
            ? status == selected
            : (known[status] ?? 0) > 0 || status == selected)
          status,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(_gap),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kBorderColor),
          borderRadius: borderRadius15,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width =
                (constraints.maxWidth - _gap * (_columns - 1)) / _columns;
            return Wrap(
              spacing: _gap,
              runSpacing: _gap,
              children: [
                SizedBox(
                  width: width,
                  child: _StatusCell(
                    label: S.allStatusesShort,
                    count: known?[null],
                    color: kPrimaryColor,
                    selected: selected == null,
                    onTap: () => onSelected(null),
                  ),
                ),
                for (final status in statuses)
                  SizedBox(
                    width: width,
                    child: _StatusCell(
                      label: Labels.orderStatus(status),
                      count: known?[status],
                      color: Labels.orderStatusColor(status),
                      selected: selected == status,
                      onTap: () => onSelected(status),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  const _StatusCell({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        // ignore: deprecated_member_use
        color: selected ? color.withOpacity(0.12) : kSurfaceColor,
        borderRadius: borderRadius10,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius10,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: borderRadius10,
              border: Border.all(
                color: selected ? color : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == null ? kDash : Fmt.count(count),
                  style: TextStyle(
                    fontFamily: gilroyBold,
                    fontSize: 18,
                    height: 1.1,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: selected ? gilroySemiBold : gilroyMedium,
                        fontSize: 11.5,
                        color: selected ? kBlackColor : kMutedColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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
