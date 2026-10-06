import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/constants.dart';
import '../data/app_state.dart';
import '../data/ashgabat_time.dart';
import '../data/formatting.dart';
import '../data/strings.dart';

/// The month lives in the app bar, not in the page: it is a control, not
/// content, and every screen that reads a period shows the same one.
class MonthAction extends StatelessWidget {
  const MonthAction({super.key});

  @override
  Widget build(BuildContext context) {
    final period = App.instance.period;
    return AnimatedBuilder(
      animation: period,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Material(
          // ignore: deprecated_member_use
          color: kPrimaryColor.withOpacity(0.10),
          borderRadius: borderRadius30,
          child: InkWell(
            borderRadius: borderRadius30,
            onTap: () => showMonthPicker(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppIcon(AppIcons.calendar, size: 17),
                  const SizedBox(width: 6),
                  Text(
                    // Short enough for the bar, exact enough to trust.
                    '${Ashgabat.monthName(period.month).substring(0, 3)} '
                    '${period.month.year}',
                    style: const TextStyle(
                      fontFamily: gilroySemiBold,
                      fontSize: 13,
                      color: kPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Year arrows and twelve months, each with what came in that month.
///
/// The amounts are the money returned in the month (the report's `daily`
/// rows, summed) — one request per year, made when the year is shown. While
/// it loads the chips show a dash, and if it fails they say so rather than
/// showing zeros: a month with nothing and a month we could not read are not
/// the same thing. A month that has not started has no books, so it cannot be
/// chosen.
Future<void> showMonthPicker(BuildContext context) async {
  final period = App.instance.period;
  final now = Ashgabat.now();
  var year = period.month.year;
  final cache = <int, Future<Map<int, double>>>{};
  Future<Map<int, double>> totalsFor(int y) => cache.putIfAbsent(
        y,
        () => App.instance.accounting.monthlyTotals(y),
      );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: FutureBuilder<Map<int, double>>(
            key: ValueKey(year),
            future: totalsFor(year),
            builder: (context, snapshot) {
              final totals = snapshot.data;
              final failed = snapshot.hasError;
              final best = totals == null
                  ? 0.0
                  : totals.values.fold<double>(0, (a, b) => b > a ? b : a);
              final yearSum = totals?.values.fold<double>(0, (a, b) => a + b);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kBorderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    S.selectMonth,
                    style: const TextStyle(
                      fontFamily: gilroyBold,
                      fontSize: 17,
                      color: kBlackColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      IconButton(
                        tooltip: S.previousMonth,
                        onPressed: () => setSheetState(() => year -= 1),
                        icon: const AppIcon(AppIcons.previousMonth, size: 18),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '$year',
                              style: const TextStyle(
                                fontFamily: gilroyBold,
                                fontSize: 20,
                                color: kBlackColor,
                              ),
                            ),
                            Text(
                              failed
                                  ? S.errLoad
                                  : yearSum == null
                                      ? kDash
                                      : '${S.yearTotal(year)}: ${Fmt.money(yearSum)}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: gilroyMedium,
                                fontSize: 12,
                                color: failed ? kNegativeColor : kPositiveColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: S.nextMonth,
                        onPressed: year >= now.year
                            ? null
                            : () => setSheetState(() => year += 1),
                        icon: AppIcon(
                          AppIcons.nextMonth,
                          size: 18,
                          color:
                              year >= now.year ? kBorderColor : kPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = (constraints.maxWidth - 16) / 3;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var m = 1; m <= 12; m++)
                            SizedBox(
                              width: width,
                              child: _MonthChip(
                                month: DateTime(year, m, 1),
                                selected: period.month.year == year &&
                                    period.month.month == m,
                                enabled: DateTime(year, m, 1).isBefore(
                                    DateTime(now.year, now.month + 1, 1)),
                                amount: totals?[m],
                                share: best <= 0 || totals == null
                                    ? 0
                                    : (totals[m] ?? 0) / best,
                                failed: failed,
                                onTap: () {
                                  period.select(DateTime(year, m, 1));
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    S.monthEarnedHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: gilroyRegular,
                      fontSize: 11.5,
                      color: kMutedColor,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({
    required this.month,
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.amount,
    required this.share,
    required this.failed,
  });

  final DateTime month;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  /// Money returned in the month; null while it loads or when it failed.
  final double? amount;

  /// 0…1, against the best month of the year.
  final double share;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final nameColor = selected
        ? Colors.white
        : enabled
            ? kBlackColor
            : kBorderColor;
    final amountColor = selected
        ? Colors.white70
        : (amount ?? 0) > 0
            ? kPositiveColor
            : kMutedColor;
    return Material(
      color: selected ? kPrimaryColor : kSurfaceColor,
      borderRadius: borderRadius10,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: borderRadius10,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Column(
            children: [
              Text(
                Ashgabat.monthName(month),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: gilroySemiBold,
                  fontSize: 13,
                  color: nameColor,
                ),
              ),
              const SizedBox(height: 4),
              if (enabled)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    failed
                        ? kDash
                        : amount == null
                            ? kDash
                            : Fmt.money(amount),
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: gilroyMedium,
                      fontSize: 11.5,
                      color: amountColor,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: enabled ? share.clamp(0.0, 1.0) : 0,
                  minHeight: 3,
                  // ignore: deprecated_member_use
                  backgroundColor: (selected ? Colors.white : kBorderColor)
                      // ignore: deprecated_member_use
                      .withOpacity(selected ? 0.25 : 0.7),
                  valueColor: AlwaysStoppedAnimation(
                    selected ? Colors.white : kPositiveColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
