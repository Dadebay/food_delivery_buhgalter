import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/constants.dart';
import '../data/app_state.dart';
import '../data/ashgabat_time.dart';

const String kLocale = 'ru';

/// The month selector the spec wants visible at the top of the screen.
///
/// It edits the shared [PeriodStore], so every section is looking at the same
/// month and the choice survives going back.
class MonthBar extends StatelessWidget {
  const MonthBar({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final period = App.instance.period;
    return AnimatedBuilder(
      animation: period,
      builder: (context, _) {
        final label = Ashgabat.monthLabel(period.month, kLocale);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: kBorderColor),
            borderRadius: borderRadius15,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: period.previous,
                tooltip: 'Предыдущий месяц',
                icon: const AppIcon(AppIcons.previousMonth, size: 18),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: borderRadius10,
                  onTap: () => _pick(context, period),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const AppIcon(AppIcons.calendar, size: 16),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                // "сентябрь 2026" with a capital first letter.
                                label.isEmpty
                                    ? label
                                    : label[0].toUpperCase() +
                                        label.substring(1),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: gilroySemiBold,
                                  fontSize: 15,
                                  color: kBlackColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: gilroyRegular,
                                fontSize: 11.5,
                                color: kMutedColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                // There are no future books to inspect.
                onPressed: period.isCurrentMonth ? null : period.next,
                tooltip: 'Следующий месяц',
                icon: AppIcon(
                  AppIcons.nextMonth,
                  size: 18,
                  color: period.isCurrentMonth ? kBorderColor : kPrimaryColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pick(BuildContext context, PeriodStore period) async {
    final now = Ashgabat.now();
    var year = period.month.year;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setSheetState(() => year -= 1),
                      icon: const AppIcon(AppIcons.previousMonth, size: 18),
                    ),
                    Expanded(
                      child: Text(
                        '$year',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: gilroyBold,
                          fontSize: 18,
                          color: kBlackColor,
                        ),
                      ),
                    ),
                    IconButton(
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var m = 1; m <= 12; m++)
                      _MonthChip(
                        month: DateTime(year, m, 1),
                        selected: period.month.year == year &&
                            period.month.month == m,
                        // A month that has not started yet has no books.
                        enabled: DateTime(year, m, 1)
                            .isBefore(DateTime(now.year, now.month + 1, 1)),
                        onTap: () {
                          period.select(DateTime(year, m, 1));
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final name = Ashgabat.monthLabel(month, kLocale).split(' ').first;
    return SizedBox(
      width: 96,
      child: Material(
        color: selected ? kPrimaryColor : kSurfaceColor,
        borderRadius: borderRadius10,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: borderRadius10,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              name.isEmpty ? name : name[0].toUpperCase() + name.substring(1),
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
      ),
    );
  }
}
