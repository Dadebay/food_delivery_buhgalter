import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/constants.dart';
import '../../data/accounting_service.dart';
import '../../data/app_state.dart';
import '../../data/ashgabat_time.dart';
import '../../data/auth_service.dart';
import '../../data/formatting.dart';
import '../../data/labels.dart';
import '../../data/models/shift.dart';
import '../../data/strings.dart';
import '../../widgets/ui.dart';
import '../audit/audit_page.dart';
import '../orders/orders_page.dart';
import 'handoff_sheet.dart';
import 'packet_tile.dart';

/// One day, opened by its `shiftKey` (`2026-10-04:day`).
///
/// Kept to what the accountant does with a day: see its amount, accept the
/// money that was handed over, and open the orders behind the number. The
/// figures are this day's own entry from `/days` — never a report total
/// relabelled. `orders` and `audit` accept the key directly; `report` and
/// `days` do not, so they are not asked for it.
class DayDetailPage extends StatefulWidget {
  const DayDetailPage({super.key, required this.day});

  final CashDay day;

  @override
  State<DayDetailPage> createState() => _DayDetailPageState();
}

class _DayDetailPageState extends State<DayDetailPage> {
  late CashDay _day = widget.day;

  Period get _period => Period.shift(_day.shiftKey);

  /// Re-reads this day from `/days`, which is how a confirmed packet gets its
  /// new state without being patched here.
  Future<void> _reload() async {
    final key = _day.dayKey;
    try {
      final days = await App.instance.accounting.days(fromDate: key, toDate: key);
      for (final day in days) {
        if (day.shiftKey == _day.shiftKey && mounted) {
          setState(() => _day = day);
          return;
        }
      }
    } catch (_) {
      // A failed refresh must not replace what is on screen with a guess.
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = Ashgabat.parseDate(_day.dayKey);
    final title = date == null ? _day.dayKey : Ashgabat.dayLabel(date);
    return AppScaffold(
      title: title,
      subtitle: S.shiftsMoney,
      child: RefreshIndicator(
        color: kPrimaryColor,
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _Summary(day: _day),
            for (final packet in _day.packets) ...[
              const SizedBox(height: 12),
              PacketTile(packet: packet, onChanged: _reload, detailed: true),
            ],
            if (_day.canCreatePacket && App.instance.auth.role.canCreateHandoff) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kPositiveColor,
                    shape: const RoundedRectangleBorder(borderRadius: borderRadius15),
                  ),
                  onPressed: () => receiveDay(context, day: _day, onDone: _reload),
                  icon: const AppIcon(AppIcons.confirmed, size: 22, color: Colors.white),
                  label: Text(
                    S.confirmAmount,
                    style: const TextStyle(
                      fontFamily: gilroyBold,
                      fontSize: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kBorderColor),
                    shape: const RoundedRectangleBorder(borderRadius: borderRadius15),
                  ),
                  onPressed: () => createHandoff(context, day: _day, onDone: _reload),
                  icon: const AppIcon(AppIcons.handoff, size: 20),
                  label: Text(
                    S.createPacket,
                    style: const TextStyle(
                      fontFamily: gilroySemiBold,
                      fontSize: 15,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
              ),
            ] else if (_day.isComplete && _day.handoff == null && (_day.availableAmount ?? 0) > 0) ...[
              // An accountant cannot create a packet — the server refuses it
              // — so there is nothing to accept yet. Say so instead of
              // leaving a button that can only fail.
              const SizedBox(height: 12),
              NoticeBox(S.waitForHandoff, color: kPrimaryColor),
            ],
            const SizedBox(height: 20),
            _Door(
              icon: AppIcons.money,
              color: kPositiveColor,
              title: S.moneyOfDay,
              onTap: () => _open(
                OrdersPage(
                  period: _period,
                  basis: OrderBasis.cashReturned,
                  title: title,
                  subtitle: S.moneyOfDay,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _Door(
              icon: AppIcons.orders,
              title: S.shiftOrders,
              onTap: () => _open(
                OrdersPage(
                  period: _period,
                  basis: OrderBasis.created,
                  title: title,
                  subtitle: S.shiftOrders,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _Door(
              icon: AppIcons.journal,
              title: S.shiftJournal,
              onTap: () => _open(
                AuditPage(
                  period: _period,
                  title: S.shiftJournal,
                  subtitle: title,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(Widget page) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page),
      );
}

/// The day's amount and where its money stands, and nothing else.
class _Summary extends StatelessWidget {
  const _Summary({required this.day});

  final CashDay day;

  @override
  Widget build(BuildContext context) => CardBox(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Pill(
              Labels.dayState(day.state),
              color: Labels.dayStateColor(day.state),
            ),
            const SizedBox(height: 12),
            Text(
              Fmt.money(day.expectedAmount),
              style: const TextStyle(
                fontFamily: gilroyBold,
                fontSize: 30,
                color: kBlackColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              S.collectedInShift,
              style: const TextStyle(
                fontFamily: gilroyRegular,
                fontSize: 14,
                color: kMutedColor,
              ),
            ),
            if ((day.availableAmount ?? 0) > 0 && day.isComplete) ...[
              const Divider(height: 24, color: kBorderColor),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      S.availableToHandOver,
                      style: const TextStyle(
                        fontFamily: gilroyMedium,
                        fontSize: 15,
                        color: kBlackColor,
                      ),
                    ),
                  ),
                  Text(
                    Fmt.money(day.availableAmount),
                    style: const TextStyle(
                      fontFamily: gilroyBold,
                      fontSize: 16,
                      color: kWarningColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
}

/// A large, single-line way into one list.
class _Door extends StatelessWidget {
  const _Door({
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AppIconBadge(icon, color: color, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: gilroySemiBold,
                  fontSize: 16.5,
                  color: kBlackColor,
                ),
              ),
            ),
            const AppIcon(AppIcons.forward, size: 18, color: kMutedColor),
          ],
        ),
      );
}
