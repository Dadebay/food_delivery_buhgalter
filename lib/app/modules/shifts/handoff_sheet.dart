import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/constants.dart';
import '../../data/api_client.dart';
import '../../data/app_state.dart';
import '../../data/formatting.dart';
import '../../data/models/shift.dart';
import '../../widgets/state_views.dart';
import '../../widgets/ui.dart';

/// The accountant confirms an existing packet after checking the amount.
///
/// Orders are never moved to `RECONCILED` from here: the server does that for
/// the contents of the confirmed packet. A `409` is shown in the server's own
/// words and the data is re-read — the request is never repeated
/// automatically, and a lost connection means checking the packet's real
/// state before trying again.
Future<void> confirmHandoff(
  BuildContext context, {
  required CashHandoff handoff,
  required VoidCallback onDone,
}) async {
  final note = TextEditingController();
  var busy = false;
  String? error;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Подтвердить сумму пакета',
              style: TextStyle(
                fontFamily: gilroyBold,
                fontSize: 19,
                color: kBlackColor,
              ),
            ),
            const SizedBox(height: 12),
            CardBox(
              child: Column(
                children: [
                  InfoRow(
                    label: 'Ожидаемая сумма',
                    value: Fmt.money(handoff.expectedAmount),
                  ),
                  InfoRow(
                    label: 'Заявлено',
                    value: Fmt.money(handoff.declaredAmount),
                    strong: true,
                  ),
                  InfoRow(
                    label: 'Расхождение',
                    value: Fmt.signedMoney(handoff.discrepancy),
                    valueColor: handoff.discrepancy == null
                        ? kBlackColor
                        : handoff.discrepancy! < 0
                            ? kNegativeColor
                            : kBlackColor,
                  ),
                  InfoRow(
                    label: 'Записей',
                    value: Fmt.count(handoff.settlementCount),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLength: 500,
              maxLines: 3,
              enabled: !busy,
              style: const TextStyle(fontFamily: gilroyMedium, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Комментарий (необязательно)',
                labelStyle: TextStyle(
                    fontFamily: gilroyMedium, color: kMutedColor),
                border: OutlineInputBorder(borderRadius: borderRadius10),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 6),
              Text(
                error!,
                style: const TextStyle(
                  fontFamily: gilroyMedium,
                  fontSize: 13,
                  color: kNegativeColor,
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: kPositiveColor,
                  shape: const RoundedRectangleBorder(
                      borderRadius: borderRadius15),
                ),
                onPressed: busy
                    ? null
                    : () async {
                        setSheetState(() {
                          busy = true;
                          error = null;
                        });
                        try {
                          await App.instance.accounting.confirmHandoff(
                            handoff.id,
                            note: note.text,
                          );
                          if (!sheetContext.mounted) return;
                          Navigator.of(sheetContext).pop();
                          onDone();
                          showSnackBar(
                            context,
                            'Пакет подтверждён',
                            color: kPositiveColor,
                          );
                        } catch (caught) {
                          final conflict = caught is ApiException &&
                              caught.failure == ApiFailure.conflict;
                          final offline = caught is ApiException &&
                              caught.failure == ApiFailure.network;
                          setSheetState(() {
                            busy = false;
                            error = offline
                                ? '${errorMessage(caught)} Сначала проверьте '
                                    'фактическое состояние пакета — операция '
                                    'могла пройти.'
                                : errorMessage(caught);
                          });
                          // A conflict means the data moved on: re-read it
                          // instead of assuming success or retrying.
                          if (conflict) onDone();
                        }
                      },
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Подтвердить',
                        style: TextStyle(
                          fontFamily: gilroySemiBold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Подтверждение сохраняется. Заказы переводит в «Сверен» сервер '
              'для состава этого пакета.',
              style: TextStyle(
                fontFamily: gilroyRegular,
                fontSize: 11.5,
                color: kMutedColor,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  note.dispose();
}

/// Creating a packet belongs to the owner. The button that opens this is
/// hidden from the accountant, and the server refuses it for anyone else.
Future<void> createHandoff(
  BuildContext context, {
  required ShiftSummary shift,
  required VoidCallback onDone,
}) async {
  final declared = TextEditingController();
  final note = TextEditingController();
  var busy = false;
  String? error;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Создать денежный пакет',
              style: TextStyle(
                fontFamily: gilroyBold,
                fontSize: 19,
                color: kBlackColor,
              ),
            ),
            const SizedBox(height: 10),
            CardBox(
              child: Column(
                children: [
                  InfoRow(label: 'Смена', value: shift.shiftKey),
                  InfoRow(
                    label: 'Ожидается к сдаче',
                    value: Fmt.money(shift.expectedAmount),
                    strong: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: declared,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              enabled: !busy,
              style: const TextStyle(fontFamily: gilroySemiBold, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Заявленная сумма (необязательно)',
                labelStyle: TextStyle(
                    fontFamily: gilroyMedium, color: kMutedColor),
                border: OutlineInputBorder(borderRadius: borderRadius10),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: note,
              maxLength: 500,
              maxLines: 2,
              enabled: !busy,
              style: const TextStyle(fontFamily: gilroyMedium, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Комментарий (необязательно)',
                labelStyle: TextStyle(
                    fontFamily: gilroyMedium, color: kMutedColor),
                border: OutlineInputBorder(borderRadius: borderRadius10),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 6),
              Text(
                error!,
                style: const TextStyle(
                  fontFamily: gilroyMedium,
                  fontSize: 13,
                  color: kNegativeColor,
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: const RoundedRectangleBorder(
                      borderRadius: borderRadius15),
                ),
                onPressed: busy
                    ? null
                    : () async {
                        setSheetState(() {
                          busy = true;
                          error = null;
                        });
                        try {
                          await App.instance.accounting.createHandoff(
                            shiftKey: shift.shiftKey,
                            declaredAmount: double.tryParse(
                                declared.text.trim().replaceAll(',', '.')),
                            note: note.text,
                          );
                          if (!sheetContext.mounted) return;
                          Navigator.of(sheetContext).pop();
                          onDone();
                          showSnackBar(context, 'Пакет создан');
                        } catch (caught) {
                          setSheetState(() {
                            busy = false;
                            error = errorMessage(caught);
                          });
                          if (caught is ApiException &&
                              caught.failure == ApiFailure.conflict) {
                            onDone();
                          }
                        }
                      },
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Создать',
                        style: TextStyle(
                          fontFamily: gilroySemiBold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  declared.dispose();
  note.dispose();
}
