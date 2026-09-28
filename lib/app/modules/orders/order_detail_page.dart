import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/constants.dart';
import '../../data/app_state.dart';
import '../../data/ashgabat_time.dart';
import '../../data/formatting.dart';
import '../../data/labels.dart';
import '../../data/models/audit.dart';
import '../../data/models/order.dart';
import '../../widgets/async_loader.dart';
import '../../widgets/month_bar.dart';
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
          title: 'Заказ',
          subtitle: 'Состав, участники и история',
          bottom: const TabBar(
            labelColor: kPrimaryColor,
            unselectedLabelColor: kMutedColor,
            indicatorColor: kPrimaryColor,
            labelStyle: TextStyle(fontFamily: gilroySemiBold, fontSize: 13.5),
            tabs: [
              Tab(text: 'Заказ'),
              Tab(text: 'История'),
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
              label: 'Создан',
              value: Ashgabat.dateTimeLabel(order.createdAt, kLocale) ??
                  kUnknown,
              icon: AppIcons.day,
            ),
            InfoRow(
              label: 'Источник',
              value: Labels.orderSource(order.source),
              icon: AppIcons.orders,
            ),
            if ((order.branchName ?? '').isNotEmpty)
              InfoRow(
                label: 'Кухня',
                value: order.branchName!,
                icon: AppIcons.branch,
              ),
            InfoRow(
              label: 'Район',
              // Districts come from the names saved on the order; an unknown
              // one is shown as unknown rather than guessed from the address.
              value: Fmt.text(order.deliveryEtrapName),
              icon: AppIcons.address,
            ),
          ],
        ),
      ),

      const SectionTitle('Клиент', icon: AppIcons.customer),
      CardBox(
        child: Column(
          children: [
            InfoRow(
                label: 'Имя',
                value: Fmt.text(order.customerName),
                icon: AppIcons.customer),
            InfoRow(
                label: 'Телефон',
                value: Fmt.text(order.customerPhone),
                icon: AppIcons.phone),
            if ((order.customerNote ?? '').trim().isNotEmpty)
              InfoRow(
                  label: 'Пожелание',
                  value: order.customerNote!.trim(),
                  icon: AppIcons.note),
          ],
        ),
      ),

      const SectionTitle('Адрес', icon: AppIcons.address),
      CardBox(
        child: Column(
          children: [
            InfoRow(label: 'Адрес', value: Fmt.text(order.address)),
            if ((order.entrance ?? '').isNotEmpty)
              InfoRow(label: 'Подъезд', value: order.entrance!),
            if ((order.floor ?? '').isNotEmpty)
              InfoRow(label: 'Этаж', value: order.floor!),
            if ((order.apartment ?? '').isNotEmpty)
              InfoRow(label: 'Квартира', value: order.apartment!),
          ],
        ),
      ),

      SectionTitle('Состав (${Fmt.count(order.items.length)})',
          icon: AppIcons.dish),
      if (order.items.isEmpty)
        const CardBox(
          child: Text(
            'Позиции не сохранены.',
            style: TextStyle(
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
        const SectionTitle('Подарки', icon: AppIcons.gift),
        CardBox(
          child: Column(
            children: [
              for (final gift in order.gifts)
                InfoRow(
                  label: Fmt.text(gift.name),
                  value: '× ${Fmt.count(gift.quantity)}'
                      '${gift.totalPoints == null ? '' : ' · ${Fmt.count(gift.totalPoints)} баллов'}',
                  icon: AppIcons.gift,
                ),
            ],
          ),
        ),
      ],

      const SectionTitle('Суммы', icon: AppIcons.money),
      CardBox(
        child: Column(
          children: [
            InfoRow(label: 'Сумма позиций', value: Fmt.money(order.subtotal)),
            InfoRow(label: 'Скидка', value: Fmt.money(order.discount)),
            InfoRow(
              label: 'Сумма еды',
              value: Fmt.money(order.foodAmount),
              icon: AppIcons.dish,
            ),
            InfoRow(label: 'Доставка', value: Fmt.money(order.deliveryFee)),
            InfoRow(
                label: 'Итого', value: Fmt.money(order.total), strong: true),
            if (order.loyaltyPointsEarned != null ||
                order.loyaltyPointsSpent != null)
              InfoRow(
                label: 'Баллы',
                value: 'начислено ${Fmt.count(order.loyaltyPointsEarned)} · '
                    'списано ${Fmt.count(order.loyaltyPointsSpent)}',
              ),
            if (order.rating != null)
              InfoRow(
                label: 'Оценка',
                value: '${order.rating}',
                icon: AppIcons.rating,
              ),
          ],
        ),
      ),

      const SectionTitle('Кто участвовал', icon: AppIcons.person),
      if (order.actualCourierUnknown)
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: NoticeBox(
            'Фактический курьер неизвестен: назначение сделано технически при '
            'историческом закрытии заказа.',
          ),
        ),
      CardBox(
        child: Column(
          children: [
            InfoRow(
              label: 'Курьер',
              value: order.actualCourierUnknown
                  ? 'неизвестен'
                  : (order.courier?.fullName ?? kUnknown),
              valueColor:
                  order.actualCourierUnknown ? kWarningColor : kBlackColor,
              icon: AppIcons.courier,
            ),
            InfoRow(
              label: 'Повар',
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
              const Text(
                'Должность сотрудника сама по себе не доказывает, что он '
                'готовил или доставлял этот заказ.',
                style: TextStyle(
                  fontFamily: gilroyRegular,
                  fontSize: 11.5,
                  color: kMutedColor,
                ),
              ),
            ],
          ],
        ),
      ),

      const SectionTitle('Этапы', icon: AppIcons.transition),
      CardBox(
        child: Column(
          children: [
            InfoRow(
              label: 'Назначен курьеру',
              value: Ashgabat.dateTimeLabel(order.assignedAt, kLocale) ??
                  kUnknown,
            ),
            InfoRow(
              label: 'Сборка подтверждена',
              value:
                  Ashgabat.dateTimeLabel(order.packingConfirmedAt, kLocale) ??
                      kUnknown,
            ),
            InfoRow(
              label: 'Доставлен',
              value: Ashgabat.dateTimeLabel(order.deliveredAt, kLocale) ??
                  kUnknown,
            ),
            InfoRow(
              label: 'Завершён',
              value: Ashgabat.dateTimeLabel(order.completedAt, kLocale) ??
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

      const SectionTitle('Деньги', icon: AppIcons.money),
      if (settlement == null)
        const CardBox(
          child: Text(
            'Денежной записи по этому заказу нет.',
            style: TextStyle(
                fontFamily: gilroyRegular, fontSize: 13, color: kMutedColor),
          ),
        )
      else ...[
        if (settlement.isHandoverDateUnknown)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: NoticeBox(
              'Сверено; дата сдачи неизвестна. Такая запись не попадает ни в '
              'сегодняшнюю смену, ни в денежный график по времени сверки.',
            ),
          ),
        CardBox(
          child: Column(
            children: [
              InfoRow(label: 'Сумма', value: Fmt.money(settlement.amount)),
              InfoRow(
                label: 'Состояние',
                value: Fmt.text(settlement.status),
                valueColor: settlement.isReconciled
                    ? kPositiveColor
                    : kBlackColor,
              ),
              InfoRow(
                label: 'Деньги вернули',
                value: Ashgabat.dateTimeLabel(
                        settlement.operatorTakenAt, kLocale) ??
                    (settlement.isHandoverDateUnknown
                        ? 'дата неизвестна'
                        : kUnknown),
                valueColor: settlement.operatorTakenAt == null
                    ? kWarningColor
                    : kBlackColor,
              ),
              InfoRow(
                label: 'Сверено',
                value:
                    Ashgabat.dateTimeLabel(settlement.reconciledAt, kLocale) ??
                        kUnknown,
              ),
              InfoRow(
                label: 'Оператор',
                value: Fmt.text(settlement.operatorName),
                icon: AppIcons.person,
              ),
              InfoRow(
                label: 'Бухгалтер',
                value: Fmt.text(settlement.accountantName),
                icon: AppIcons.person,
              ),
              if (settlement.cashHandoffId != null)
                InfoRow(
                  label: 'Денежный пакет',
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
                '${Fmt.money(line.unitPrice)} за штуку',
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
                'Готовится ${Fmt.minutes(line.preparationMinutes)}',
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
            '${Ashgabat.dateTimeLabel(transition.createdAt, kLocale) ?? kUnknown}',
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
        emptyTitle: 'История пуста',
        emptyMessage: 'По этому заказу сохранённых действий нет.',
        fetch: (page) =>
            App.instance.accounting.orderAudit(orderId, page: page),
        header: const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: NoticeBox(
            'История заказа показывается целиком и не зависит от выбранного '
            'в приложении периода.',
            color: kPrimaryColor,
          ),
        ),
        itemBuilder: (context, entry, _) => AuditTile(entry: entry),
      );
}
