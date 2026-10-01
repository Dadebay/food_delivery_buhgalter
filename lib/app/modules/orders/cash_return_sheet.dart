import 'package:flutter/material.dart';

import '../../constants/constants.dart';
import '../../data/api_client.dart';
import '../../data/app_state.dart';
import '../../data/formatting.dart';
import '../../data/models/order.dart';
import '../../data/strings.dart';
import '../../widgets/state_views.dart';
import '../../widgets/ui.dart';

/// The owner marks an order's cash as returned when the courier's own app
/// never confirmed it. This is a stand-in for that confirmation, not a
/// replacement — the server still creates the money record itself from
/// `total - deliveryFee` and nothing in this sheet can change that amount.
///
/// On a `409` the order moved on already: the caller is told to re-read it
/// rather than having the request repeated automatically, same as the
/// handoff confirmation.
Future<void> markCashReturned(
  BuildContext context, {
  required OrderDetail order,
  required VoidCallback onDone,
}) async {
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
            Text(
              S.markCashReturnedTitle,
              style: const TextStyle(
                fontFamily: gilroyBold,
                fontSize: 19,
                color: kBlackColor,
              ),
            ),
            const SizedBox(height: 12),
            CardBox(
              child: Column(
                children: [
                  InfoRow(label: S.order, value: Fmt.orderNumber(order.number)),
                  InfoRow(
                    label: S.foodAmount,
                    value: Fmt.money(order.foodAmount),
                    strong: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              S.markCashReturnedNote,
              style: const TextStyle(
                fontFamily: gilroyRegular,
                fontSize: 12,
                color: kMutedColor,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
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
                onPressed: busy || order.version == null
                    ? null
                    : () async {
                        setSheetState(() {
                          busy = true;
                          error = null;
                        });
                        try {
                          await App.instance.accounting.markCashReturned(
                            order.id,
                            version: order.version!,
                          );
                          if (!sheetContext.mounted) return;
                          Navigator.of(sheetContext).pop();
                          onDone();
                          showSnackBar(
                            context,
                            S.cashReturnedMarked,
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
                                ? '${errorMessage(caught)} ${S.checkOrderFirst}'
                                : errorMessage(caught);
                          });
                          // A conflict means the order moved on: re-read it
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
                    : Text(
                        S.markCashReturned,
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
  );
}
