import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/constants.dart';
import '../data/app_state.dart';
import '../data/ashgabat_time.dart';
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
          color: // ignore: deprecated_member_use
          kPrimaryColor.withOpacity(0.10),
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

/// Year arrows and twelve chips. A month that has not started has no books,
/// so it cannot be chosen.
Future<void> showMonthPicker(BuildContext context) async {
  final period = App.instance.period;
  final now = Ashgabat.now();
  var year = period.month.year;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
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
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    tooltip: S.previousMonth,
                    onPressed: () => setSheetState(() => year -= 1),
                    icon: const AppIcon(AppIcons.previousMonth, size: 18),
                  ),
                  Expanded(
                    child: Text(
                      '$year',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: gilroyBold,
                        fontSize: 20,
                        color: kBlackColor,
                      ),
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
                      color: year >= now.year ? kBorderColor : kPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
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
            ],
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
  });

  final DateTime month;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? kPrimaryColor : kSurfaceColor,
        borderRadius: borderRadius10,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: borderRadius10,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              Ashgabat.monthName(month),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: gilroySemiBold,
                fontSize: 13,
                color: selected
                    ? Colors.white
                    : enabled
                        ? kBlackColor
                        : kBorderColor,
              ),
            ),
          ),
        ),
      );
}
