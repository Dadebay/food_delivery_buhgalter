import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/constants.dart';
import '../data/formatting.dart';
import '../data/strings.dart';
import 'ui.dart';

/// One row of a ranking: a name, how many, and optionally the food money
/// behind it.
class RankRow {
  const RankRow({required this.name, required this.count, this.amount});

  final String name;
  final int count;
  final double? amount;
}

const List<Color> _palette = [
  kPrimaryColor,
  kPositiveColor,
  kWarningColor,
  Color(0xff0ea5e9),
  Color(0xffec4899),
];

const Color _otherColor = Color(0xffb8b8c8);

/// A ranked list with its head shown and its tail one tap away, optionally
/// topped by a donut of the biggest five.
///
/// Districts, kitchens, cancellation reasons and dish demand each run to
/// dozens of rows. The donut says at a glance who leads and by how much; the
/// list under it keeps every row — cutting it silently would hide data the
/// accountant came for, so the count of what is folded away is on the button.
class RankedCard extends StatefulWidget {
  const RankedCard({
    super.key,
    required this.title,
    required this.icon,
    required this.rows,
    this.accent = kPrimaryColor,
    this.donut = true,
    this.footnote,
    this.previewCount = 5,
  });

  final String title;
  final List<List<dynamic>> icon;
  final List<RankRow> rows;
  final Color accent;

  /// Whether to draw the donut. Dish demand is a list, not a split.
  final bool donut;
  final String? footnote;
  final int previewCount;

  @override
  State<RankedCard> createState() => _RankedCardState();
}

class _RankedCardState extends State<RankedCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final rows = [...widget.rows]..sort((a, b) => b.count.compareTo(a.count));
    final total = rows.fold<int>(0, (sum, row) => sum + row.count);
    final top = rows.isEmpty ? 0 : rows.first.count;
    final hasMore = rows.length > widget.previewCount;
    final shown = _expanded || !hasMore ? rows.length : widget.previewCount;

    return CardBox(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconBadge(widget.icon, color: widget.accent, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontFamily: gilroySemiBold,
                    fontSize: 14.5,
                    color: kBlackColor,
                  ),
                ),
              ),
              Text(
                Fmt.count(total),
                style: TextStyle(
                  fontFamily: gilroyBold,
                  fontSize: 15,
                  color: widget.accent,
                ),
              ),
            ],
          ),
          if (widget.donut && total > 0) ...[
            const SizedBox(height: 14),
            _Donut(rows: rows, total: total),
          ],
          const SizedBox(height: 10),
          for (var i = 0; i < shown; i++)
            _RankTile(
              rank: i + 1,
              row: rows[i],
              share: top == 0 ? 0 : rows[i].count / top,
              color: widget.donut && i < _palette.length
                  ? _palette[i]
                  : widget.donut
                      ? _otherColor
                      : widget.accent,
            ),
          if (hasMore) ...[
            const Divider(height: 14, color: kBorderColor),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: borderRadius10,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _expanded ? S.showLess : S.showAll(rows.length),
                      style: const TextStyle(
                        fontFamily: gilroySemiBold,
                        fontSize: 13,
                        color: kPrimaryColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AppIcon(
                      _expanded ? AppIcons.collapse : AppIcons.expand,
                      size: 15,
                      color: kPrimaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (widget.footnote != null) ...[
            const SizedBox(height: 6),
            Text(
              widget.footnote!,
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
}

class _Donut extends StatelessWidget {
  const _Donut({required this.rows, required this.total});

  final List<RankRow> rows;
  final int total;

  @override
  Widget build(BuildContext context) {
    final lead = rows.take(_palette.length).toList();
    final rest = rows.skip(_palette.length).fold<int>(0, (s, r) => s + r.count);
    return Row(
      children: [
        SizedBox(
          width: 118,
          height: 118,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(enabled: false),
                  sections: [
                    for (var i = 0; i < lead.length; i++)
                      PieChartSectionData(
                        value: lead[i].count.toDouble(),
                        color: _palette[i],
                        radius: 16,
                        showTitle: false,
                      ),
                    if (rest > 0)
                      PieChartSectionData(
                        value: rest.toDouble(),
                        color: _otherColor,
                        radius: 16,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              Text(
                Fmt.count(total),
                style: const TextStyle(
                  fontFamily: gilroyBold,
                  fontSize: 16,
                  color: kBlackColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < lead.length; i++)
                _LegendRow(
                  color: _palette[i],
                  label: lead[i].name,
                  value: lead[i].count,
                ),
              if (rest > 0)
                _LegendRow(
                  color: _otherColor,
                  label: S.otherLabel,
                  value: rest,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: gilroyMedium,
                  fontSize: 12,
                  color: kBlackColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              Fmt.count(value),
              style: const TextStyle(
                fontFamily: gilroySemiBold,
                fontSize: 12,
                color: kMutedColor,
              ),
            ),
          ],
        ),
      );
}

class _RankTile extends StatelessWidget {
  const _RankTile({
    required this.rank,
    required this.row,
    required this.share,
    required this.color,
  });

  final int rank;
  final RankRow row;
  final double share;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: color.withOpacity(rank <= 3 ? 0.14 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  fontFamily: gilroyBold,
                  fontSize: 11.5,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.name,
                          style: const TextStyle(
                            fontFamily: gilroySemiBold,
                            fontSize: 13.5,
                            color: kBlackColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        Fmt.count(row.count),
                        style: const TextStyle(
                          fontFamily: gilroyBold,
                          fontSize: 13.5,
                          color: kBlackColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: share.clamp(0.0, 1.0),
                      minHeight: 5,
                      // ignore: deprecated_member_use
                      backgroundColor: color.withOpacity(0.10),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  if (row.amount != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      Fmt.money(row.amount),
                      style: const TextStyle(
                        fontFamily: gilroyRegular,
                        fontSize: 12,
                        color: kMutedColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}
