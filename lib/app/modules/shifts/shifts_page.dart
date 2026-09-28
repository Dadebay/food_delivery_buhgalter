import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/constants.dart';
import '../../data/app_state.dart';
import '../../data/ashgabat_time.dart';
import '../../data/formatting.dart';
import '../../data/labels.dart';
import '../../data/models/shift.dart';
import '../../widgets/async_loader.dart';
import '../../widgets/month_bar.dart';
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
    return AnimatedBuilder(
      animation: period,
      builder: (context, _) => AppScaffold(
        title: 'Смены и деньги',
        subtitle: 'Суммы к сдаче и переданные пакеты',
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const MonthBar(),
                const SizedBox(height: 14),
                if (data.shifts.isEmpty)
                  const EmptyShifts()
                else
                  for (final entry in data.grouped.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 8),
                      child: Text(
                        _dayTitle(entry.key),
                        style: const TextStyle(
                          fontFamily: gilroyBold,
                          fontSize: 15,
                          color: kBlackColor,
                        ),
                      ),
                    ),
                    for (final shift in entry.value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ShiftCard(
                          shift: shift,
                          settings: data.settings,
                          onChanged: reload,
                        ),
                      ),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _dayTitle(String dayKey) {
    final parsed = Ashgabat.parseDate(dayKey);
    return parsed == null ? dayKey : Ashgabat.dayLabel(parsed, kLocale);
  }
}

class _ShiftsData {
  const _ShiftsData({required this.shifts, this.settings});

  final List<ShiftSummary> shifts;
  final AccountingSettings? settings;

  /// Two shifts under one calendar day, in the order the server sent them.
  Map<String, List<ShiftSummary>> get grouped {
    final result = <String, List<ShiftSummary>>{};
    for (final shift in shifts) {
      result.putIfAbsent(shift.dayKey, () => []).add(shift);
    }
    return result;
  }
}

class EmptyShifts extends StatelessWidget {
  const EmptyShifts({super.key});

  @override
  Widget build(BuildContext context) => const CardBox(
        child: Text(
          'За выбранный месяц смен нет.',
          style: TextStyle(
            fontFamily: gilroyRegular,
            fontSize: 13.5,
            color: kMutedColor,
          ),
        ),
      );
}

class ShiftCard extends StatelessWidget {
  const ShiftCard({
    super.key,
    required this.shift,
    required this.settings,
    required this.onChanged,
  });

  final ShiftSummary shift;
  final AccountingSettings? settings;

  /// Called after a packet is confirmed, so the shifts, the report and the
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
    final name = shift.name ??
        settings?.nameFor(shift.slot) ??
        Labels.shiftSlot(shift.slot);
    final window = () {
      final start = Ashgabat.timeLabel(shift.startsAt);
      final end = Ashgabat.timeLabel(shift.endsAt);
      if (start != null && end != null) return '$start – $end';
      final configured = definition?.window ?? '';
      return configured.isEmpty ? null : configured;
    }();

    return CardBox(
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
              AppIconBadge(AppIcons.shifts, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: gilroySemiBold,
                        fontSize: 15.5,
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
              Pill(
                Labels.handoffStatus(handoff?.status),
                color: Labels.handoffStatusColor(handoff?.status),
                icon: AppIcons.handoff,
              ),
            ],
          ),
          const SizedBox(height: 10),
          InfoRow(
            label: 'Заказов',
            value: Fmt.count(shift.orderCount),
            icon: AppIcons.orders,
          ),
          InfoRow(
            label: 'Получено в смену',
            value: Fmt.money(shift.collectedAmount),
            icon: AppIcons.collected,
          ),
          InfoRow(
            label: 'Ожидается к сдаче',
            value: Fmt.money(shift.expectedAmount),
            icon: AppIcons.handoff,
            strong: true,
          ),
          if (handoff != null) ...[
            const Divider(height: 18, color: kBorderColor),
            InfoRow(
              label: 'Заявлено',
              value: Fmt.money(handoff.declaredAmount),
            ),
            InfoRow(
              label: 'Расхождение',
              value: Fmt.signedMoney(handoff.discrepancy),
              valueColor: handoff.discrepancy == null
                  ? kBlackColor
                  : handoff.discrepancy! < 0
                      ? kNegativeColor
                      : handoff.discrepancy! > 0
                          ? kWarningColor
                          : kPositiveColor,
            ),
            InfoRow(
              label: 'Передал',
              value: handoff.submittedBy?.fullName ?? kUnknown,
              icon: AppIcons.person,
            ),
            if (handoff.isConfirmed)
              InfoRow(
                label: 'Подтвердил',
                value: handoff.confirmedBy?.fullName ?? kUnknown,
                icon: AppIcons.confirmed,
              ),
            if (!handoff.isConfirmed) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kPositiveColor,
                    shape: const RoundedRectangleBorder(
                        borderRadius: borderRadius10),
                  ),
                  onPressed: () => confirmHandoff(
                    context,
                    handoff: handoff,
                    onDone: onChanged,
                  ),
                  icon: const AppIcon(AppIcons.confirmed,
                      size: 18, color: Colors.white),
                  label: const Text(
                    'Подтвердить сумму',
                    style: TextStyle(
                      fontFamily: gilroySemiBold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ] else if (App.instance.auth.role.canCreateHandoff) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kBorderColor),
                  shape: const RoundedRectangleBorder(
                      borderRadius: borderRadius10),
                ),
                onPressed: () => createHandoff(
                  context,
                  shift: shift,
                  onDone: onChanged,
                ),
                icon: const AppIcon(AppIcons.handoff, size: 18),
                label: const Text(
                  'Создать пакет',
                  style: TextStyle(
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
