import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/constants.dart';
import '../../data/accounting_service.dart';
import '../../data/app_state.dart';
import '../../data/ashgabat_time.dart';
import '../../data/formatting.dart';
import '../../data/labels.dart';
import '../../data/models/overview.dart';
import '../../data/strings.dart';
import '../../widgets/async_loader.dart';
import '../../widgets/daily_charts.dart';
import '../../widgets/language_action.dart';
import '../../widgets/month_picker.dart';
import '../../widgets/ranked_card.dart';
import '../../widgets/ui.dart';
import '../orders/orders_page.dart';

/// The month, built from two range calls.
///
/// There is no `/monthly` endpoint: `overview` and `report` are asked in
/// parallel, and the rest of the sections load when they are opened
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
      animation: Listenable.merge(
          [period, App.instance.language, App.instance.refresh]),
      builder: (context, _) => DefaultTabController(
        length: 3,
        child: AppScaffold(
          title: S.charts,
          subtitle: Ashgabat.monthLabel(period.month),
          actions: const [MonthAction(), LanguageAction(), SizedBox(width: 4)],
          bottom: SegmentedTabBar(
            tabs: [
              SegmentTab(S.tabMoney, icon: AppIcons.money),
              SegmentTab(S.tabOrders, icon: AppIcons.orders),
              SegmentTab(S.tabBreakdown, icon: AppIcons.districts),
            ],
          ),
          child: AsyncLoader<MonthBundle>(
            requestKey:
                '${period.fromDate}:${period.toDate}:${App.instance.refreshTick}',
            request: () => App.instance.accounting
                .month(fromDate: period.fromDate, toDate: period.toDate),
            builder: (context, bundle, reload) => TabBarView(
              children: [
                _Tab(reload: reload, children: _money(context, bundle, period.month)),
                _Tab(reload: reload, children: _orders(context, bundle, period.month)),
                _Tab(reload: reload, children: _breakdown(bundle)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Everything that came in and where it stands.
  List<Widget> _money(BuildContext context, MonthBundle bundle, DateTime month) {
    final report = bundle.report.summary;
    return [
      _PairCard(
        left: _Figure(
          S.received,
          Fmt.money(report.collectedAmount),
          AppIcons.collected,
          kPositiveColor,
        ),
        right: _Figure(
          S.checkName,
          Fmt.count(report.completedOrders),
          AppIcons.money,
          kPrimaryColor,
        ),
      ),
      const SizedBox(height: 14),
      DailyMoneyChart(
        points: alignMoney(month, bundle.report.daily),
        onDayTap: (day) => _openDay(context, day, OrderBasis.cashReturned),
      ),
    ];
  }

  /// What was ordered, and what was cancelled out of it.
  List<Widget> _orders(BuildContext context, MonthBundle bundle, DateTime month) {
    final overview = bundle.overview.summary;
    return [
      _PairCard(
        left: _Figure(
          S.createdOrders,
          Fmt.count(overview.createdOrders),
          AppIcons.orders,
          kPrimaryColor,
        ),
        right: _Figure(
          S.cancelledNow,
          Fmt.count(overview.cancelledOrders),
          AppIcons.cancelled,
          kNegativeColor,
        ),
      ),
      const SizedBox(height: 14),
      DailyOrdersChart(
        points: alignOrders(month, bundle.overview.daily),
        onDayTap: (day) => _openDay(context, day, OrderBasis.created),
      ),
    ];
  }

  /// The lists behind the two headline numbers: who ordered from where, and
  /// what they ordered.
  List<Widget> _breakdown(MonthBundle bundle) {
    final overview = bundle.overview;
    List<RankRow> named(List<NamedCount> rows, {bool reasons = false}) => [
          for (final row in rows)
            RankRow(
              // An unknown district is shown as such, never guessed.
              name: reasons
                  ? Labels.cancelReason(row.name)
                  : Fmt.text(row.name),
              count: row.count ?? 0,
              amount: row.foodAmount,
            ),
        ];
    List<RankRow> products(List<ProductDemand> rows) => [
          for (final row in rows)
            RankRow(name: Fmt.text(row.name), count: row.quantity ?? 0),
        ];

    final sections = <Widget>[
      if (overview.mostOrderedProducts.isNotEmpty)
        RankedCard(
          title: S.mostOrdered,
          icon: AppIcons.ranking,
          accent: kPositiveColor,
          donut: false,
          rows: products(overview.mostOrderedProducts),
        ),
      if (overview.cancellationReasons.isNotEmpty)
        RankedCard(
          title: S.cancelReasons,
          icon: AppIcons.cancelled,
          accent: kNegativeColor,
          // A reason arrives as a stored key or as free text; both are named
          // in the reader's own language where the app knows the key.
          rows: named(overview.cancellationReasons, reasons: true),
        ),
    ];
    if (sections.isEmpty) {
      return [
        const SizedBox(height: 8),
        CardBox(
          child: Text(
            S.nothingForPeriod,
            style: const TextStyle(
              fontFamily: gilroyRegular,
              fontSize: 13.5,
              color: kMutedColor,
            ),
          ),
        ),
      ];
    }
    return [
      for (var i = 0; i < sections.length; i++) ...[
        if (i > 0) const SizedBox(height: 14),
        sections[i],
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

/// One tab's scrollable body, so pull-to-refresh works the same on each.
class _Tab extends StatelessWidget {
  const _Tab({required this.reload, required this.children});

  final VoidCallback reload;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        color: kPrimaryColor,
        onRefresh: () async => reload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          physics: const AlwaysScrollableScrollPhysics(),
          children: children,
        ),
      );
}

class _Figure {
  const _Figure(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final List<List<dynamic>> icon;
  final Color color;
}

/// Two figures side by side on one slim card — for a tab whose answer is a
/// pair of numbers, where a tall hero would only be empty space. Each figure
/// carries its own colour: red cannot be read on a coloured card, so this
/// one is white.
class _PairCard extends StatelessWidget {
  const _PairCard({required this.left, required this.right});

  final _Figure left;
  final _Figure right;

  @override
  Widget build(BuildContext context) => CardBox(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _FigureView(left)),
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: kBorderColor,
              ),
              Expanded(child: _FigureView(right)),
            ],
          ),
        ),
      );
}

class _FigureView extends StatelessWidget {
  const _FigureView(this.figure);

  final _Figure figure;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(figure.icon, size: 14, color: figure.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  figure.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: gilroyMedium,
                    fontSize: 11.5,
                    color: kMutedColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              figure.value,
              style: TextStyle(
                fontFamily: gilroyBold,
                fontSize: 24,
                color: figure.color,
              ),
            ),
          ),
        ],
      );
}
