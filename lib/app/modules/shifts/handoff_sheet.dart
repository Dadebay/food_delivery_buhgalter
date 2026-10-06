import 'package:flutter/material.dart';

import '../../constants/constants.dart';
import '../../data/api_client.dart';
import '../../data/app_state.dart';
import '../../data/ashgabat_time.dart';
import '../../data/formatting.dart';
import '../../data/models/shift.dart';
import '../../data/strings.dart';
import '../../widgets/state_views.dart';
import '../../widgets/ui.dart';

const _sheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
);

const _titleStyle = TextStyle(
  fontFamily: gilroyBold,
  fontSize: 19,
  color: kBlackColor,
);

const _errorStyle = TextStyle(
  fontFamily: gilroyMedium,
  fontSize: 13,
  color: kNegativeColor,
);

Widget _spinner() => const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );

/// The accountant confirms one existing packet after checking the amount.
///
/// Everything the decision rests on is shown first — the packet's own period,
/// what the system expected, what the sender declared and the difference
/// between them — and the difference never blocks the button: the server
/// accepts it, and hiding it would be the one dishonest thing this sheet
/// could do.
///
/// Orders are never moved to `RECONCILED` from here: the server does that for
/// the contents of the packet. The request carries only the optional `note`.
/// A `409` is shown in the server's own words and the data is re-read — the
/// request is never repeated automatically, and a lost connection means
/// checking the packet's real state before trying again.
Future<void> confirmHandoff(
  BuildContext context, {
  required CashHandoff handoff,
  required VoidCallback onDone,
}) async {
  final note = TextEditingController();
  var busy = false;
  String? error;
  final discrepancy = handoff.discrepancy;
  final period = Ashgabat.periodLabel(handoff.periodStart, handoff.periodEnd);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: _sheetShape,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => SafeArea(
        child: SingleChildScrollView(
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
              Text(S.confirmPacketTitle, style: _titleStyle),
              const SizedBox(height: 12),
              CardBox(
                child: Column(
                  children: [
                    InfoRow(
                      label: S.periodLabel,
                      value: period ?? handoff.shiftKey ?? kUnknown,
                    ),
                    InfoRow(
                      label: S.expectedAmount,
                      value: Fmt.money(handoff.expectedAmount),
                    ),
                    InfoRow(
                      label: S.declared,
                      value: Fmt.money(handoff.declaredAmount),
                      strong: true,
                    ),
                    InfoRow(
                      label: discrepancy == null || discrepancy == 0
                          ? S.discrepancy
                          : discrepancy < 0
                              ? S.shortfall
                              : S.surplus,
                      value: Fmt.signedMoney(discrepancy),
                      valueColor: discrepancy == null || discrepancy == 0
                          ? kBlackColor
                          : discrepancy < 0
                              ? kNegativeColor
                              : kWarningColor,
                    ),
                    InfoRow(
                      label: S.records,
                      value: Fmt.count(handoff.settlementCount),
                    ),
                    InfoRow(
                      label: S.submittedBy,
                      value: handoff.submittedBy?.fullName ?? kUnknown,
                    ),
                    InfoRow(
                      label: S.submittedAt,
                      value:
                          Ashgabat.dateTimeLabel(handoff.submittedAt) ?? kUnknown,
                    ),
                    if ((handoff.note ?? '').trim().isNotEmpty)
                      InfoRow(
                        label: S.packetAuthorNote,
                        value: handoff.note!.trim(),
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
                decoration: InputDecoration(
                  labelText: '${S.accountantNote} (${S.noteOptional})',
                  labelStyle: const TextStyle(
                      fontFamily: gilroyMedium, color: kMutedColor),
                  border:
                      const OutlineInputBorder(borderRadius: borderRadius10),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 6),
                Text(error!, style: _errorStyle),
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
                              S.packetConfirmed,
                              color: kPositiveColor,
                            );
                          } catch (caught) {
                            final conflict = caught is ApiException &&
                                caught.failure == ApiFailure.conflict;
                            final offline = caught is ApiException &&
                                caught.failure == ApiFailure.network;
                            if (!sheetContext.mounted) return;
                            setSheetState(() {
                              busy = false;
                              error = offline
                                  ? '${errorMessage(caught)} ${S.checkPacketFirst}'
                                  : errorMessage(caught);
                            });
                            // A conflict means the data moved on (already
                            // confirmed, say): re-read it instead of
                            // assuming success or retrying.
                            if (conflict) onDone();
                          }
                        },
                  child: busy
                      ? _spinner()
                      : Text(
                          S.confirmReceipt,
                          style: const TextStyle(
                            fontFamily: gilroySemiBold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                S.confirmNote,
                style: const TextStyle(
                  fontFamily: gilroyRegular,
                  fontSize: 11.5,
                  color: kMutedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  note.dispose();
}

/// The owner hands a **finished** day's money to the accountant. The button
/// that opens this is hidden from the accountant, the server refuses it for
/// anyone else, and it never appears for a day that has not ended yet.
///
/// No order list, expected amount, status or version is sent: the server
/// takes every suitable money record of the day that no other packet holds.
Future<void> createHandoff(
  BuildContext context, {
  required CashDay day,
  required VoidCallback onDone,
}) async {
  final declared = TextEditingController();
  final note = TextEditingController();
  var busy = false;
  String? error;

  /// Null means "not given — let the server use the expected amount"; the
  /// returned flag says whether what was typed is acceptable at all.
  (double?, bool) parseDeclared() {
    final raw = declared.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return (null, true);
    if (!RegExp(r'^\d{1,8}(\.\d{1,2})?$').hasMatch(raw)) return (null, false);
    return (double.parse(raw), true);
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: _sheetShape,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => SafeArea(
        child: SingleChildScrollView(
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
              Text(S.createPacketTitle, style: _titleStyle),
              const SizedBox(height: 10),
              CardBox(
                child: Column(
                  children: [
                    InfoRow(label: S.day, value: day.dayKey),
                    InfoRow(
                      label: S.expected,
                      value: Fmt.money(day.availableAmount),
                      strong: true,
                    ),
                    InfoRow(
                      label: S.records,
                      value: Fmt.count(day.settlementCount),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                S.createPacketNote,
                style: const TextStyle(
                  fontFamily: gilroyRegular,
                  fontSize: 11.5,
                  color: kMutedColor,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: declared,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                enabled: !busy,
                style:
                    const TextStyle(fontFamily: gilroySemiBold, fontSize: 14),
                decoration: InputDecoration(
                  labelText: S.declaredOptional,
                  labelStyle: const TextStyle(
                      fontFamily: gilroyMedium, color: kMutedColor),
                  border:
                      const OutlineInputBorder(borderRadius: borderRadius10),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                maxLength: 500,
                maxLines: 2,
                enabled: !busy,
                style: const TextStyle(fontFamily: gilroyMedium, fontSize: 14),
                decoration: InputDecoration(
                  labelText: S.noteOptional,
                  labelStyle: const TextStyle(
                      fontFamily: gilroyMedium, color: kMutedColor),
                  border:
                      const OutlineInputBorder(borderRadius: borderRadius10),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 6),
                Text(error!, style: _errorStyle),
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
                          final (amount, valid) = parseDeclared();
                          if (!valid) {
                            setSheetState(
                                () => error = S.declaredAmountError);
                            return;
                          }
                          setSheetState(() {
                            busy = true;
                            error = null;
                          });
                          try {
                            await App.instance.accounting.createHandoff(
                              shiftKey: day.shiftKey,
                              declaredAmount: amount,
                              note: note.text,
                            );
                            if (!sheetContext.mounted) return;
                            Navigator.of(sheetContext).pop();
                            onDone();
                            showSnackBar(context, S.packetCreated);
                          } catch (caught) {
                            final conflict = caught is ApiException &&
                                caught.failure == ApiFailure.conflict;
                            final offline = caught is ApiException &&
                                caught.failure == ApiFailure.network;
                            if (!sheetContext.mounted) return;
                            setSheetState(() {
                              busy = false;
                              error = offline
                                  ? '${errorMessage(caught)} ${S.checkPacketFirst}'
                                  : errorMessage(caught);
                            });
                            if (conflict) onDone();
                          }
                        },
                  child: busy
                      ? _spinner()
                      : Text(
                          S.create,
                          style: const TextStyle(
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
    ),
  );
  declared.dispose();
  note.dispose();
}

/// The owner takes a finished day's money in one step: the packet is created
/// and confirmed back to back. Only `SUPER_ADMIN` can do both — the server
/// refuses a packet from an accountant and a confirmation from a plain
/// administrator.
///
/// These are two requests, not one transaction. If the second fails the first
/// has already happened: the packet exists, is waiting for confirmation and
/// shows its own button on the day's screen, so nothing is created twice and
/// nothing is lost. The sheet says so instead of retrying either request.
Future<void> receiveDay(
  BuildContext context, {
  required CashDay day,
  required VoidCallback onDone,
}) async {
  final note = TextEditingController();
  var busy = false;
  String? error;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: _sheetShape,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => SafeArea(
        child: SingleChildScrollView(
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
              Text(S.receiveDayTitle, style: _titleStyle),
              const SizedBox(height: 12),
              CardBox(
                child: Column(
                  children: [
                    InfoRow(label: S.day, value: day.dayKey),
                    InfoRow(
                      label: S.expected,
                      value: Fmt.money(day.availableAmount),
                      strong: true,
                    ),
                    InfoRow(
                      label: S.records,
                      value: Fmt.count(day.settlementCount),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                S.receiveDayNote,
                style: const TextStyle(
                  fontFamily: gilroyRegular,
                  fontSize: 12,
                  color: kMutedColor,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                maxLength: 500,
                maxLines: 2,
                enabled: !busy,
                style: const TextStyle(fontFamily: gilroyMedium, fontSize: 14),
                decoration: InputDecoration(
                  labelText: S.noteOptional,
                  labelStyle: const TextStyle(
                      fontFamily: gilroyMedium, color: kMutedColor),
                  border:
                      const OutlineInputBorder(borderRadius: borderRadius10),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 6),
                Text(error!, style: _errorStyle),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 54,
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
                          var created = false;
                          try {
                            final packet =
                                await App.instance.accounting.createHandoff(
                              shiftKey: day.shiftKey,
                              note: note.text,
                            );
                            created = packet != null;
                            if (packet == null) throw StateError('no packet');
                            await App.instance.accounting
                                .confirmHandoff(packet.id);
                            if (!sheetContext.mounted) return;
                            Navigator.of(sheetContext).pop();
                            onDone();
                            showSnackBar(
                              context,
                              S.packetConfirmed,
                              color: kPositiveColor,
                            );
                          } catch (caught) {
                            final conflict = caught is ApiException &&
                                caught.failure == ApiFailure.conflict;
                            if (!sheetContext.mounted) return;
                            setSheetState(() {
                              busy = false;
                              error = created
                                  ? '${errorMessage(caught)} ${S.checkPacketFirst}'
                                  : errorMessage(caught);
                            });
                            // Either the day moved on or the packet exists
                            // already: re-read, never repeat.
                            if (conflict || created) onDone();
                          }
                        },
                  child: busy
                      ? _spinner()
                      : Text(
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
          ),
        ),
      ),
    ),
  );
  note.dispose();
}
