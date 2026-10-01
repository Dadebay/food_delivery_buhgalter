import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/constants.dart';
import '../../data/app_state.dart';
import '../../data/ashgabat_time.dart';
import '../../data/auth_service.dart';
import '../../data/formatting.dart';
import '../../data/labels.dart';
import '../../data/models/audit.dart';
import '../../data/models/order.dart';
import '../../data/strings.dart';
import '../../widgets/async_loader.dart';
import '../../widgets/paged_list.dart';
import '../../widgets/ui.dart';
import '../audit/audit_tile.dart';
import 'cash_return_sheet.dart';

/// One order, in three readings: what it is, what it cost, and what happened
/// to it.
///
/// The order is fetched once for the whole screen — the card and the receipt
/// are two views of the same answer, not two requests. The history tab uses
/// `/orders/:id/audit`, which is deliberately not limited by the dates chosen
/// elsewhere in the app: an order's story is its own, whatever month the
/// accountant happens to be looking at.
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: App.instance.language,
        builder: (context, _) => DefaultTabController(
          length: 3,
          child: AppScaffold(
            title: S.order,
            subtitle: S.orderDetailsSub,
            bottom: SegmentedTabBar(
              tabs: [
                SegmentTab(S.orderTabOrder, icon: AppIcons.orders),
                SegmentTab(S.orderTabReceipt, icon: AppIcons.money),
                SegmentTab(S.orderTabHistory, icon: AppIcons.history),
              ],
            ),
            child: AsyncLoader<OrderDetail>(
              requestKey: orderId,
              request: () => App.instance.accounting.order(orderId),
              builder: (context, order, reload) => TabBarView(
                children: [
                  _OrderTab(order: order, reload: reload),
                  _ReceiptTab(order: order, reload: reload),
                  _HistoryTab(orderId: orderId),
                ],
              ),
            ),
          ),
        ),
      );
}

/// The scrollable body every tab shares, so pull-to-refresh behaves the same
/// on each of them.
class _Refreshable extends StatelessWidget {
  const _Refreshable({required this.reload, required this.children});

  final VoidCallback reload;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        color: kPrimaryColor,
        onRefresh: () async => reload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          physics: const AlwaysScrollableScrollPhysics(),
          children: children,
        ),
      );
}

// ── Tab 1: the order itself ─────────────────────────────────────────────

class _OrderTab extends StatelessWidget {
  const _OrderTab({required this.order, required this.reload});

  final OrderDetail order;
  final VoidCallback reload;

  @override
  Widget build(BuildContext context) => _Refreshable(
        reload: reload,
        children: [
          _StatusHeader(order: order),
          const SizedBox(height: 12),
          CardBox(
            child: Column(
              children: [
                InfoRow(
                  label: S.created,
                  value: Ashgabat.dateTimeLabel(order.createdAt) ?? kUnknown,
                  icon: AppIcons.day,
                ),
                InfoRow(
                  label: S.source,
                  value: Labels.orderSource(order.source),
                  icon: AppIcons.orders,
                ),
                if ((order.branchName ?? '').isNotEmpty)
                  InfoRow(
                    label: S.kitchen,
                    value: order.branchName!,
                    icon: AppIcons.branch,
                  ),
                InfoRow(
                  label: S.district,
                  // Districts come from the names saved on the order; an
                  // unknown one is shown as unknown rather than guessed from
                  // the address.
                  value: Fmt.text(order.deliveryEtrapName),
                  icon: AppIcons.address,
                ),
              ],
            ),
          ),

          SectionTitle(S.customer, icon: AppIcons.customer),
          CardBox(
            child: Column(
              children: [
                InfoRow(
                    label: S.name,
                    value: Fmt.text(order.customerName),
                    icon: AppIcons.customer),
                InfoRow(
                    label: S.phone,
                    value: Fmt.text(order.customerPhone),
                    icon: AppIcons.phone),
                if ((order.customerNote ?? '').trim().isNotEmpty)
                  InfoRow(
                      label: S.customerWish,
                      value: order.customerNote!.trim(),
                      icon: AppIcons.note),
              ],
            ),
          ),

          SectionTitle(S.address, icon: AppIcons.address),
          CardBox(
            child: Column(
              children: [
                InfoRow(label: S.address, value: Fmt.text(order.address)),
                if ((order.entrance ?? '').isNotEmpty)
                  InfoRow(label: S.entrance, value: order.entrance!),
                if ((order.floor ?? '').isNotEmpty)
                  InfoRow(label: S.floor, value: order.floor!),
                if ((order.apartment ?? '').isNotEmpty)
                  InfoRow(label: S.apartment, value: order.apartment!),
              ],
            ),
          ),

          SectionTitle(S.participants, icon: AppIcons.person),
          if (order.actualCourierUnknown)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: NoticeBox(S.courierUnknownNote),
            ),
          CardBox(
            child: Column(
              children: [
                InfoRow(
                  label: S.courier,
                  value: order.actualCourierUnknown
                      ? S.courierUnknownShort
                      : (order.courier?.fullName ?? kUnknown),
                  valueColor:
                      order.actualCourierUnknown ? kWarningColor : kBlackColor,
                  icon: AppIcons.courier,
                ),
                InfoRow(
                  label: S.cook,
                  value: order.cook?.fullName ?? kUnknown,
                  icon: AppIcons.cook,
                ),
                if (order.participants.isNotEmpty) ...[
                  const Divider(height: 18, color: kBorderColor),
                  for (final participant in order.participants)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const AppIcon(AppIcons.person,
                                  size: 15, color: kMutedColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  participant.actor?.fullName ?? kUnknown,
                                  style: const TextStyle(
                                    fontFamily: gilroySemiBold,
                                    fontSize: 13.5,
                                    color: kBlackColor,
                                  ),
                                ),
                              ),
                              if (participant.actor?.role != null)
                                Text(
                                  // The role arrives as the server spells it
                                  // (`SUPER_ADMIN`); it is named in words
                                  // here.
                                  Labels.role(participant.actor!.role),
                                  style: const TextStyle(
                                    fontFamily: gilroyRegular,
                                    fontSize: 11.5,
                                    color: kMutedColor,
                                  ),
                                ),
                            ],
                          ),
                          if (participant.actions.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final action in participant.actions)
                                  Pill(Labels.participantAction(action),
                                      color: kMutedColor),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    S.participantsNote,
                    style: const TextStyle(
                      fontFamily: gilroyRegular,
                      fontSize: 11.5,
                      color: kMutedColor,
                    ),
                  ),
                ],
              ],
            ),
          ),

          SectionTitle(S.stages, icon: AppIcons.transition),
          CardBox(
            child: Column(
              children: [
                InfoRow(
                  label: S.assignedAt,
                  value: Ashgabat.dateTimeLabel(order.assignedAt) ?? kUnknown,
                ),
                InfoRow(
                  label: S.packedAt,
                  value: Ashgabat.dateTimeLabel(order.packingConfirmedAt) ??
                      kUnknown,
                ),
                InfoRow(
                  label: S.deliveredAt,
                  value: Ashgabat.dateTimeLabel(order.deliveredAt) ?? kUnknown,
                ),
                InfoRow(
                  label: S.completedAt,
                  value: Ashgabat.dateTimeLabel(order.completedAt) ?? kUnknown,
                ),
              ],
            ),
          ),

          if (order.transitions.isNotEmpty) ...[
            const SizedBox(height: 10),
            CardBox(
              child: Column(
                children: [
                  for (var i = 0; i < order.transitions.length; i++) ...[
                    if (i > 0) const Divider(height: 16, color: kBorderColor),
                    _TransitionRow(transition: order.transitions[i]),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
}

/// The order number and both statuses it carries: where the food got to, and
/// where its money got to. They are different machines and are shown as two
/// captions rather than merged into one.
class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final settlement = order.settlement;
    return CardBox(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconBadge(
                AppIcons.orders,
                color: Labels.orderStatusColor(order.status),
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Fmt.orderNumber(order.number),
                        style: const TextStyle(
                          fontFamily: gilroyBold,
                          fontSize: 22,
                          color: kBlackColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Ashgabat.dateTimeLabel(order.createdAt) ?? kUnknown,
                      style: const TextStyle(
                        fontFamily: gilroyRegular,
                        fontSize: 12,
                        color: kMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: kBorderColor),
          _StatusLine(
            label: S.deliveryStatus,
            value: Labels.orderStatus(order.status),
            color: Labels.orderStatusColor(order.status),
          ),
          const SizedBox(height: 8),
          _StatusLine(
            label: S.moneyStatus,
            value: settlement == null
                ? S.packetNotCreated
                : Labels.settlementStatus(settlement.status),
            color: settlement == null
                ? kMutedColor
                : Labels.settlementStatusColor(settlement.status),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: gilroyRegular,
                fontSize: 13,
                color: kMutedColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(child: Pill(value, color: color)),
        ],
      );
}

// ── Tab 2: the receipt ──────────────────────────────────────────────────

/// What the order cost, laid out as the slip the courier hands over.
///
/// Nothing here is recomputed: every figure is the server's own, printed in
/// the order a receipt prints them. It is not a fiscal document and says so,
/// so nobody files it as one.
class _ReceiptTab extends StatelessWidget {
  const _ReceiptTab({required this.order, required this.reload});

  final OrderDetail order;
  final VoidCallback reload;

  @override
  Widget build(BuildContext context) {
    final settlement = order.settlement;
    return _Refreshable(
      reload: reload,
      children: [
        const SizedBox(height: 8),
        ReceiptPaper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      S.appName,
                      style: const TextStyle(
                        fontFamily: gilroyBold,
                        fontSize: 16,
                        color: kBlackColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Fmt.orderNumber(order.number),
                      style: const TextStyle(
                        fontFamily: gilroySemiBold,
                        fontSize: 13,
                        color: kPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Ashgabat.dateTimeLabel(order.createdAt) ?? kUnknown,
                      style: const TextStyle(
                        fontFamily: gilroyRegular,
                        fontSize: 11.5,
                        color: kMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const DashedLine(),
              const SizedBox(height: 10),
              _ReceiptMeta(
                label: S.kitchen,
                value: Fmt.text(order.branchName),
              ),
              _ReceiptMeta(
                label: S.district,
                value: Fmt.text(order.deliveryEtrapName),
              ),
              _ReceiptMeta(
                label: S.customer,
                value: Fmt.text(order.customerName),
              ),
              _ReceiptMeta(
                label: S.courier,
                value: order.actualCourierUnknown
                    ? S.courierUnknownShort
                    : (order.courier?.fullName ?? kUnknown),
              ),
              const SizedBox(height: 10),
              const DashedLine(),
              const SizedBox(height: 12),
              Text(
                S.composition(order.items.length),
                style: const TextStyle(
                  fontFamily: gilroySemiBold,
                  fontSize: 12,
                  color: kMutedColor,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              if (order.items.isEmpty)
                Text(
                  S.noItems,
                  style: const TextStyle(
                    fontFamily: gilroyRegular,
                    fontSize: 13,
                    color: kMutedColor,
                  ),
                )
              else
                for (var i = 0; i < order.items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _ReceiptLine(line: order.items[i]),
                ],
              if (order.gifts.isNotEmpty) ...[
                const SizedBox(height: 12),
                const DashedLine(),
                const SizedBox(height: 10),
                Text(
                  S.gifts,
                  style: const TextStyle(
                    fontFamily: gilroySemiBold,
                    fontSize: 12,
                    color: kMutedColor,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                for (final gift in order.gifts)
                  ReceiptRow(
                    label: '${Fmt.text(gift.name)} × ${Fmt.count(gift.quantity)}',
                    value: gift.totalPoints == null
                        ? kDash
                        : S.points(Fmt.count(gift.totalPoints)),
                  ),
              ],
              const SizedBox(height: 12),
              const DashedLine(),
              const SizedBox(height: 10),
              ReceiptRow(label: S.subtotal, value: Fmt.money(order.subtotal)),
              ReceiptRow(
                label: S.discount,
                value: Fmt.money(order.discount),
                color: (order.discount ?? 0) > 0 ? kPositiveColor : null,
              ),
              ReceiptRow(label: S.foodAmount, value: Fmt.money(order.foodAmount)),
              ReceiptRow(label: S.delivery, value: Fmt.money(order.deliveryFee)),
              if (order.loyaltyPointsEarned != null ||
                  order.loyaltyPointsSpent != null)
                ReceiptRow(
                  label: S.loyalty,
                  value: S.loyaltyValue(
                    Fmt.count(order.loyaltyPointsEarned),
                    Fmt.count(order.loyaltyPointsSpent),
                  ),
                ),
              const SizedBox(height: 10),
              const DashedLine(),
              const SizedBox(height: 10),
              ReceiptRow(
                label: S.total,
                value: Fmt.money(order.total),
                total: true,
                color: kPrimaryColor,
              ),
              const SizedBox(height: 12),
              const DashedLine(),
              const SizedBox(height: 10),
              Center(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    Pill(
                      Labels.orderStatus(order.status),
                      color: Labels.orderStatusColor(order.status),
                      icon: AppIcons.delivered,
                    ),
                    Pill(
                      settlement == null
                          ? S.packetNotCreated
                          : Labels.settlementStatus(settlement.status),
                      color: settlement == null
                          ? kMutedColor
                          : Labels.settlementStatusColor(settlement.status),
                      icon: AppIcons.money,
                    ),
                    if (order.rating != null)
                      Pill('${S.rating}: ${order.rating}',
                          color: kWarningColor, icon: AppIcons.rating),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          S.receiptNote,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: gilroyRegular,
            fontSize: 11.5,
            color: kMutedColor,
          ),
        ),

        SectionTitle(S.money, icon: AppIcons.money),
        if (settlement == null) ...[
          CardBox(
            child: Text(
              S.noSettlement,
              style: const TextStyle(
                  fontFamily: gilroyRegular, fontSize: 13, color: kMutedColor),
            ),
          ),
          if (App.instance.auth.role.canReturnCash &&
              order.status == 'DELIVERED') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kPositiveColor),
                  shape: const RoundedRectangleBorder(
                      borderRadius: borderRadius10),
                ),
                onPressed: () => markCashReturned(
                  context,
                  order: order,
                  onDone: reload,
                ),
                icon: const AppIcon(AppIcons.money,
                    size: 18, color: kPositiveColor),
                label: Text(
                  S.markCashReturned,
                  style: const TextStyle(
                    fontFamily: gilroySemiBold,
                    color: kPositiveColor,
                  ),
                ),
              ),
            ),
          ],
        ] else ...[
          if (settlement.isHandoverDateUnknown)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: NoticeBox(S.handoverUnknownNote),
            ),
          CardBox(
            child: Column(
              children: [
                InfoRow(label: S.amount, value: Fmt.money(settlement.amount)),
                InfoRow(
                  label: S.state,
                  // The money record's state is a server word and is named
                  // here rather than printed as `WITH_OPERATOR`.
                  value: Labels.settlementStatus(settlement.status),
                  valueColor: Labels.settlementStatusColor(settlement.status),
                ),
                InfoRow(
                  label: S.cashReturned,
                  value: Ashgabat.dateTimeLabel(settlement.operatorTakenAt) ??
                      (settlement.isHandoverDateUnknown
                          ? S.dateUnknown
                          : kUnknown),
                  valueColor: settlement.operatorTakenAt == null
                      ? kWarningColor
                      : kBlackColor,
                ),
                InfoRow(
                  label: S.reconciledAt,
                  value:
                      Ashgabat.dateTimeLabel(settlement.reconciledAt) ?? kUnknown,
                ),
                InfoRow(
                  label: S.operator,
                  value: Fmt.text(settlement.operatorName),
                  icon: AppIcons.person,
                ),
                InfoRow(
                  label: S.accountant,
                  value: Fmt.text(settlement.accountantName),
                  icon: AppIcons.person,
                ),
                if (settlement.cashHandoffId != null)
                  InfoRow(
                    label: S.cashPacket,
                    value: settlement.cashHandoffId!,
                    icon: AppIcons.handoff,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ReceiptMeta extends StatelessWidget {
  const _ReceiptMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: gilroyRegular,
                  fontSize: 12,
                  color: kMutedColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: gilroyMedium,
                  fontSize: 12,
                  color: kBlackColor,
                ),
              ),
            ),
          ],
        ),
      );
}

/// A dish on the receipt: its name, then `2 × 35,00 = 70,00` underneath, the
/// way a printed slip breaks the arithmetic out.
class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine({required this.line});

  final OrderLine line;

  @override
  Widget build(BuildContext context) {
    final name = [line.productName, line.variantName]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                name.isEmpty ? kUnknown : name,
                style: const TextStyle(
                  fontFamily: gilroySemiBold,
                  fontSize: 13.5,
                  color: kBlackColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              Fmt.money(line.lineTotal),
              style: const TextStyle(
                fontFamily: gilroySemiBold,
                fontSize: 13.5,
                color: kBlackColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                '${Fmt.count(line.quantity)} × ${Fmt.money(line.unitPrice)}',
                style: const TextStyle(
                  fontFamily: gilroyRegular,
                  fontSize: 12,
                  color: kMutedColor,
                ),
              ),
            ),
            if (line.preparationMinutes != null) ...[
              const AppIcon(AppIcons.preparation,
                  size: 12, color: kMutedColor),
              const SizedBox(width: 4),
              Text(
                // 520 is a legal value and is printed in full.
                Fmt.minutes(line.preparationMinutes),
                style: const TextStyle(
                  fontFamily: gilroyRegular,
                  fontSize: 11.5,
                  color: kMutedColor,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _TransitionRow extends StatelessWidget {
  const _TransitionRow({required this.transition});

  final OrderTransition transition;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(AppIcons.transition, size: 15, color: kMutedColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${Labels.orderStatus(transition.fromStatus)} → '
                  '${Labels.orderStatus(transition.toStatus)}',
                  style: const TextStyle(
                    fontFamily: gilroySemiBold,
                    fontSize: 13,
                    color: kBlackColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${transition.actor?.fullName ?? kUnknown} · '
            '${Ashgabat.dateTimeLabel(transition.createdAt) ?? kUnknown}',
            style: const TextStyle(
              fontFamily: gilroyRegular,
              fontSize: 12,
              color: kMutedColor,
            ),
          ),
          if ((transition.note ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              // A cancellation note is often a stored reason key rather than
              // a sentence somebody typed.
              Labels.cancelReason(transition.note),
              style: const TextStyle(
                fontFamily: gilroyMedium,
                fontSize: 12.5,
                color: kBlackColor,
              ),
            ),
          ],
        ],
      );
}

// ── Tab 3: the history ──────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) => PagedList<AuditEntry>(
        requestKey: 'order-audit-$orderId',
        storageKey: 'order-audit-$orderId',
        emptyTitle: S.historyEmpty,
        emptyMessage: S.historyEmptyMessage,
        fetch: (page) =>
            App.instance.accounting.orderAudit(orderId, page: page),
        header: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: NoticeBox(S.historyNote, color: kPrimaryColor),
        ),
        itemBuilder: (context, entry, _) => AuditTile(entry: entry),
      );
}
