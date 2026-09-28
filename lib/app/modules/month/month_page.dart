import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/constants.dart';
import '../../data/accounting_service.dart';
import '../../data/app_state.dart';
import '../../data/ashgabat_time.dart';
import '../../data/formatting.dart';
import '../../data/models/overview.dart';
import '../../data/strings.dart';
import '../../widgets/language_action.dart';
import '../../widgets/month_picker.dart';
import '../../widgets/async_loader.dart';
import '../../widgets/daily_charts.dart';
import '../../widgets/ui.dart';
import '../orders/orders_page.dart';

/// The month, built from the three range calls the spec prescribes.
///
/// There is no `/monthly` endpoint: `overview`, `report` and `shifts` are
/// asked in parallel, and the rest of the sections load when they are opened
/// rather than being downloaded here to build charts.
class MonthPage extends StatelessWidget {
  const MonthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final period = App.instance.period;
    return AnimatedBuilder(
      animation: Listenable.merge([period, App.instance.language]),
      builder: (context, _) => AppScaffold(
        title: S.charts,
        subtitle: Ashgabat.monthLabel(period.month),
        actions: const [MonthAction(), LanguageAction(), SizedBox(width: 4)],
        child: AsyncLoader<MonthBundle>(
          requestKey: '${period.fromDate}:${period.toDate}',
          request: () => App.instance.accounting
              .month(fromDate: period.fromDate, toDate: period.toDate),
          builder: (context, bundle, reload) => RefreshIndicator(
            color: kPrimaryColor,
            onRefresh: () async => reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              physics: const AlwaysScrollableScrollPhysics(),
              children: _body(context, bundle, period.month),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    MonthBundle bundle,
    DateTime month,
  ) {
    final overview = bundle.overview.summary;
    final report = bundle.report.summary;
    final discrepancy = report.handoffDiscrepancy;
    return [
      SectionTitle(S.ordersAndCancels, icon: AppIcons.orders),
      StatGrid(tiles: [
        StatTile(
          label: S.createdOrders,
          value: Fmt.count(overview.createdOrders),
          icon: AppIcons.orders,
          color: kPrimaryColor,
        ),
        StatTile(
          label: S.cancelledNow,
          value: Fmt.count(overview.cancelledOrders),
          icon: AppIcons.cancelled,
          color: kNegativeColor,
          hint: S.cancelledNowHint,
        ),
        StatTile(
          label: S.cancelShare,
          value: Fmt.percent(overview.cancellationRate),
          icon: AppIcons.districts,
        ),
        StatTile(
          label: S.cancelEvents,
          value: Fmt.count(overview.cancellationEvents),
          icon: AppIcons.cancelled,
          hint: S.cancelEventsHint,
        ),
        StatTile(
          label: S.editEvents,
          value: Fmt.count(overview.editEvents),
          icon: AppIcons.edited,
          hint: S.editEventsHint,
        ),
        StatTile(
          label: S.foodAmount,
          value: Fmt.money(overview.foodAmount),
          icon: AppIcons.dish,
        ),
      ]),

      SectionTitle(S.money, icon: AppIcons.money),
      StatGrid(tiles: [
        StatTile(
          label: S.received,
          value: Fmt.money(report.collectedAmount),
          icon: AppIcons.collected,
          color: kPositiveColor,
        ),
        StatTile(
          label: S.handedOver,
          value: Fmt.money(report.submittedAmount),
          icon: AppIcons.submitted,
        ),
        StatTile(
          label: S.confirmedMoney,
          value: Fmt.money(report.confirmedAmount),
          icon: AppIcons.confirmed,
          color: kPositiveColor,
        ),
        StatTile(
          label: S.outstanding,
          value: Fmt.money(report.outstandingAmount),
          icon: AppIcons.outstanding,
          color: kWarningColor,
        ),
        StatTile(
          label: S.declaredByPackets,
          value: Fmt.money(report.declaredHandoffAmount),
          icon: AppIcons.handoff,
          hint: S.declaredByPacketsHint,
        ),
        StatTile(
          label: S.discrepancy,
          value: Fmt.signedMoney(discrepancy),
          icon: AppIcons.warning,
          color: discrepancy == null
              ? kBlackColor
              : discrepancy < 0
                  ? kNegativeColor
                  : discrepancy > 0
                      ? kWarningColor
                      : kPositiveColor,
          hint: S.discrepancyHint,
        ),
      ]),
      const SizedBox(height: 10),
      NoticeBox(S.discrepancyNote, color: kPrimaryColor),

      const SizedBox(height: 22),
      DailyOrdersChart(
        points: alignOrders(month, bundle.overview.daily),
        onDayTap: (day) => _openDay(context, day, OrderBasis.created),
      ),
      const SizedBox(height: 12),
      DailyMoneyChart(
        points: alignMoney(month, bundle.report.daily),
        onDayTap: (day) => _openDay(context, day, OrderBasis.cashReturned),
      ),

      if (bundle.overview.districts.isNotEmpty) ...[
        SectionTitle(S.districts, icon: AppIcons.address),
        _NamedList(rows: bundle.overview.districts),
      ],
      if (bundle.overview.branches.isNotEmpty) ...[
        SectionTitle(S.kitchens, icon: AppIcons.branch),
        _NamedList(rows: bundle.overview.branches),
      ],
      if (bundle.overview.cancellationReasons.isNotEmpty) ...[
        SectionTitle(S.cancelReasons, icon: AppIcons.cancelled),
        _NamedList(rows: bundle.overview.cancellationReasons),
      ],

      if (bundle.overview.mostOrderedProducts.isNotEmpty) ...[
        SectionTitle(S.mostOrdered, icon: AppIcons.ranking),
        _ProductList(rows: bundle.overview.mostOrderedProducts),
      ],
      if (bundle.overview.leastOrderedProducts.isNotEmpty) ...[
        SectionTitle(S.leastOrdered, icon: AppIcons.ranking),
        _ProductList(rows: bundle.overview.leastOrderedProducts),
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

class _NamedList extends StatelessWidget {
  const _NamedList({required this.rows});

  final List<NamedCount> rows;

  @override
  Widget build(BuildContext context) {
    final top = rows.fold<int>(
        0, (best, row) => (row.count ?? 0) > best ? (row.count ?? 0) : best);
    return CardBox(
      child: Column(
        children: [
          for (final row in rows)
            NamedCountRow(
              // An unknown district is shown as such, never guessed.
              name: Fmt.text(row.name),
              count: row.count,
              amount: row.foodAmount,
              share: top == 0 ? 0 : (row.count ?? 0) / top,
            ),
        ],
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
    return CardBox(
      child: Column(
        children: [
          for (final row in rows)
            NamedCountRow(
              name: Fmt.text(row.name),
              count: row.quantity,
              share: top == 0 ? 0 : (row.quantity ?? 0) / top,
            ),
        ],
      ),
    );
  }
}
