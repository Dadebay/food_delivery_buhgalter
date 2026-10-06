import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/constants.dart';
import '../data/ashgabat_time.dart';
import '../data/formatting.dart';
import '../data/models/overview.dart';
import '../data/models/report.dart';
import '../data/strings.dart';
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
/// orders by creation time; touching one shows its numbers.
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
    final peak = _peak(points);
    return _ChartFrame(
      title: S.chartOrders,
      icon: AppIcons.orders,
      accent: kPrimaryColor,
      highlight: peak == null || peak.primary <= 0
          ? null
          : '${S.peakDay}: ${Ashgabat.shortDay(peak.day)} · '
              '${Fmt.count(peak.primary.round())}',
      legend: [
        _Legend(color: kPrimaryColor, label: S.legendCreated),
        _Legend(color: kNegativeColor, label: S.legendCancelled),
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
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => kBlackColor,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (rodIndex != 0) return null;
                final point = points[groupIndex];
                return BarTooltipItem(
                  '${Ashgabat.shortDay(point.day)}\n'
                  '${S.legendCreated}: ${Fmt.count(point.primary.round())}\n'
                  '${S.legendCancelled}: ${Fmt.count(point.secondary.round())}',
                  const TextStyle(
                    fontFamily: gilroyMedium,
                    fontSize: 11.5,
                    color: Colors.white,
                    height: 1.35,
                  ),
                );
              },
            ),
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
                    width: 4.5,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                  BarChartRodData(
                    toY: points[i].secondary,
                    color: kNegativeColor,
                    width: 4.5,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(3)),
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
    final peak = _peak(points);
    final peakIndex = peak == null ? -1 : points.indexOf(peak);
    return _ChartFrame(
      title: S.chartMoney,
      icon: AppIcons.money,
      accent: kPositiveColor,
      highlight: peak == null || peak.primary <= 0
          ? null
          : '${S.bestDay}: ${Ashgabat.shortDay(peak.day)} · '
              '${Fmt.money(peak.primary)}',
      legend: [_Legend(color: kPositiveColor, label: S.legendReceived)],
      footnote: S.chartZeroNote,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxValue <= 0 ? 4 : maxValue * 1.25,
          gridData: _grid(),
          borderData: FlBorderData(show: false),
          titlesData: _titles(points, _shortMoney, reserved: 48),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => kBlackColor,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (spots) => [
                for (final spot in spots)
                  LineTooltipItem(
                    '${Ashgabat.shortDay(points[spot.spotIndex].day)}\n'
                    '${Fmt.money(points[spot.spotIndex].primary)}',
                    const TextStyle(
                      fontFamily: gilroyMedium,
                      fontSize: 11.5,
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
              ],
            ),
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
              isCurved: true,
              curveSmoothness: 0.2,
              preventCurveOverShooting: true,
              color: kPositiveColor,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, _) =>
                    spot.x.round() == peakIndex && spot.y > 0,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 4.5,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: kPositiveColor,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    // ignore: deprecated_member_use
                    kPositiveColor.withOpacity(0.28),
                    // ignore: deprecated_member_use
                    kPositiveColor.withOpacity(0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _shortMoney(double value) {
    // Language-neutral on purpose: an axis label has no room for a word.
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }
}

/// The day with the highest primary value — a reading of the rows the server
/// sent, not a figure of its own.
DayPoint? _peak(List<DayPoint> points) {
  DayPoint? best;
  for (final point in points) {
    if (best == null || point.primary > best.primary) best = point;
  }
  return best;
}

FlGridData _grid() => FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) =>
          const FlLine(color: kBorderColor, strokeWidth: 1, dashArray: [4, 4]),
    );

FlTitlesData _titles(
  List<DayPoint> points,
  String Function(double value) leftLabel, {
  double reserved = 34,
}) =>
    FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
    required this.icon,
    required this.accent,
    required this.child,
    required this.legend,
    this.highlight,
    this.footnote,
  });

  final String title;
  final List<List<dynamic>> icon;
  final Color accent;
  final Widget child;
  final List<Widget> legend;

  /// One line that says where the chart peaks, so the answer is readable
  /// without touching the chart.
  final String? highlight;
  final String? footnote;

  @override
  Widget build(BuildContext context) => CardBox(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIconBadge(icon, color: accent, size: 34),
                const SizedBox(width: 10),
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
            if (highlight != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: accent.withOpacity(0.08),
                  borderRadius: borderRadius10,
                ),
                child: Text(
                  highlight!,
                  style: TextStyle(
                    fontFamily: gilroySemiBold,
                    fontSize: 12,
                    color: accent,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(spacing: 14, runSpacing: 4, children: legend),
            const SizedBox(height: 14),
            SizedBox(height: 210, child: child),
            const SizedBox(height: 10),
            Text(
              S.chartTapHint,
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
