import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/constants.dart';
import '../../data/accounting_service.dart';
import '../../data/app_state.dart';
import '../../data/ashgabat_time.dart';
import '../../data/formatting.dart';
import '../../data/models/overview.dart';
import '../../widgets/async_loader.dart';
import '../../widgets/daily_charts.dart';
import '../../widgets/month_bar.dart';
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
      animation: period,
      builder: (context, _) => AppScaffold(
        title: 'Графики',
        subtitle: 'Спрос, деньги и причины отмен',
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
      const MonthBar(),

      const SectionTitle('Заказы и отмены', icon: AppIcons.orders),
      StatGrid(tiles: [
        StatTile(
          label: 'Создано заказов',
          value: Fmt.count(overview.createdOrders),
          icon: AppIcons.orders,
          color: kPrimaryColor,
        ),
        StatTile(
          label: 'Отменено сейчас',
          value: Fmt.count(overview.cancelledOrders),
          icon: AppIcons.cancelled,
          color: kNegativeColor,
          hint: 'состояние заказов, созданных в периоде',
        ),
        StatTile(
          label: 'Доля отмен',
          value: Fmt.percent(overview.cancellationRate),
          icon: AppIcons.districts,
        ),
        StatTile(
          label: 'Действий отмены',
          value: Fmt.count(overview.cancellationEvents),
          icon: AppIcons.cancelled,
          hint: 'переходы в отмену в течение периода',
        ),
        StatTile(
          label: 'Редактирований',
          value: Fmt.count(overview.editEvents),
          icon: AppIcons.edited,
          hint: 'в том числе заказов прошлых смен',
        ),
        StatTile(
          label: 'Сумма еды',
          value: Fmt.money(overview.foodAmount),
          icon: AppIcons.dish,
        ),
      ]),

      const SectionTitle('Деньги', icon: AppIcons.money),
      StatGrid(tiles: [
        StatTile(
          label: 'Получено',
          value: Fmt.money(report.collectedAmount),
          icon: AppIcons.collected,
          color: kPositiveColor,
        ),
        StatTile(
          label: 'Передано',
          value: Fmt.money(report.submittedAmount),
          icon: AppIcons.submitted,
        ),
        StatTile(
          label: 'Подтверждено',
          value: Fmt.money(report.confirmedAmount),
          icon: AppIcons.confirmed,
          color: kPositiveColor,
        ),
        StatTile(
          label: 'Ещё не передано',
          value: Fmt.money(report.outstandingAmount),
          icon: AppIcons.outstanding,
          color: kWarningColor,
        ),
        StatTile(
          label: 'Заявлено пакетами',
          value: Fmt.money(report.declaredHandoffAmount),
          icon: AppIcons.handoff,
          hint: 'пакеты смен, начавшихся в периоде',
        ),
        StatTile(
          label: 'Расхождение',
          value: Fmt.signedMoney(discrepancy),
          icon: AppIcons.warning,
          color: discrepancy == null
              ? kBlackColor
              : discrepancy < 0
                  ? kNegativeColor
                  : discrepancy > 0
                      ? kWarningColor
                      : kPositiveColor,
          hint: 'заявлено минус ожидаемое',
        ),
      ]),
      const SizedBox(height: 10),
      const NoticeBox(
        'Расхождение — это не комиссия за систему и не доказательство '
        'фактического пересчёта купюр. Детали и комментарии остаются в '
        'пакетах смен.',
        color: kPrimaryColor,
      ),

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
        const SectionTitle('Районы', icon: AppIcons.address),
        _NamedList(rows: bundle.overview.districts),
      ],
      if (bundle.overview.branches.isNotEmpty) ...[
        const SectionTitle('Кухни', icon: AppIcons.branch),
        _NamedList(rows: bundle.overview.branches),
      ],
      if (bundle.overview.cancellationReasons.isNotEmpty) ...[
        const SectionTitle('Причины отмен', icon: AppIcons.cancelled),
        _NamedList(rows: bundle.overview.cancellationReasons),
      ],

      if (bundle.overview.mostOrderedProducts.isNotEmpty) ...[
        const SectionTitle('Часто заказывают', icon: AppIcons.ranking),
        _ProductList(rows: bundle.overview.mostOrderedProducts),
      ],
      if (bundle.overview.leastOrderedProducts.isNotEmpty) ...[
        const SectionTitle('Редко заказывают', icon: AppIcons.ranking),
        _ProductList(rows: bundle.overview.leastOrderedProducts),
        const SizedBox(height: 8),
        const Text(
          'Популярность считается в порциях, а не в деньгах. Блюда, которых '
          'никто не заказывал, в «редкие» не попадают; переименованное блюдо '
          'может стать отдельной исторической строкой.',
          style: TextStyle(
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
          title: Ashgabat.dayLabel(day, kLocale),
          subtitle: basis == OrderBasis.created
              ? 'Заказы по времени создания'
              : 'Деньги, возвращённые в этот день',
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
