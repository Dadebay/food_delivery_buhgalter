import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/constants.dart';
import '../../data/accounting_service.dart';
import '../../data/app_state.dart';
import '../../data/ashgabat_time.dart';
import '../../data/formatting.dart';
import '../../data/models/overview.dart';
import '../../data/strings.dart';
import '../../widgets/async_loader.dart';
import '../../widgets/daily_charts.dart';
import '../../widgets/expandable_list.dart';
import '../../widgets/language_action.dart';
import '../../widgets/month_picker.dart';
import '../../widgets/state_views.dart';
import '../../widgets/ui.dart';
import '../orders/orders_page.dart';

/// The month, built from the three range calls the spec prescribes.
///
/// There is no `/monthly` endpoint: `overview`, `report` and `shifts` are
/// asked in parallel, once, and the three tabs read that one answer. Money,
/// orders and the breakdowns are separate questions, and stacking them into
/// a single scroll made the page long enough that the charts were never seen.
class MonthPage extends StatefulWidget {
  const MonthPage({super.key});

  @override
  State<MonthPage> createState() => _MonthPageState();
}

class _MonthPageState extends State<MonthPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final period = App.instance.period;
    return AnimatedBuilder(
      animation: Listenable.merge([period, App.instance.language]),
      builder: (context, _) => AppScaffold(
        title: S.charts,
        subtitle: Ashgabat.monthLabel(period.month),
        actions: const [MonthAction(), LanguageAction(), SizedBox(width: 4)],
        bottom: PillTabBar(
          controller: _tabs,
          // Three short labels fit a 320 px screen without scrolling.
          labels: [S.tabMoney, S.tabOrders, S.tabBreakdown],
        ),
        child: AsyncLoader<MonthBundle>(
          requestKey: '${period.fromDate}:${period.toDate}',
          request: () => App.instance.accounting
              .month(fromDate: period.fromDate, toDate: period.toDate),
          builder: (context, bundle, reload) => TabBarView(
            controller: _tabs,
            children: [
              _Tab(onRefresh: reload, children: _money(context, bundle, period)),
              _Tab(onRefresh: reload, children: _orders(context, bundle, period)),
              _Tab(onRefresh: reload, children: _breakdown(bundle)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Money ───────────────────────────────────────────────────────────────
  List<Widget> _money(
      BuildContext context, MonthBundle bundle, PeriodStore period) {
    final report = bundle.report.summary;
    final discrepancy = report.handoffDiscrepancy;
    return [
      HeadlineCard(
        icon: AppIcons.collected,
        accent: kPositiveColor,
        caption: S.received,
        value: Fmt.money(report.collectedAmount),
        rows: [
          HeadlineRow(S.handedOver, Fmt.money(report.submittedAmount)),
          HeadlineRow(S.confirmedMoney, Fmt.money(report.confirmedAmount),
              color: kPositiveColor),
          HeadlineRow(S.outstanding, Fmt.money(report.outstandingAmount),
              color: kWarningColor),
          HeadlineRow(
              S.declaredByPackets, Fmt.money(report.declaredHandoffAmount)),
          if (discrepancy != null && discrepancy != 0)
            HeadlineRow(
              S.discrepancy,
              Fmt.signedMoney(discrepancy),
              color: discrepancy < 0 ? kNegativeColor : kWarningColor,
            ),
        ],
      ),
      if (discrepancy != null && discrepancy != 0) ...[
        const SizedBox(height: 10),
        NoticeBox(S.discrepancyNote, color: kPrimaryColor),
      ],
      const SizedBox(height: 14),
      DailyMoneyChart(
        points: alignMoney(period.month, bundle.report.daily),
        onDayTap: (day) => _openDay(context, day, OrderBasis.cashReturned),
      ),
    ];
  }

  // ── Orders ──────────────────────────────────────────────────────────────
  List<Widget> _orders(
      BuildContext context, MonthBundle bundle, PeriodStore period) {
    final overview = bundle.overview.summary;
    return [
      HeadlineCard(
        icon: AppIcons.orders,
        accent: kPrimaryColor,
        caption: S.createdOrders,
        value: Fmt.count(overview.createdOrders),
        rows: [
          HeadlineRow(S.cancelledNow, Fmt.count(overview.cancelledOrders),
              color: kNegativeColor),
          HeadlineRow(S.cancelShare, Fmt.percent(overview.cancellationRate)),
          HeadlineRow(S.cancelEvents, Fmt.count(overview.cancellationEvents)),
          HeadlineRow(S.editEvents, Fmt.count(overview.editEvents)),
          HeadlineRow(S.foodAmount, Fmt.money(overview.foodAmount)),
        ],
      ),
      const SizedBox(height: 14),
      DailyOrdersChart(
        points: alignOrders(period.month, bundle.overview.daily),
        onDayTap: (day) => _openDay(context, day, OrderBasis.created),
      ),
    ];
  }

  // ── Breakdowns ──────────────────────────────────────────────────────────
  List<Widget> _breakdown(MonthBundle bundle) {
    final overview = bundle.overview;
    final blocks = <Widget>[
      if (overview.districts.isNotEmpty) ...[
        SectionTitle(S.districts, icon: AppIcons.address),
        _CountList(rows: overview.districts),
      ],
      if (overview.branches.isNotEmpty) ...[
        SectionTitle(S.kitchens, icon: AppIcons.branch),
        _CountList(rows: overview.branches),
      ],
      if (overview.cancellationReasons.isNotEmpty) ...[
        SectionTitle(S.cancelReasons, icon: AppIcons.cancelled),
        _CountList(rows: overview.cancellationReasons),
      ],
      if (overview.mostOrderedProducts.isNotEmpty) ...[
        SectionTitle(S.mostOrdered, icon: AppIcons.ranking),
        _ProductList(rows: overview.mostOrderedProducts),
      ],
      if (overview.leastOrderedProducts.isNotEmpty) ...[
        SectionTitle(S.leastOrdered, icon: AppIcons.ranking),
        _ProductList(rows: overview.leastOrderedProducts),
        const SizedBox(height: 8),
        Text(
          S.demandNote,
          style: const TextStyle(
            fontFamily: gilroyRegular,
            fontSize: 11.5,
            color: kMutedColor,
          ),
        ),
      ],
    ];
    // An empty answer is a state of its own, not a failure and not a blank.
    return blocks.isEmpty ? [const EmptyView()] : blocks;
  }

  /// A tap on a day opens that day's orders on the basis of the chart that
  /// was tapped — creation for the order chart, cash return for the money
  /// chart.
  void _openDay(BuildContext context, DateTime day, OrderBasis basis) {
    final date = Ashgabat.date(day);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrdersPage(
          period: Period.range(date, date),
          basis: basis,
          title: Ashgabat.dayLabel(day),
          subtitle: basis == OrderBasis.created
              ? S.ordersByCreation
              : S.moneyOfShift,
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.children, required this.onRefresh});

  final List<Widget> children;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        color: kPrimaryColor,
        onRefresh: () async => onRefresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          physics: const AlwaysScrollableScrollPhysics(),
          children: children,
        ),
      );
}

class _CountList extends StatelessWidget {
  const _CountList({required this.rows});

  final List<NamedCount> rows;

  @override
  Widget build(BuildContext context) {
    final top = rows.fold<int>(
        0, (best, row) => (row.count ?? 0) > best ? (row.count ?? 0) : best);
    return ExpandableList(
      itemCount: rows.length,
      itemBuilder: (context, i) => NamedCountRow(
        // An unknown district is shown as such, never guessed.
        name: Fmt.text(rows[i].name),
        count: rows[i].count,
        amount: rows[i].foodAmount,
        share: top == 0 ? 0 : (rows[i].count ?? 0) / top,
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({required this.rows});

  final List<ProductDemand> rows;

  @override
  Widget build(BuildContext context) {
    final top = rows.fold<int>(
        0,
        (best, row) =>
            (row.quantity ?? 0) > best ? (row.quantity ?? 0) : best);
    return ExpandableList(
      itemCount: rows.length,
      itemBuilder: (context, i) => NamedCountRow(
        name: Fmt.text(rows[i].name),
        count: rows[i].quantity,
        share: top == 0 ? 0 : (rows[i].quantity ?? 0) / top,
      ),
    );
  }
}
