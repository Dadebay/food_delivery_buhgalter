import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/constants.dart';
import '../../data/app_state.dart';
import '../../data/ashgabat_time.dart';
import '../../data/auth_service.dart';
import '../../data/formatting.dart';
import '../../data/labels.dart';
import '../../data/models/shift.dart';
import '../../data/strings.dart';
import '../../widgets/async_loader.dart';
import '../../widgets/language_action.dart';
import '../../widgets/month_picker.dart';
import '../../widgets/ui.dart';
import 'handoff_sheet.dart';
import 'shift_detail_page.dart';

/// The shifts of the chosen month, with what each owes and its money packet.
///
/// `/shifts` takes calendar dates only — a shift key is not accepted here —
/// and a whole day's report is never labelled as one shift's takings: each
/// amount below comes from that shift's own entry.
class ShiftsPage extends StatelessWidget {
  const ShiftsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final period = App.instance.period;
    final language = App.instance.language;
    return AnimatedBuilder(
      animation: Listenable.merge([period, language]),
      builder: (context, _) => AppScaffold(
        title: S.shiftsMoney,
        subtitle: Ashgabat.monthLabel(period.month),
        actions: const [MonthAction(), LanguageAction(), SizedBox(width: 4)],
        child: AsyncLoader<_ShiftsData>(
          requestKey: '${period.fromDate}:${period.toDate}',
          request: () async {
            final shifts = await App.instance.accounting.shifts(
              fromDate: period.fromDate,
              toDate: period.toDate,
            );
            // Names and windows come from the API; 09:30/19:00 is never
            // hardcoded. Losing them only costs the caption.
            AccountingSettings? settings;
            try {
              settings = await App.instance.settings();
            } catch (_) {
              settings = null;
            }
            return _ShiftsData(shifts: shifts, settings: settings);
          },
          builder: (context, data, reload) => RefreshIndicator(
            color: kPrimaryColor,
            onRefresh: () async => reload(),
            child: _ShiftsList(data: data, onChanged: reload),
          ),
        ),
      ),
    );
  }
}

class _ShiftsData {
  const _ShiftsData({required this.shifts, this.settings});

  final List<ShiftSummary> shifts;
  final AccountingSettings? settings;

  /// Two shifts under one calendar day, newest day first.
  ///
  /// The books are read from today backwards, so today sits at the top and
  /// nobody scrolls the whole month to reach the shift they are standing in.
  /// Within a day the later shift comes first for the same reason.
  Map<String, List<ShiftSummary>> get grouped {
    final result = <String, List<ShiftSummary>>{};
    for (final shift in shifts) {
      result.putIfAbsent(shift.dayKey, () => []).add(shift);
    }
    for (final day in result.values) {
      day.sort((a, b) {
        final byStart = (b.startsAt ?? DateTime(0)).compareTo(a.startsAt ?? DateTime(0));
        // Without times to compare, `second` still belongs above `first`.
        return byStart != 0 ? byStart : b.slot.compareTo(a.slot);
      });
    }
    final days = result.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final day in days) day: result[day]!};
  }
}

/// The month's shifts with today at the top and the rest folded away.
///
/// A month holds sixty cards and only two of them are the shift somebody is
/// standing in. Today is printed on its own and the earlier days stay behind
/// one button — they are still here, and the button says how many days that
/// is, because a list cut silently is worse than a long one.
class _ShiftsList extends StatefulWidget {
  const _ShiftsList({required this.data, required this.onChanged});

  final _ShiftsData data;
  final VoidCallback onChanged;

  @override
  State<_ShiftsList> createState() => _ShiftsListState();
}

class _ShiftsListState extends State<_ShiftsList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final grouped = widget.data.grouped;
    final days = grouped.keys.toList();
    final todayKey = Ashgabat.date(Ashgabat.now());

    // The day to open on: today when the month has it, otherwise the latest
    // day the month does have — a past month opens on its last working day
    // rather than on nothing at all.
    final hasToday = grouped.containsKey(todayKey);
    final leadDay = hasToday ? todayKey : (days.isEmpty ? null : days.first);
    final rest = days.where((day) => day != leadDay).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (days.isEmpty)
          CardBox(
            child: Text(
              S.noShifts,
              style: const TextStyle(
                fontFamily: gilroyRegular,
                fontSize: 13.5,
                color: kMutedColor,
              ),
            ),
          )
        else ...[
          // Saying "today has no shift yet" is not the same as an empty
          // month, and the accountant is told which of the two this is.
          if (!hasToday && App.instance.period.isCurrentMonth) ...[
            NoticeBox(S.noShiftsTodayInMonth, color: kPrimaryColor),
            const SizedBox(height: 12),
          ],
          _DayBlock(
            title: hasToday ? S.todayShifts : _dayTitle(leadDay!),
            subtitle: hasToday ? _dayTitle(leadDay!) : null,
            shifts: grouped[leadDay]!,
            settings: widget.data.settings,
            onChanged: widget.onChanged,
          ),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 6),
            ShowMoreButton(
              expanded: _expanded,
              label: _expanded ? S.hideOtherDays : S.showOtherDays(rest.length),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
            if (_expanded) ...[
              const SizedBox(height: 14),
              for (final day in rest)
                _DayBlock(
                  title: _dayTitle(day),
                  shifts: grouped[day]!,
                  settings: widget.data.settings,
                  onChanged: widget.onChanged,
                ),
            ],
          ],
        ],
      ],
    );
  }

  static String _dayTitle(String dayKey) {
    final parsed = Ashgabat.parseDate(dayKey);
    return parsed == null ? dayKey : Ashgabat.dayLabel(parsed);
  }
}

/// One calendar day and the shifts under it.
class _DayBlock extends StatelessWidget {
  const _DayBlock({
    required this.title,
    required this.shifts,
    required this.settings,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<ShiftSummary> shifts;
  final AccountingSettings? settings;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 10),
            child: Row(
              children: [
                const AppIcon(AppIcons.day, size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: gilroyBold,
                          fontSize: 15,
                          color: kBlackColor,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontFamily: gilroyRegular,
                            fontSize: 11.5,
                            color: kMutedColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final shift in shifts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ShiftCard(
                shift: shift,
                settings: settings,
                onChanged: onChanged,
              ),
            ),
        ],
      );
}

/// One shift, reduced to what a glance needs: which shift, whether the money
/// is settled, how much is owed, and the one action available.
///
/// The packet's authors, notes and record count live on the shift's own
/// screen — a list that repeats them is slower to read, not richer.
class ShiftCard extends StatelessWidget {
  const ShiftCard({
    super.key,
    required this.shift,
    required this.settings,
    required this.onChanged,
  });

  final ShiftSummary shift;
  final AccountingSettings? settings;

  /// Called after a packet changes, so the shifts, the report and the
  /// journal are all re-read rather than patched locally.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final handoff = shift.handoff;
    ShiftDefinition? definition;
    for (final item in settings?.shifts ?? const <ShiftDefinition>[]) {
      if (item.slot == shift.slot) {
        definition = item;
        break;
      }
    }
    final name = shift.name ?? settings?.nameFor(shift.slot) ?? Labels.shiftSlot(shift.slot);
    final start = Ashgabat.timeLabel(shift.startsAt);
    final end = Ashgabat.timeLabel(shift.endsAt);
    final window = start != null && end != null ? '$start – $end' : ((definition?.window ?? '').isEmpty ? null : definition!.window);
    final discrepancy = handoff?.discrepancy;

    return CardBox(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ShiftDetailPage(shift: shift, shiftName: name),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppIconBadge(AppIcons.shifts, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: gilroySemiBold,
                        fontSize: 15,
                        color: kBlackColor,
                      ),
                    ),
                    if (window != null)
                      Text(
                        window,
                        style: const TextStyle(
                          fontFamily: gilroyRegular,
                          fontSize: 12,
                          color: kMutedColor,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Pill(
                Labels.handoffStatus(handoff?.status),
                color: Labels.handoffStatusColor(handoff?.status),
              ),
            ],
          ),
          const Divider(height: 18, color: kBorderColor),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.expected,
                      style: const TextStyle(
                        fontFamily: gilroyRegular,
                        fontSize: 12,
                        color: kMutedColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Fmt.money(shift.expectedAmount),
                      style: const TextStyle(
                        fontFamily: gilroyBold,
                        fontSize: 18,
                        color: kBlackColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${S.collectedInShift} ${Fmt.money(shift.collectedAmount)}'
                '\n${Fmt.count(shift.orderCount)} · ${S.ordersCount}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: gilroyMedium,
                  fontSize: 11.5,
                  color: kMutedColor,
                ),
              ),
            ],
          ),
          // Only worth a line when it is not zero: a matching packet needs no
          // commentary.
          if (discrepancy != null && discrepancy != 0) ...[
            const SizedBox(height: 8),
            Pill(
              '${S.discrepancy}: ${Fmt.signedMoney(discrepancy)}',
              color: discrepancy < 0 ? kNegativeColor : kWarningColor,
              icon: AppIcons.warning,
            ),
          ],
          // Inline null check so the packet promotes to non-null below.
          if (handoff != null && !handoff.isConfirmed) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: kPositiveColor,
                  shape: const RoundedRectangleBorder(borderRadius: borderRadius10),
                ),
                onPressed: () => confirmHandoff(
                  context,
                  handoff: handoff,
                  onDone: onChanged,
                ),
                icon: const AppIcon(AppIcons.confirmed, size: 17, color: Colors.white),
                label: Text(
                  S.confirmAmount,
                  style: const TextStyle(
                    fontFamily: gilroySemiBold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ] else if (handoff == null && App.instance.auth.role.canCreateHandoff) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kBorderColor),
                  shape: const RoundedRectangleBorder(borderRadius: borderRadius10),
                ),
                onPressed: () => createHandoff(
                  context,
                  shift: shift,
                  onDone: onChanged,
                ),
                icon: const AppIcon(AppIcons.handoff, size: 17),
                label: Text(
                  S.createPacket,
                  style: const TextStyle(
                    fontFamily: gilroySemiBold,
                    color: kPrimaryColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
