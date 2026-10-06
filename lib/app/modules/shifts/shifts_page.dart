import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/constants.dart';
import '../../data/app_state.dart';
import '../../data/ashgabat_time.dart';
import '../../data/formatting.dart';
import '../../data/labels.dart';
import '../../data/models/shift.dart';
import '../../data/strings.dart';
import '../../widgets/async_loader.dart';
import '../../widgets/language_action.dart';
import '../../widgets/month_picker.dart';
import '../../widgets/ui.dart';
import 'shift_detail_page.dart';

/// The days of the chosen month: what each owes, its money packets, and the
/// queue of packets still waiting for the accountant.
///
/// `/days` takes calendar dates only — a day key is not accepted here — and
/// every figure is that day's own entry, never a report total relabelled.
class ShiftsPage extends StatelessWidget {
  const ShiftsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final period = App.instance.period;
    final language = App.instance.language;
    return AnimatedBuilder(
      animation: Listenable.merge([period, language, App.instance.refresh]),
      builder: (context, _) => AppScaffold(
        title: S.shiftsMoney,
        subtitle: Ashgabat.monthLabel(period.month),
        actions: const [MonthAction(), LanguageAction(), SizedBox(width: 4)],
        child: AsyncLoader<_CashData>(
          requestKey:
              '${period.fromDate}:${period.toDate}:${App.instance.refreshTick}',
          request: () async {
            // The month being read, and — whatever the month — the recent
            // days, so money still waiting from an earlier month is not
            // hidden by the month picker.
            final now = Ashgabat.now();
            final results = await Future.wait([
              App.instance.accounting.days(
                fromDate: period.fromDate,
                toDate: period.toDate,
              ),
              App.instance.accounting.days(
                fromDate: Ashgabat.date(
                    now.subtract(const Duration(days: kArrearsLookbackDays))),
                toDate: Ashgabat.date(now),
              ),
            ]);
            return _CashData(month: results[0], recent: results[1]);
          },
          builder: (context, data, reload) =>
              _CashTabs(data: data, onChanged: reload),
        ),
      ),
    );
  }
}

class _CashData {
  const _CashData({required this.month, required this.recent});

  /// The days of the month on screen.
  final List<CashDay> month;

  /// The last [kArrearsLookbackDays] days, whatever month that is.
  final List<CashDay> recent;

  /// Both lists as one, a day once.
  List<CashDay> get all {
    final seen = <String>{};
    return [...month, ...recent].where((d) => seen.add(d.shiftKey)).toList();
  }
}

/// Packets that are waiting for the accountant, without duplicates.
///
/// Decided by each packet's own `SUBMITTED` status. The month's period is the
/// period the packet **started** in, not the date it will be confirmed.
List<CashHandoff> pendingPackets(Iterable<CashDay> days) {
  final seen = <String>{};
  return [
    for (final day in days)
      for (final packet in day.pending)
        if (seen.add(packet.id)) packet,
  ];
}

/// Two tabs: the latest week, and what is still outstanding.
///
/// «Эта неделя» comes first and lists the latest seven days; days that have
/// not happened yet are not listed at all, and the older days of the month sit
/// behind a button that says how many there are. «Ещё не передано» gathers
/// everything that still needs somebody — packets waiting for the
/// accountant, and finished days nobody has handed over — from the last
/// [kArrearsLookbackDays] days whatever month is chosen, and carries its
/// count on the tab so it is never out of sight.
class _CashTabs extends StatelessWidget {
  const _CashTabs({required this.data, required this.onChanged});

  final _CashData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final outstanding = _Outstanding.of(data);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          SegmentedTabBar(
            tabs: [
              SegmentTab(
                App.instance.period.isCurrentMonth
                    ? S.thisWeek
                    : S.lastDays,
                icon: AppIcons.day,
              ),
              SegmentTab(
                outstanding.count == 0
                    ? S.notHandedOver
                    : '${S.notHandedOver} (${outstanding.count})',
                icon: AppIcons.warning,
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _WeekTab(data: data, onChanged: onChanged),
                _OutstandingTab(outstanding: outstanding, onChanged: onChanged),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What still needs somebody, worked out once for both the tab's label and
/// its body.
class _Outstanding {
  const _Outstanding({required this.waiting, required this.unhanded});

  /// Days holding a packet that is waiting for the accountant.
  final List<CashDay> waiting;

  /// Finished days with money outside every packet.
  final List<CashDay> unhanded;

  /// Distinct days, so a day that is both is counted once.
  int get count =>
      {...waiting.map((d) => d.shiftKey), ...unhanded.map((d) => d.shiftKey)}
          .length;

  factory _Outstanding.of(_CashData data) {
    final today = Ashgabat.date(Ashgabat.now());
    final all = data.all;
    int newestFirst(CashDay a, CashDay b) => b.dayKey.compareTo(a.dayKey);
    return _Outstanding(
      waiting: all.where((day) => day.pending.isNotEmpty).toList()
        ..sort(newestFirst),
      unhanded: all
          .where((day) =>
              day.isComplete &&
              day.dayKey != today &&
              (day.availableAmount ?? 0) > 0)
          .toList()
        ..sort(newestFirst),
    );
  }
}

class _WeekTab extends StatefulWidget {
  const _WeekTab({required this.data, required this.onChanged});

  final _CashData data;
  final VoidCallback onChanged;

  @override
  State<_WeekTab> createState() => _WeekTabState();
}

class _WeekTabState extends State<_WeekTab> {
  static const _weekDays = 7;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final today = Ashgabat.date(Ashgabat.now());
    // Newest first, and nothing from the future: ISO dates compare as text.
    final sorted = widget.data.month
        .where((day) => day.dayKey.compareTo(today) <= 0)
        .toList()
      ..sort((a, b) => b.dayKey.compareTo(a.dayKey));
    final week = sorted.take(_weekDays).toList();
    final older = sorted.skip(_weekDays).toList();

    return RefreshIndicator(
      color: kPrimaryColor,
      onRefresh: () async => widget.onChanged(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (sorted.isEmpty)
            CardBox(
              child: Text(
                S.noShifts,
                style: const TextStyle(
                  fontFamily: gilroyRegular,
                  fontSize: 15,
                  color: kMutedColor,
                ),
              ),
            )
          else ...[
            for (final day in week)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DayRow(day: day, onReturn: widget.onChanged),
              ),
            if (older.isNotEmpty) ...[
              const SizedBox(height: 4),
              ShowMoreButton(
                expanded: _expanded,
                label: _expanded
                    ? S.hideOtherDays
                    : S.showOtherDays(older.length),
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
              if (_expanded) ...[
                const SizedBox(height: 14),
                for (final day in older)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DayRow(day: day, onReturn: widget.onChanged),
                  ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _OutstandingTab extends StatelessWidget {
  const _OutstandingTab({required this.outstanding, required this.onChanged});

  final _Outstanding outstanding;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final waiting = outstanding.waiting;
    final unhanded = outstanding.unhanded;
    return RefreshIndicator(
      color: kPrimaryColor,
      onRefresh: () async => onChanged(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (waiting.isEmpty && unhanded.isEmpty)
            CardBox(
              child: Text(
                S.nothingOutstanding,
                style: const TextStyle(
                  fontFamily: gilroyRegular,
                  fontSize: 15,
                  color: kMutedColor,
                ),
              ),
            ),
          if (waiting.isNotEmpty) ...[
            _Heading(S.awaitingConfirmation, count: waiting.length),
            // The money is accepted on the day's own screen, so these are
            // ways in, not buttons: a list that is also a row of confirm
            // buttons is one mis-tap from accepting the wrong day.
            for (final day in waiting)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DayRow(
                  day: day,
                  amount: day.pending.fold<double>(
                    0,
                    (sum, packet) =>
                        sum +
                        (packet.declaredAmount ?? packet.expectedAmount ?? 0),
                  ),
                  pillText: Labels.handoffStatus('SUBMITTED'),
                  pillColor: Labels.handoffStatusColor('SUBMITTED'),
                  onReturn: onChanged,
                ),
              ),
            const SizedBox(height: 12),
          ],
          if (unhanded.isNotEmpty) ...[
            _Heading(S.notHandedOver, count: unhanded.length),
            for (final day in unhanded)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DayRow(
                  day: day,
                  amount: day.availableAmount,
                  onReturn: onChanged,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {this.count});

  final String text;
  final int? count;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 2),
        child: Text(
          count == null ? text : '$text · $count',
          style: const TextStyle(
            fontFamily: gilroyBold,
            fontSize: 18,
            color: kBlackColor,
          ),
        ),
      );
}

/// One day as one line: its date, where its money stands, and its amount.
class DayRow extends StatelessWidget {
  const DayRow({
    super.key,
    required this.day,
    this.amount,
    this.pillText,
    this.pillColor,
    this.onReturn,
  });

  final CashDay day;

  /// The figure to print instead of the day's total — for the list of days
  /// whose money has not been handed over, where what matters is what is
  /// still outside any packet.
  final double? amount;

  /// A caption in place of the day's own state — «Ждёт подтверждения» in the
  /// queue, where the day's state may say something broader.
  final String? pillText;
  final Color? pillColor;

  /// Called when the day's screen is closed, so a packet accepted there is
  /// gone from this list instead of waiting for a manual refresh.
  final VoidCallback? onReturn;

  @override
  Widget build(BuildContext context) {
    final date = Ashgabat.parseDate(day.dayKey);
    final isToday = day.dayKey == Ashgabat.date(Ashgabat.now());
    final label = date == null ? day.dayKey : Ashgabat.dayLabel(date);
    return CardBox(
      padding: const EdgeInsets.all(16),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => DayDetailPage(day: day)),
        );
        onReturn?.call();
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? '${S.todayDay} · $label' : label,
                  style: const TextStyle(
                    fontFamily: gilroySemiBold,
                    fontSize: 16,
                    color: kBlackColor,
                  ),
                ),
                const SizedBox(height: 8),
                Pill(
                  pillText ?? Labels.dayState(day.state),
                  color: pillColor ?? Labels.dayStateColor(day.state),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            Fmt.money(amount ?? day.expectedAmount),
            style: const TextStyle(
              fontFamily: gilroyBold,
              fontSize: 19,
              color: kBlackColor,
            ),
          ),
          const SizedBox(width: 6),
          const AppIcon(AppIcons.forward, size: 18, color: kMutedColor),
        ],
      ),
    );
  }
}
