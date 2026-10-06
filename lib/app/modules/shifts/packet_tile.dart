import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/constants.dart';
import '../../data/ashgabat_time.dart';
import '../../data/formatting.dart';
import '../../data/labels.dart';
import '../../data/models/shift.dart';
import '../../data/strings.dart';
import '../../widgets/ui.dart';
import 'handoff_sheet.dart';

/// The calendar day a packet's period started on, for a heading.
String packetDayLabel(CashHandoff packet) {
  final start = packet.periodStart;
  if (start != null) return Ashgabat.dayLabel(Ashgabat.toLocal(start));
  final key = (packet.shiftKey ?? '').split(':').first;
  final parsed = Ashgabat.parseDate(key);
  return parsed == null ? kUnknown : Ashgabat.dayLabel(parsed);
}

/// One money packet in plain words: what was handed over, whether the
/// difference matters, and — when it is waiting — one large button.
///
/// The button follows the **packet's own status**, never the day's `state`:
/// a day can keep old packets from the two-shift era while its own `handoff`
/// is null, and each is confirmed by its own id. The fuller picture (period,
/// expected amount, record count, notes) is on the confirmation sheet, which
/// opens before anything is sent.
class PacketTile extends StatelessWidget {
  const PacketTile({
    super.key,
    required this.packet,
    required this.onChanged,
    this.showDay = false,
    this.detailed = false,
  });

  final CashHandoff packet;

  /// Called after the packet changes, so days, report and queue are re-read
  /// rather than patched locally.
  final VoidCallback onChanged;

  /// Print the packet's own day as the heading — for the queue, where
  /// packets of different days sit together.
  final bool showDay;

  /// Who handed it over and who accepted it, for the day's own screen.
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final difference = packet.discrepancy;
    final amount = packet.declaredAmount ?? packet.expectedAmount;
    return CardBox(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  showDay ? packetDayLabel(packet) : S.handedOver,
                  style: const TextStyle(
                    fontFamily: gilroySemiBold,
                    fontSize: 16,
                    color: kBlackColor,
                  ),
                ),
              ),
              Pill(
                Labels.handoffStatus(packet.status),
                color: Labels.handoffStatusColor(packet.status),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            Fmt.money(amount),
            style: const TextStyle(
              fontFamily: gilroyBold,
              fontSize: 26,
              color: kBlackColor,
            ),
          ),
          if (difference != null && difference != 0) ...[
            const SizedBox(height: 6),
            Text(
              '${S.difference}: ${Fmt.signedMoney(difference)}',
              style: TextStyle(
                fontFamily: gilroySemiBold,
                fontSize: 14.5,
                color: difference < 0 ? kNegativeColor : kWarningColor,
              ),
            ),
          ],
          if (detailed) ...[
            const SizedBox(height: 8),
            if (packet.submittedBy != null)
              _Line(
                '${S.handedBy}: ${packet.submittedBy!.fullName}'
                '${_when(packet.submittedAt)}',
              ),
            if (packet.isConfirmed && packet.confirmedBy != null)
              _Line(
                '${S.acceptedBy}: ${packet.confirmedBy!.fullName}'
                '${_when(packet.confirmedAt)}',
              ),
            if ((packet.note ?? '').trim().isNotEmpty)
              _Line(packet.note!.trim()),
            if ((packet.confirmationNote ?? '').trim().isNotEmpty)
              _Line(packet.confirmationNote!.trim()),
          ],
          if (packet.isSubmitted) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: kPositiveColor,
                  shape: const RoundedRectangleBorder(
                      borderRadius: borderRadius15),
                ),
                onPressed: () => confirmHandoff(
                  context,
                  handoff: packet,
                  onDone: onChanged,
                ),
                icon: const AppIcon(AppIcons.confirmed,
                    size: 22, color: Colors.white),
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
          ],
        ],
      ),
    );
  }

  static String _when(DateTime? instant) {
    final label = Ashgabat.dateTimeLabel(instant);
    return label == null ? '' : ' · $label';
  }
}

class _Line extends StatelessWidget {
  const _Line(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: gilroyRegular,
            fontSize: 13.5,
            color: kMutedColor,
          ),
        ),
      );
}
