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
  Widget build(BuildContext context) {
    final place = [
      order.address,
      if ((order.entrance ?? '').isNotEmpty) '${S.entrance} ${order.entrance}',
      if ((order.floor ?? '').isNotEmpty) '${S.floor} ${order.floor}',
      if ((order.apartment ?? '').isNotEmpty)
        '${S.apartment} ${order.apartment}',
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');
    final wish = (order.customerNote ?? '').trim();

    return _Refreshable(
      reload: reload,
      children: [
        _StatusHeader(order: order),
        const SizedBox(height: 12),
        _FactCard(
          icon: AppIcons.customer,
          title: S.customer,
          lines: [
            Fmt.text(order.customerName),
            if ((order.customerPhone ?? '').trim().isNotEmpty)
              order.customerPhone!.trim(),
          ],
          note: wish.isEmpty ? null : '${S.customerWish}: $wish',
        ),
        const SizedBox(height: 10),
        _FactCard(
          icon: AppIcons.address,
          title: S.address,
          lines: [
            place.isEmpty ? kUnknown : place,
            if ((order.deliveryEtrapName ?? '').trim().isNotEmpty)
              order.deliveryEtrapName!.trim(),
          ],
        ),
        const SizedBox(height: 10),
        _FactCard(
          icon: AppIcons.courier,
          title: S.participants,
          lines: [
            '${S.courier}: ${order.actualCourierUnknown ? S.courierUnknownShort : (order.courier?.fullName ?? kUnknown)}',
            '${S.cook}: ${order.cook?.fullName ?? kUnknown}',
          ],
          note: order.actualCourierUnknown ? S.courierUnknownNote : null,
        ),
      ],
    );
  }
}

/// A small titled card: an icon and a heading, then a few plain lines. The
/// first line is the answer and is printed larger; the rest support it.
class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.icon,
    required this.title,
    required this.lines,
    this.note,
  });

  final List<List<dynamic>> icon;
  final String title;
  final List<String> lines;
  final String? note;

  @override
  Widget build(BuildContext context) => CardBox(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIconBadge(icon, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: gilroyMedium,
                      fontSize: 12.5,
                      color: kMutedColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  for (var i = 0; i < lines.length; i++)
                    Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : 3),
                      child: Text(
                        lines[i],
                        style: TextStyle(
                          fontFamily: i == 0 ? gilroySemiBold : gilroyRegular,
                          fontSize: i == 0 ? 15.5 : 13.5,
                          color: i == 0 ? kBlackColor : kMutedColor,
                        ),
                      ),
                    ),
                  if (note != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      note!,
                      style: const TextStyle(
                        fontFamily: gilroyRegular,
                        fontSize: 12.5,
                        color: kWarningColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
    final where = [order.branchName, order.deliveryEtrapName]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(' · ');
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
                size: 46,
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
                        fontSize: 12.5,
                        color: kMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Pill(
                Labels.orderStatus(order.status),
                color: Labels.orderStatusColor(order.status),
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
            ],
          ),
          if (where.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              where,
              style: const TextStyle(
                fontFamily: gilroyRegular,
                fontSize: 13,
                color: kMutedColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
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
        separator: 0,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        fetch: (page) =>
            App.instance.accounting.orderAudit(orderId, page: page),
        header: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            S.historyNote,
            style: const TextStyle(
              fontFamily: gilroyRegular,
              fontSize: 12,
              color: kMutedColor,
            ),
          ),
        ),
        itemBuilder: (context, entry, index) =>
            AuditTimelineTile(entry: entry),
      );
}
