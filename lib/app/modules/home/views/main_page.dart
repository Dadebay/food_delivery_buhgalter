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

/// The overview: what today owes, then the sections.
///
/// The month is a control, so it sits in the app bar next to the language
/// switch rather than taking a block of the page. The month chosen there is
/// the month every section loads, and it survives coming back.
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
        actions: const [
          MonthAction(),
          LanguageAction(),
          SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([period, language]),
          builder: (context, _) {
            // Rebuilt with the month so every card carries the current range.
            final range = Period.range(period.fromDate, period.toDate);
            final monthLabel = Ashgabat.monthLabel(period.month);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              children: [
                const TodayMoneyCard(),
                const SizedBox(height: 18),
                Text(
                  S.overview,
                  style: const TextStyle(
                    color: kBlackColor,
                    fontFamily: gilroyBold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$monthLabel · ${S.overviewSubtitle}',
                  style: const TextStyle(
                    color: kMutedColor,
                    fontFamily: gilroyMedium,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                SectionCard(
                  icon: AppIcons.orders,
                  title: S.orders,
                  subtitle: S.ordersSub,
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
                const SizedBox(height: 10),
                SectionCard(
                  icon: AppIcons.shifts,
                  title: S.shiftsMoney,
                  subtitle: S.shiftsMoneySub,
                  color: kPositiveColor,
                  onTap: () => _open(context, const ShiftsPage()),
                ),
                const SizedBox(height: 10),
                SectionCard(
                  icon: AppIcons.charts,
                  title: S.charts,
                  subtitle: S.chartsSub,
                  onTap: () => _open(context, const MonthPage()),
                ),
                const SizedBox(height: 10),
                SectionCard(
                  icon: AppIcons.journal,
                  title: S.journal,
                  subtitle: S.journalSub,
                  onTap: () => _open(
                    context,
                    AuditPage(
                      period: range,
                      title: S.journal,
                      subtitle: monthLabel,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SectionCard(
                  icon: AppIcons.carryIn,
                  title: S.carryIn,
                  subtitle: S.carryInSub,
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
                const SizedBox(height: 10),
                SectionCard(
                  icon: AppIcons.carryOut,
                  title: S.carryOut,
                  subtitle: S.carryOutSub,
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
                SectionTitle(S.account, icon: AppIcons.access),
                _account(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _account(BuildContext context) {
    final auth = App.instance.auth;
    final name = (auth.displayName ?? '').trim();
    return CardBox(
      child: Column(
        children: [
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
          // The accountant gets a view, not the right to edit or cancel.
          InfoRow(label: S.rights, value: S.rightsValue),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kBorderColor),
                shape:
                    const RoundedRectangleBorder(borderRadius: borderRadius10),
              ),
              onPressed: () => _signOut(context),
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

/// «Сегодня нужно сдать» — today's shifts, summed from their own entries.
///
/// The figures come from `/shifts` for today's calendar date, which is the
/// only place a shift's own money lives; a whole day's `/report` is a
/// different question and is never relabelled as this one.
class TodayMoneyCard extends StatelessWidget {
  const TodayMoneyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final today = Ashgabat.date(Ashgabat.now());
    return AsyncLoader<List<ShiftSummary>>(
      requestKey: 'today-$today-${App.instance.language.current}',
      loading: const _TodaySkeleton(),
      request: () => App.instance.accounting
          .shifts(fromDate: today, toDate: today),
      builder: (context, shifts, reload) {
        double? sum(double? Function(ShiftSummary) pick) {
          double? total;
          for (final shift in shifts) {
            final value = pick(shift);
            if (value == null) continue;
            total = (total ?? 0) + value;
          }
          return total;
        }

        final expected = sum((shift) => shift.expectedAmount);
        final collected = sum((shift) => shift.collectedAmount);
        final remaining = expected == null || collected == null
            ? null
            : expected - collected;

        return _TodayCard(
          empty: shifts.isEmpty,
          expected: expected,
          collected: collected,
          remaining: remaining,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ShiftsPage()),
          ),
          onRefresh: reload,
        );
      },
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.empty,
    required this.expected,
    required this.collected,
    required this.remaining,
    required this.onTap,
    required this.onRefresh,
  });

  final bool empty;
  final double? expected;
  final double? collected;
  final double? remaining;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Material(
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
                    const AppIcon(AppIcons.handoff,
                        size: 18, color: Colors.white),
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
                  empty ? S.todayNoShifts : Fmt.money(expected),
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
                      _Chip(label: S.todayCollected, value: Fmt.money(collected)),
                      const SizedBox(width: 10),
                      _Chip(
                        label: S.todayRemaining,
                        value: Fmt.money(remaining),
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
