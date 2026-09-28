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
///
/// The controller is created here rather than inherited, so the tab strip and
/// the pages cannot disagree about which tab is open.
class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: S.order,
        subtitle: S.orderDetailsSub,
        bottom: PillTabBar(
          controller: _tabs,
          labels: [S.orderTabOrder, S.orderTabHistory],
          icons: const [AppIcons.orders, AppIcons.history],
        ),
        child: TabBarView(
          controller: _tabs,
          children: [
            _OrderTab(orderId: widget.orderId),
            _HistoryTab(orderId: widget.orderId),
          ],
        ),
      );
}

class _OrderTab extends StatelessWidget {
  const _OrderTab({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) => AsyncLoader<OrderDetail>(
        requestKey: '$orderId-${App.instance.language.current}',
        request: () => App.instance.accounting.order(orderId),
        builder: (context, order, reload) => RefreshIndicator(
          color: kPrimaryColor,
          onRefresh: () async => reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            physics: const AlwaysScrollableScrollPhysics(),
            children: _body(context, order),
          ),
        ),
      );

  List<Widget> _body(BuildContext context, OrderDetail order) {
    final settlement = order.settlement;
    return [
      _Header(order: order),

      if (order.actualCourierUnknown) ...[
        const SizedBox(height: 12),
        NoticeBox(S.courierUnknownNote),
      ],

      // ── Who and where ─────────────────────────────────────────────────
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
            InfoRow(
              label: S.address,
              value: Fmt.text(order.address),
              icon: AppIcons.address,
            ),
            if ([order.entrance, order.floor, order.apartment]
                .any((part) => (part ?? '').isNotEmpty))
              InfoRow(
                label: '${S.entrance} · ${S.floor} · ${S.apartment}',
                value: [
                  Fmt.text(order.entrance),
                  Fmt.text(order.floor),
                  Fmt.text(order.apartment),
                ].join(' · '),
              ),
            // Districts come from the names saved on the order; an unknown
            // one is shown as unknown rather than guessed from the address.
            InfoRow(
                label: S.district,
                value: Fmt.text(order.deliveryEtrapName),
                icon: AppIcons.address),
            if ((order.branchName ?? '').isNotEmpty)
              InfoRow(
                  label: S.kitchen,
                  value: order.branchName!,
                  icon: AppIcons.branch),
            if ((order.customerNote ?? '').trim().isNotEmpty)
              InfoRow(
                  label: S.customerWish,
                  value: order.customerNote!.trim(),
                  icon: AppIcons.note),
          ],
        ),
      ),

      // ── What was ordered, and what it cost ────────────────────────────
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
              const Divider(height: 20, color: kBorderColor),
              InfoRow(label: S.subtotal, value: Fmt.money(order.subtotal)),
              InfoRow(label: S.discount, value: Fmt.money(order.discount)),
              InfoRow(label: S.foodAmount, value: Fmt.money(order.foodAmount)),
              InfoRow(label: S.delivery, value: Fmt.money(order.deliveryFee)),
              InfoRow(
                  label: S.total, value: Fmt.money(order.total), strong: true),
            ],
          ),
        ),

      if (order.gifts.isNotEmpty ||
          order.rating != null ||
          order.loyaltyPointsEarned != null ||
          order.loyaltyPointsSpent != null) ...[
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
      ],

      // ── Who touched it ────────────────────────────────────────────────
      SectionTitle(S.participants, icon: AppIcons.person),
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
                _ParticipantRow(participant: participant),
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

      // ── How it moved ──────────────────────────────────────────────────
      SectionTitle(S.stages, icon: AppIcons.transition),
      CardBox(
        child: Timeline(
          entries: [
            TimelineEntry(
              title: S.created,
              subtitle: Ashgabat.dateTimeLabel(order.createdAt) ?? kUnknown,
              done: order.createdAt != null,
            ),
            TimelineEntry(
              title: S.assignedAt,
              subtitle: Ashgabat.dateTimeLabel(order.assignedAt) ?? kUnknown,
              done: order.assignedAt != null,
            ),
            TimelineEntry(
              title: S.packedAt,
              subtitle:
                  Ashgabat.dateTimeLabel(order.packingConfirmedAt) ?? kUnknown,
              done: order.packingConfirmedAt != null,
            ),
            TimelineEntry(
              title: S.deliveredAt,
              subtitle: Ashgabat.dateTimeLabel(order.deliveredAt) ?? kUnknown,
              done: order.deliveredAt != null,
            ),
            TimelineEntry(
              title: S.completedAt,
              subtitle: Ashgabat.dateTimeLabel(order.completedAt) ?? kUnknown,
              done: order.completedAt != null,
            ),
          ],
        ),
      ),

      if (order.transitions.isNotEmpty) ...[
        const SizedBox(height: 10),
        CardBox(
          child: Timeline(
            entries: [
              for (final transition in order.transitions)
                TimelineEntry(
                  title: '${Labels.orderStatus(transition.fromStatus)} → '
                      '${Labels.orderStatus(transition.toStatus)}',
                  subtitle: '${transition.actor?.fullName ?? kUnknown} · '
                      '${Ashgabat.dateTimeLabel(transition.createdAt) ?? kUnknown}',
                  done: true,
                  note: (transition.note ?? '').trim().isEmpty
                      ? null
                      : transition.note!.trim(),
                ),
            ],
          ),
        ),
      ],

      // ── The money record ──────────────────────────────────────────────
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
              InfoRow(
                  label: S.amount,
                  value: Fmt.money(settlement.amount),
                  strong: true),
              InfoRow(
                label: S.state,
                value: Fmt.text(settlement.status),
                valueColor:
                    settlement.isReconciled ? kPositiveColor : kBlackColor,
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
                  icon: AppIcons.person),
              InfoRow(
                  label: S.accountant,
                  value: Fmt.text(settlement.accountantName),
                  icon: AppIcons.person),
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

/// Number, state and total in one block, so the three things that identify
/// an order are read before anything else.
class _Header extends StatelessWidget {
  const _Header({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) => CardBox(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    Fmt.orderNumber(order.number),
                    style: const TextStyle(
                      fontFamily: gilroyBold,
                      fontSize: 26,
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
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Pill(
                  Ashgabat.dateTimeLabel(order.createdAt) ?? kUnknown,
                  color: kMutedColor,
                  icon: AppIcons.day,
                ),
                Pill(
                  Labels.orderSource(order.source),
                  color: kMutedColor,
                  icon: AppIcons.orders,
                ),
              ],
            ),
            const Divider(height: 22, color: kBorderColor),
            Row(
              children: [
                Text(
                  S.total,
                  style: const TextStyle(
                    fontFamily: gilroyRegular,
                    fontSize: 13,
                    color: kMutedColor,
                  ),
                ),
                const Spacer(),
                Text(
                  Fmt.money(order.total),
                  style: const TextStyle(
                    fontFamily: gilroyBold,
                    fontSize: 20,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.participant});

  final Participant participant;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppIcon(AppIcons.person, size: 15, color: kMutedColor),
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
                    Pill(Labels.participantAction(action), color: kMutedColor),
                ],
              ),
            ],
          ],
        ),
      );
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: kSurfaceColor,
            borderRadius: borderRadius10,
          ),
          child: Text(
            '×${line.quantity ?? 1}',
            style: const TextStyle(
              fontFamily: gilroyBold,
              fontSize: 12,
              color: kPrimaryColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? kUnknown : name,
                style: const TextStyle(
                  fontFamily: gilroySemiBold,
                  fontSize: 14,
                  color: kBlackColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                [
                  S.perPiece(Fmt.money(line.unitPrice)),
                  // 520 is a legal value and is printed in full.
                  if (line.preparationMinutes != null)
                    S.prepares(Fmt.minutes(line.preparationMinutes)),
                ].join(' · '),
                style: const TextStyle(
                  fontFamily: gilroyRegular,
                  fontSize: 11.5,
                  color: kMutedColor,
                ),
              ),
            ],
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
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) => PagedList<AuditEntry>(
        requestKey: 'order-audit-$orderId-${App.instance.language.current}',
        storageKey: 'order-audit-$orderId',
        emptyTitle: S.historyEmpty,
        emptyMessage: S.historyEmptyMessage,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        fetch: (page) =>
            App.instance.accounting.orderAudit(orderId, page: page),
        header: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: NoticeBox(S.historyNote, color: kPrimaryColor),
        ),
        itemBuilder: (context, entry, _) => AuditTile(entry: entry),
      );
}
