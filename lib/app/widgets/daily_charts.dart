import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/constants.dart';
import '../data/ashgabat_time.dart';
import '../data/formatting.dart';
import '../data/models/overview.dart';
import '../data/models/report.dart';
import 'ui.dart';

/// One point of a daily chart, already placed on the month's own axis.
class DayPoint {
  const DayPoint({
    required this.day,
    required this.primary,
    this.secondary = 0,
    this.orderCount,
    this.present = true,
  });

  final DateTime day;
  final double primary;
  final double secondary;
  final int? orderCount;

  /// Whether the server actually sent this day. A day it omitted is drawn as
  /// zero; a day that failed to load is not drawn at all, because a failed
  /// request is not zero revenue.
  final bool present;
}

/// Lays the server's daily rows onto every day of the month, matching on the
/// `date` string and never on the position in the array.
List<DayPoint> alignOrders(DateTime month, List<DailyOrders> daily) {
  final byDate = {for (final row in daily) row.date: row};
  return [
    for (final day in Ashgabat.daysOfMonth(month))
      () {
        final row = byDate[Ashgabat.date(day)];
        return DayPoint(
          day: day,
          primary: (row?.orders ?? 0).toDouble(),
          secondary: (row?.cancelled ?? 0).toDouble(),
          present: row != null,
        );
      }(),
  ];
}

List<DayPoint> alignMoney(DateTime month, List<DailyMoney> daily) {
  final byDate = {for (final row in daily) row.date: row};
  return [
    for (final day in Ashgabat.daysOfMonth(month))
      () {
        final row = byDate[Ashgabat.date(day)];
        return DayPoint(
          day: day,
          primary: row?.amount ?? 0,
          orderCount: row?.orderCount,
          present: row != null,
        );
      }(),
  ];
}

/// Orders and cancellations per day. Tapping a column opens that day's
/// orders by creation time.
class DailyOrdersChart extends StatelessWidget {
  const DailyOrdersChart({
    super.key,
    required this.points,
    required this.onDayTap,
  });

  final List<DayPoint> points;
  final void Function(DateTime day) onDayTap;

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<double>(
        0, (best, point) => point.primary > best ? point.primary : best);
    return _ChartFrame(
      title: 'Заказы по дням',
      legend: const [
        _Legend(color: kPrimaryColor, label: 'Создано'),
        _Legend(color: kNegativeColor, label: 'Отменено'),
      ],
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          maxY: maxValue <= 0 ? 4 : maxValue * 1.25,
          gridData: _grid(),
          borderData: FlBorderData(show: false),
          titlesData: _titles(points, (value) => Fmt.count(value.round())),
          barTouchData: BarTouchData(
            enabled: true,
            touchCallback: (event, response) {
              if (event is! FlTapUpEvent) return;
              final spot = response?.spot;
              if (spot == null) return;
              final index = spot.touchedBarGroupIndex;
              if (index < 0 || index >= points.length) return;
              onDayTap(points[index].day);
            },
          ),
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 1,
                barRods: [
                  BarChartRodData(
                    toY: points[i].primary,
                    color: kPrimaryColor,
                    width: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  BarChartRodData(
                    toY: points[i].secondary,
                    color: kNegativeColor,
                    width: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Money returned per day. A day the server omitted is a zero on this axis —
/// the caveat is printed under the chart so nobody reads a gap as a loss.
class DailyMoneyChart extends StatelessWidget {
  const DailyMoneyChart({
    super.key,
    required this.points,
    required this.onDayTap,
  });

  final List<DayPoint> points;
  final void Function(DateTime day) onDayTap;

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<double>(
        0, (best, point) => point.primary > best ? point.primary : best);
    return _ChartFrame(
      title: 'Получено денег за еду по дням',
      legend: const [_Legend(color: kPositiveColor, label: 'Получено, TMT')],
      footnote: 'Дни без поступлений сервер может не присылать — на оси они '
          'показаны нулём.',
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxValue <= 0 ? 4 : maxValue * 1.25,
          gridData: _grid(),
          borderData: FlBorderData(show: false),
          titlesData: _titles(points, _shortMoney, reserved: 48),
          lineTouchData: LineTouchData(
            enabled: true,
            touchCallback: (event, response) {
              if (event is! FlTapUpEvent) return;
              final spots = response?.lineBarSpots;
              if (spots == null || spots.isEmpty) return;
              final index = spots.first.spotIndex;
              if (index < 0 || index >= points.length) return;
              onDayTap(points[index].day);
            },
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].primary),
              ],
              isCurved: false,
              color: kPositiveColor,
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                // ignore: deprecated_member_use
                color: kPositiveColor.withOpacity(0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _shortMoney(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}М';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}т';
    return value.toStringAsFixed(0);
  }
}

FlGridData _grid() => FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) =>
          FlLine(color: kBorderColor, strokeWidth: 1),
    );

FlTitlesData _titles(
  List<DayPoint> points,
  String Function(double value) leftLabel, {
  double reserved = 34,
}) =>
    FlTitlesData(
      show: true,
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: reserved,
          getTitlesWidget: (value, meta) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              leftLabel(value),
              style: const TextStyle(
                fontFamily: gilroyRegular,
                fontSize: 9.5,
                color: kMutedColor,
              ),
            ),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          reservedSize: 22,
          getTitlesWidget: (value, meta) {
            final index = value.round();
            if (index < 0 || index >= points.length) {
              return const SizedBox.shrink();
            }
            final day = points[index].day.day;
            // Every fifth day plus the first keeps a 31-day axis readable on
            // a narrow phone without sideways scrolling.
            if (day != 1 && day % 5 != 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '$day',
                style: const TextStyle(
                  fontFamily: gilroyRegular,
                  fontSize: 9.5,
                  color: kMutedColor,
                ),
              ),
            );
          },
        ),
      ),
    );

class _ChartFrame extends StatelessWidget {
  const _ChartFrame({
    required this.title,
    required this.child,
    required this.legend,
    this.footnote,
  });

  final String title;
  final Widget child;
  final List<Widget> legend;
  final String? footnote;

  @override
  Widget build(BuildContext context) => CardBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppIcon(AppIcons.charts, size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: gilroySemiBold,
                      fontSize: 14.5,
                      color: kBlackColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(spacing: 14, runSpacing: 4, children: legend),
            const SizedBox(height: 14),
            SizedBox(height: 190, child: child),
            const SizedBox(height: 8),
            Text(
              'Нажмите на день, чтобы открыть его заказы.',
              style: const TextStyle(
                fontFamily: gilroyRegular,
                fontSize: 11.5,
                color: kMutedColor,
              ),
            ),
            if (footnote != null) ...[
              const SizedBox(height: 4),
              Text(
                footnote!,
                style: const TextStyle(
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

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: gilroyMedium,
              fontSize: 11.5,
              color: kMutedColor,
            ),
          ),
        ],
      );
}
