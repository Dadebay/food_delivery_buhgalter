import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/constants.dart';
import '../../data/app_state.dart';
import '../../data/ashgabat_time.dart';
import '../../data/formatting.dart';
import '../../data/labels.dart';
import '../../data/models/audit.dart';
import '../../data/models/order.dart';
import '../../data/strings.dart';
import '../../widgets/async_loader.dart';
import '../../widgets/paged_list.dart';
import '../../widgets/ui.dart';
import '../audit/audit_tile.dart';

/// One order, full screen, with its whole history beside it.
///
/// The history tab uses `/orders/:id/audit`, which is deliberately not
/// limited by the dates chosen elsewhere in the app: an order's story is its
/// own, whatever month the accountant happens to be looking at.
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: AppScaffold(
          title: S.order,
          subtitle: S.orderDetailsSub,
          bottom: TabBar(
            labelColor: kPrimaryColor,
            unselectedLabelColor: kMutedColor,
            indicatorColor: kPrimaryColor,
            labelStyle: const TextStyle(
                fontFamily: gilroySemiBold, fontSize: 13.5),
            tabs: [
              Tab(text: S.orderTabOrder),
              Tab(text: S.orderTabHistory),
            ],
          ),
          child: TabBarView(
            children: [
              _OrderTab(orderId: orderId),
              _HistoryTab(orderId: orderId),
            ],
          ),
        ),
      );
}

class _OrderTab extends StatelessWidget {
  const _OrderTab({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) => AsyncLoader<OrderDetail>(
        requestKey: orderId,
        request: () => App.instance.accounting.order(orderId),
        builder: (context, order, reload) => RefreshIndicator(
          color: kPrimaryColor,
          onRefresh: () async => reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            physics: const AlwaysScrollableScrollPhysics(),
            children: _body(context, order),
          ),
        ),
      );

  List<Widget> _body(BuildContext context, OrderDetail order) {
    final settlement = order.settlement;
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              Fmt.orderNumber(order.number),
              style: const TextStyle(
                fontFamily: gilroyBold,
                fontSize: 24,
                color: kBlackColor,
              ),
            ),
          ),
          Pill(
            Labels.orderStatus(order.status),
            color: Labels.orderStatusColor(order.status),
          ),
        ],
      ),
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
              // Districts come from the names saved on the order; an unknown
              // one is shown as unknown rather than guessed from the address.
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

      SectionTitle(S.composition(order.items.length), icon: AppIcons.dish),
      if (order.items.isEmpty)
        CardBox(
          child: Text(
            S.noItems,
            style: const TextStyle(
                fontFamily: gilroyRegular, fontSize: 13, color: kMutedColor),
          ),
        )
      else
        CardBox(
          child: Column(
            children: [
              for (var i = 0; i < order.items.length; i++) ...[
                if (i > 0) const Divider(height: 18, color: kBorderColor),
                _LineRow(line: order.items[i]),
              ],
            ],
          ),
        ),

      if (order.gifts.isNotEmpty) ...[
        SectionTitle(S.gifts, icon: AppIcons.gift),
        CardBox(
          child: Column(
            children: [
              for (final gift in order.gifts)
                InfoRow(
                  label: Fmt.text(gift.name),
                  value: '× ${Fmt.count(gift.quantity)}'
                      '${gift.totalPoints == null ? '' : ' · ${S.points(Fmt.count(gift.totalPoints))}'}',
                  icon: AppIcons.gift,
                ),
            ],
          ),
        ),
      ],

      SectionTitle(S.amounts, icon: AppIcons.money),
      CardBox(
        child: Column(
          children: [
            InfoRow(label: S.subtotal, value: Fmt.money(order.subtotal)),
            InfoRow(label: S.discount, value: Fmt.money(order.discount)),
            InfoRow(
              label: S.foodAmount,
              value: Fmt.money(order.foodAmount),
              icon: AppIcons.dish,
            ),
            InfoRow(label: S.delivery, value: Fmt.money(order.deliveryFee)),
            InfoRow(label: S.total, value: Fmt.money(order.total), strong: true),
            if (order.loyaltyPointsEarned != null ||
                order.loyaltyPointsSpent != null)
              InfoRow(
                label: S.loyalty,
                value: S.loyaltyValue(Fmt.count(order.loyaltyPointsEarned),
                    Fmt.count(order.loyaltyPointsSpent)),
              ),
            if (order.rating != null)
              InfoRow(
                label: S.rating,
                value: '${order.rating}',
                icon: AppIcons.rating,
              ),
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
                              participant.actor!.role!,
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
              value: Ashgabat.dateTimeLabel(order.assignedAt) ??
                  kUnknown,
            ),
            InfoRow(
              label: S.packedAt,
              value:
                  Ashgabat.dateTimeLabel(order.packingConfirmedAt) ??
                      kUnknown,
            ),
            InfoRow(
              label: S.deliveredAt,
              value: Ashgabat.dateTimeLabel(order.deliveredAt) ??
                  kUnknown,
            ),
            InfoRow(
              label: S.completedAt,
              value: Ashgabat.dateTimeLabel(order.completedAt) ??
                  kUnknown,
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

      SectionTitle(S.money, icon: AppIcons.money),
      if (settlement == null)
        CardBox(
          child: Text(
            S.noSettlement,
            style: const TextStyle(
                fontFamily: gilroyRegular, fontSize: 13, color: kMutedColor),
          ),
        )
      else ...[
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
                value: Fmt.text(settlement.status),
                valueColor: settlement.isReconciled
                    ? kPositiveColor
                    : kBlackColor,
              ),
              InfoRow(
                label: S.cashReturned,
                value: Ashgabat.dateTimeLabel(
                        settlement.operatorTakenAt) ??
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
                    Ashgabat.dateTimeLabel(settlement.reconciledAt) ??
                        kUnknown,
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
    ];
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line});

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
                  fontSize: 14,
                  color: kBlackColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '× ${Fmt.count(line.quantity)}',
              style: const TextStyle(
                fontFamily: gilroyBold,
                fontSize: 14,
                color: kPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                S.perPiece(Fmt.money(line.unitPrice)),
                style: const TextStyle(
                  fontFamily: gilroyRegular,
                  fontSize: 12,
                  color: kMutedColor,
                ),
              ),
            ),
            Text(
              Fmt.money(line.lineTotal),
              style: const TextStyle(
                fontFamily: gilroySemiBold,
                fontSize: 13,
                color: kBlackColor,
              ),
            ),
          ],
        ),
        if (line.preparationMinutes != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const AppIcon(AppIcons.preparation, size: 13, color: kMutedColor),
              const SizedBox(width: 6),
              Text(
                // 520 is a legal value and is printed in full.
                S.prepares(Fmt.minutes(line.preparationMinutes)),
                style: const TextStyle(
                  fontFamily: gilroyRegular,
                  fontSize: 12,
                  color: kMutedColor,
                ),
              ),
            ],
          ),
        ],
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
              transition.note!.trim(),
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
