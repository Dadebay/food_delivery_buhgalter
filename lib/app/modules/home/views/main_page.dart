import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../constants/constants.dart';
import '../../../data/accounting_service.dart';
import '../../../data/app_state.dart';
import '../../../data/ashgabat_time.dart';
import '../../../data/auth_service.dart';
import '../../../data/formatting.dart';
import '../../../data/models/shift.dart';
import '../../../data/strings.dart';
import '../../../widgets/async_loader.dart';
import '../../../widgets/language_action.dart';
import '../../../widgets/month_picker.dart';
import '../../../widgets/ui.dart';
import '../../audit/audit_page.dart';
import '../../carryover/carryover_screen.dart';
import '../../month/month_page.dart';
import '../../orders/orders_page.dart';
import '../../shifts/shifts_page.dart';

/// The home screen, kept to three things: what today owes, what the chosen
/// month brought in, and six doors to the rest.
///
/// The month is a control, so it sits in the app bar next to the language
/// switch and the account. The month chosen there is the month every section
/// loads, and it survives coming back.
class MainPage extends StatelessWidget {
  const MainPage({super.key, required this.onSignedOut});

  final VoidCallback onSignedOut;

  @override
  Widget build(BuildContext context) {
    final period = App.instance.period;
    final language = App.instance.language;
    return Scaffold(
      backgroundColor: kSurfaceColor,
      appBar: AppBar(
        backgroundColor: kSurfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: AnimatedBuilder(
          animation: language,
          builder: (context, _) => Text(
            S.appName,
            style: const TextStyle(
              color: kBlackColor,
              fontFamily: gilroyBold,
              fontSize: 22,
            ),
          ),
        ),
        actions: [
          const MonthAction(),
          const LanguageAction(),
          IconButton(
            onPressed: () => _showAccount(context),
            icon: const AppIcon(AppIcons.person, size: 24),
          ),
          const SizedBox(width: 2),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation:
              Listenable.merge([period, language, App.instance.refresh]),
          builder: (context, _) {
            // Rebuilt with the month so every door carries the current range.
            final range = Period.range(period.fromDate, period.toDate);
            final monthLabel = Ashgabat.monthLabel(period.month);
            return RefreshIndicator(
              color: kPrimaryColor,
              onRefresh: () async => App.instance.refresh.value++,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  const TodayMoneyCard(),
                  const SizedBox(height: 12),
                  _MonthSummary(onTap: () => _open(context, const MonthPage())),
                  const SizedBox(height: 18),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.55,
                    children: [
                      _NavTile(
                        icon: AppIcons.orders,
                        title: S.orders,
                        onTap: () => _open(
                          context,
                          OrdersPage(
                            period: range,
                            basis: OrderBasis.created,
                            title: S.orders,
                            subtitle: monthLabel,
                          ),
                        ),
                      ),
                      _NavTile(
                        icon: AppIcons.shifts,
                        title: S.shiftsMoney,
                        color: kPositiveColor,
                        onTap: () => _open(context, const ShiftsPage()),
                      ),
                      _NavTile(
                        icon: AppIcons.charts,
                        title: S.charts,
                        onTap: () => _open(context, const MonthPage()),
                      ),
                      _NavTile(
                        icon: AppIcons.journal,
                        title: S.journal,
                        onTap: () => _open(
                          context,
                          AuditPage(
                            period: range,
                            title: S.journal,
                            subtitle: monthLabel,
                          ),
                        ),
                      ),
                      _NavTile(
                        icon: AppIcons.carryIn,
                        title: S.carryIn,
                        color: kWarningColor,
                        onTap: () => _open(
                          context,
                          CarryoverScreen(
                            period: range,
                            incoming: true,
                            subtitle: monthLabel,
                          ),
                        ),
                      ),
                      _NavTile(
                        icon: AppIcons.carryOut,
                        title: S.carryOut,
                        color: kWarningColor,
                        onTap: () => _open(
                          context,
                          CarryoverScreen(
                            period: range,
                            incoming: false,
                            subtitle: monthLabel,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Who is signed in and the way out. It lives behind the person icon so the
  /// home screen is not spent on the one thing used least.
  void _showAccount(BuildContext context) {
    final auth = App.instance.auth;
    final name = (auth.displayName ?? '').trim();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.account,
                style: const TextStyle(
                  fontFamily: gilroyBold,
                  fontSize: 19,
                  color: kBlackColor,
                ),
              ),
              const SizedBox(height: 10),
              InfoRow(
                label: S.staff,
                value: name.isEmpty ? (auth.phone ?? kUnknown) : name,
                icon: AppIcons.person,
              ),
              InfoRow(
                label: S.role,
                value: switch (auth.role) {
                  StaffRole.accountant => S.roleAccountant,
                  StaffRole.superAdmin => S.roleOwner,
                  StaffRole.other => kUnknown,
                },
                icon: AppIcons.access,
              ),
              InfoRow(label: S.rights, value: S.rightsValue),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kBorderColor),
                    shape: const RoundedRectangleBorder(
                        borderRadius: borderRadius10),
                  ),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _signOut(context);
                  },
                  icon: const AppIcon(AppIcons.signOut,
                      size: 17, color: kNegativeColor),
                  label: Text(
                    S.signOut,
                    style: const TextStyle(
                      fontFamily: gilroySemiBold,
                      color: kNegativeColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page),
      );

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: borderRadius15),
        title: Text(
          S.signOutQuestion,
          style: const TextStyle(fontFamily: gilroySemiBold, fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child:
                Text(S.cancel, style: const TextStyle(fontFamily: gilroyMedium)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              S.signOut,
              style: const TextStyle(
                  fontFamily: gilroySemiBold, color: kNegativeColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await App.instance.signOut();
    onSignedOut();
  }
}

/// One door to a section: an icon and a name, nothing else. The longer
/// descriptions this replaced said what the section title already said.
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = kPrimaryColor,
  });

  final List<List<dynamic>> icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => CardBox(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppIconBadge(icon, color: color, size: 38),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: gilroySemiBold,
                fontSize: 14.5,
                height: 1.15,
                color: kBlackColor,
              ),
            ),
          ],
        ),
      );
}

/// What the chosen month brought in — the report's `collectedAmount`, the
/// money returned in the month. Tapping it opens the charts.
class _MonthSummary extends StatefulWidget {
  const _MonthSummary({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_MonthSummary> createState() => _MonthSummaryState();
}

class _MonthSummaryState extends State<_MonthSummary> {
  Future<double?>? _future;
  String? _key;

  Future<double?> _load() async {
    final period = App.instance.period;
    final report = await App.instance.accounting
        .report(fromDate: period.fromDate, toDate: period.toDate);
    return report.summary.collectedAmount;
  }

  @override
  Widget build(BuildContext context) {
    final period = App.instance.period;
    final key =
        '${period.fromDate}:${period.toDate}:${App.instance.refreshTick}';
    if (key != _key) {
      _key = key;
      _future = _load();
    }
    return CardBox(
      onTap: widget.onTap,
      padding: const EdgeInsets.all(14),
      child: FutureBuilder<double?>(
        future: _future,
        builder: (context, snapshot) {
          final failed = snapshot.hasError;
          final loading = snapshot.connectionState != ConnectionState.done;
          return Row(
            children: [
              const AppIconBadge(AppIcons.collected,
                  color: kPositiveColor, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${S.monthEarned} · ${Ashgabat.monthLabel(period.month)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: gilroyMedium,
                        fontSize: 12.5,
                        color: kMutedColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      failed
                          ? S.errLoad
                          : loading
                              ? kDash
                              : Fmt.money(snapshot.data),
                      style: TextStyle(
                        fontFamily: gilroyBold,
                        fontSize: 21,
                        color: failed ? kNegativeColor : kPositiveColor,
                      ),
                    ),
                  ],
                ),
              ),
              const AppIcon(AppIcons.forward, size: 18, color: kMutedColor),
            ],
          );
        },
      ),
    );
  }
}

/// «Сегодня нужно сдать» — today's day entry, plus what earlier days still
/// owe: packets waiting for the accountant and money nobody has handed over.
///
/// The figures come from `/days`, which is the only place a day's own money
/// lives; the report is a different question and is never relabelled as this
/// one. The lookback window is a display convenience, not a business rule —
/// an old unconfirmed packet does not stop existing once it falls outside it,
/// it just stops being nagged about on the home page.
class TodayMoneyCard extends StatelessWidget {
  const TodayMoneyCard({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: App.instance.refresh,
        builder: (context, tick, _) {
          // Re-read on every return to the app and at Ashgabat midnight, so
          // "today" never stays on yesterday's date.
          final today = Ashgabat.date(Ashgabat.now());
          final from = Ashgabat.date(
            Ashgabat.now().subtract(const Duration(days: kArrearsLookbackDays)),
          );
          return AsyncLoader<List<CashDay>>(
            requestKey: 'today-$today-$tick-${App.instance.language.current}',
            loading: const _TodaySkeleton(),
            request: () =>
                App.instance.accounting.days(fromDate: from, toDate: today),
            builder: (context, days, reload) {
              CashDay? todays;
              for (final day in days) {
                if (day.dayKey == today) todays = day;
              }

              // Packets waiting for confirmation are decided by their own
              // status; a finished day that still has money outside any
              // packet is the administrator's debt to hand over.
              final waiting = pendingPackets(days);
              final waitingTotal = waiting.fold<double>(
                  0, (total, packet) => total + (packet.expectedAmount ?? 0));
              final unhanded = days
                  .where((day) =>
                      day.dayKey != today &&
                      day.isComplete &&
                      (day.availableAmount ?? 0) > 0)
                  .toList();
              final unhandedTotal = unhanded.fold<double>(
                  0, (total, day) => total + (day.availableAmount ?? 0));

              void openDays() => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ShiftsPage()),
                  );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TodayCard(
                    day: todays,
                    onTap: openDays,
                    onRefresh: reload,
                  ),
                  if (waiting.isNotEmpty || unhanded.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _OverdueCard(
                      waitingTotal: waitingTotal,
                      waitingCount: waiting.length,
                      unhandedTotal: unhandedTotal,
                      unhandedDays: unhanded.length,
                      onTap: openDays,
                    ),
                  ],
                ],
              );
            },
          );
        },
      );
}

/// What earlier days still owe, as a quiet strip under today's figure rather
/// than a second hero. Two lines that mean different things: a packet that
/// was handed over and waits for the accountant, and money that has not been
/// handed over at all.
class _OverdueCard extends StatelessWidget {
  const _OverdueCard({
    required this.waitingTotal,
    required this.waitingCount,
    required this.unhandedTotal,
    required this.unhandedDays,
    required this.onTap,
  });

  final double waitingTotal;
  final int waitingCount;
  final double unhandedTotal;
  final int unhandedDays;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        // ignore: deprecated_member_use
        color: kWarningColor.withOpacity(0.10),
        borderRadius: borderRadius15,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius15,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: borderRadius15,
              // ignore: deprecated_member_use
              border: Border.all(color: kWarningColor.withOpacity(0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppIcon(AppIcons.warning,
                        size: 16, color: kWarningColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        S.overdueTitle,
                        style: const TextStyle(
                          fontFamily: gilroySemiBold,
                          fontSize: 13,
                          color: kWarningColor,
                        ),
                      ),
                    ),
                    const AppIcon(AppIcons.forward,
                        size: 15, color: kWarningColor),
                  ],
                ),
                const SizedBox(height: 8),
                if (waitingCount > 0)
                  _OverdueLine(
                    label: '${S.awaitingConfirmation} · '
                        '${S.packetsCount(waitingCount)}',
                    value: Fmt.money(waitingTotal),
                  ),
                if (unhandedDays > 0)
                  _OverdueLine(
                    label: '${S.notHandedOver} · ${S.daysCount(unhandedDays)}',
                    value: Fmt.money(unhandedTotal),
                  ),
              ],
            ),
          ),
        ),
      );
}

class _OverdueLine extends StatelessWidget {
  const _OverdueLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: gilroyRegular,
                  fontSize: 12.5,
                  color: kBlackColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              value,
              style: const TextStyle(
                fontFamily: gilroySemiBold,
                fontSize: 13.5,
                color: kBlackColor,
              ),
            ),
          ],
        ),
      );
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.day,
    required this.onTap,
    required this.onRefresh,
  });

  /// Today's entry, or null when the server has none for today.
  final CashDay? day;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final empty = day == null;
    return Material(
      color: kPrimaryColor,
      borderRadius: borderRadius20,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius20,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppIcon(AppIcons.handoff, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      empty ? S.today : S.todayToCollect,
                      style: const TextStyle(
                        fontFamily: gilroyMedium,
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onRefresh,
                    borderRadius: borderRadius30,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: AppIcon(AppIcons.refresh,
                          size: 17, color: Colors.white70),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                empty ? S.todayNoShifts : Fmt.money(day!.expectedAmount),
                style: TextStyle(
                  fontFamily: gilroyBold,
                  fontSize: empty ? 18 : 28,
                  color: Colors.white,
                ),
              ),
              if (!empty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Chip(
                      label: S.availableToHandOver,
                      value: Fmt.money(day!.availableAmount),
                    ),
                    const SizedBox(width: 10),
                    _Chip(
                      label: S.records,
                      value: Fmt.count(day!.settlementCount),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.16),
            borderRadius: borderRadius10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: gilroyMedium,
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: gilroySemiBold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
}

class _TodaySkeleton extends StatelessWidget {
  const _TodaySkeleton();

  @override
  Widget build(BuildContext context) => Container(
        height: 132,
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: kPrimaryColor.withOpacity(0.35),
          borderRadius: borderRadius20,
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      );
}
