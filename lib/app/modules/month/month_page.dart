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
import '../../widgets/ui.dart';
import '../orders/orders_page.dart';

/// The month, built from the three range calls the spec prescribes.
///
/// There is no `/monthly` endpoint: `overview`, `report` and `shifts` are
/// asked in parallel, and the rest of the sections load when they are opened
/// rather than being downloaded here to build charts.
///
/// The page reads top to bottom as one answer: what came in, what was
/// ordered, how both moved day by day, and only then the breakdowns — each
/// of which shows its head and keeps its tail one tap away.
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
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
      // ── Money, as one block with one headline ──────────────────────────
      _HeadlineCard(
        icon: AppIcons.collected,
        accent: kPositiveColor,
        caption: S.received,
        value: Fmt.money(report.collectedAmount),
        rows: [
          _Row(S.handedOver, Fmt.money(report.submittedAmount)),
          _Row(S.confirmedMoney, Fmt.money(report.confirmedAmount),
              color: kPositiveColor),
          _Row(S.outstanding, Fmt.money(report.outstandingAmount),
              color: kWarningColor),
          _Row(S.declaredByPackets, Fmt.money(report.declaredHandoffAmount)),
          if (discrepancy != null && discrepancy != 0)
            _Row(
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

      // ── Orders, the same shape so the two read as a pair ───────────────
      const SizedBox(height: 12),
      _HeadlineCard(
        icon: AppIcons.orders,
        accent: kPrimaryColor,
        caption: S.createdOrders,
        value: Fmt.count(overview.createdOrders),
        rows: [
          _Row(S.cancelledNow, Fmt.count(overview.cancelledOrders),
              color: kNegativeColor),
          _Row(S.cancelShare, Fmt.percent(overview.cancellationRate)),
          _Row(S.cancelEvents, Fmt.count(overview.cancellationEvents)),
          _Row(S.editEvents, Fmt.count(overview.editEvents)),
          _Row(S.foodAmount, Fmt.money(overview.foodAmount)),
        ],
      ),

      const SizedBox(height: 18),
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
        _CountList(rows: bundle.overview.districts),
      ],
      if (bundle.overview.branches.isNotEmpty) ...[
        SectionTitle(S.kitchens, icon: AppIcons.branch),
        _CountList(rows: bundle.overview.branches),
      ],
      if (bundle.overview.cancellationReasons.isNotEmpty) ...[
        SectionTitle(S.cancelReasons, icon: AppIcons.cancelled),
        _CountList(rows: bundle.overview.cancellationReasons),
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

class _Row {
  const _Row(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;
}

/// One headline figure with its supporting rows.
///
/// This replaced a grid of six equal tiles: six numbers of the same size say
/// nothing about which one to read first.
class _HeadlineCard extends StatelessWidget {
  const _HeadlineCard({
    required this.icon,
    required this.accent,
    required this.caption,
    required this.value,
    required this.rows,
  });

  final List<List<dynamic>> icon;
  final Color accent;
  final String caption;
  final String value;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) => CardBox(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIconBadge(icon, color: accent, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caption,
                        style: const TextStyle(
                          fontFamily: gilroyMedium,
                          fontSize: 12.5,
                          color: kMutedColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontFamily: gilroyBold,
                            fontSize: 24,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (rows.isNotEmpty) const Divider(height: 20, color: kBorderColor),
            for (final row in rows)
              InfoRow(
                label: row.label,
                value: row.value,
                valueColor: row.color ?? kBlackColor,
              ),
          ],
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
