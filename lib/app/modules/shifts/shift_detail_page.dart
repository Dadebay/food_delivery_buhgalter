import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/constants.dart';
import '../../data/accounting_service.dart';
import '../../data/app_state.dart';
import '../../data/ashgabat_time.dart';
import '../../data/formatting.dart';
import '../../data/labels.dart';
import '../../data/models/overview.dart';
import '../../data/models/shift.dart';
import '../../widgets/async_loader.dart';
import '../../widgets/month_bar.dart';
import '../../widgets/ui.dart';
import '../audit/audit_page.dart';
import '../carryover/carryover_screen.dart';
import '../orders/orders_page.dart';
import 'handoff_sheet.dart';

/// One shift, opened by its `shiftKey`.
///
/// The money shown here is this shift's own entry from `/shifts` — never a
/// whole day's report relabelled. `overview`, `orders`, `audit` and
/// `carryover` all accept the key directly; `report` and `shifts` do not, so
/// they are not asked for it.
class ShiftDetailPage extends StatefulWidget {
  const ShiftDetailPage({
    super.key,
    required this.shift,
    required this.shiftName,
  });

  final ShiftSummary shift;
  final String shiftName;

  @override
  State<ShiftDetailPage> createState() => _ShiftDetailPageState();
}

class _ShiftDetailPageState extends State<ShiftDetailPage> {
  late ShiftSummary _shift = widget.shift;

  Period get _period => Period.shift(_shift.shiftKey);

  /// Re-reads this shift from `/shifts` for its own calendar day, which is
  /// how a confirmed packet gets its new state without being patched here.
  Future<void> _reload() async {
    final day = _shift.dayKey;
    try {
      final shifts = await App.instance.accounting
          .shifts(fromDate: day, toDate: day);
      for (final shift in shifts) {
        if (shift.shiftKey == _shift.shiftKey && mounted) {
          setState(() => _shift = shift);
          return;
        }
      }
    } catch (_) {
      // The detail below reloads on its own; a failed refresh must not
      // replace what is on screen with a guess.
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = Ashgabat.parseDate(_shift.dayKey);
    final handoff = _shift.handoff;
    return AppScaffold(
      title: widget.shiftName,
      subtitle: date == null
          ? _shift.shiftKey
          : Ashgabat.dayLabel(date, kLocale),
      child: AsyncLoader<AccountingOverview>(
        requestKey: 'shift-${_shift.shiftKey}',
        request: () => App.instance.accounting.overview(_period),
        builder: (context, overview, reload) => RefreshIndicator(
          color: kPrimaryColor,
          onRefresh: () async {
            await _reload();
            reload();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _money(context, handoff),
              const SectionTitle('Заказы смены', icon: AppIcons.orders),
              StatGrid(tiles: [
                StatTile(
                  label: 'Создано',
                  value: Fmt.count(overview.summary.createdOrders),
                  icon: AppIcons.orders,
                  color: kPrimaryColor,
                ),
                StatTile(
                  label: 'Отменено',
                  value: Fmt.count(overview.summary.cancelledOrders),
                  icon: AppIcons.cancelled,
                  color: kNegativeColor,
                ),
                StatTile(
                  label: 'Редактирований',
                  value: Fmt.count(overview.summary.editEvents),
                  icon: AppIcons.edited,
                  hint: 'в том числе заказов прошлых смен',
                ),
                StatTile(
                  label: 'Действий отмены',
                  value: Fmt.count(overview.summary.cancellationEvents),
                  icon: AppIcons.cancelled,
                ),
              ]),

              const SectionTitle('Открыть', icon: AppIcons.details),
              SectionCard(
                icon: AppIcons.orders,
                title: 'Заказы по созданию',
                subtitle: 'Что заказали в эту смену',
                onTap: () => _open(
                  context,
                  OrdersPage(
                    period: _period,
                    basis: OrderBasis.created,
                    title: widget.shiftName,
                    subtitle: 'Заказы по времени создания',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SectionCard(
                icon: AppIcons.money,
                title: 'Деньги, вернувшиеся в смену',
                subtitle: 'Для сданного пакета — его состав',
                color: kPositiveColor,
                onTap: () => _open(
                  context,
                  OrdersPage(
                    period: _period,
                    basis: OrderBasis.cashReturned,
                    title: widget.shiftName,
                    subtitle: 'Деньги, возвращённые в смену',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SectionCard(
                icon: AppIcons.journal,
                title: 'Кто что сделал',
                subtitle: 'Действия в течение смены',
                onTap: () => _open(
                  context,
                  AuditPage(
                    period: _period,
                    title: 'Журнал смены',
                    subtitle: widget.shiftName,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SectionCard(
                icon: AppIcons.carryIn,
                title: 'Принято от смены',
                subtitle: 'Незавершённые заказы на входе',
                color: kWarningColor,
                onTap: () => _open(
                  context,
                  CarryoverScreen(
                    period: _period,
                    incoming: true,
                    subtitle: widget.shiftName,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SectionCard(
                icon: AppIcons.carryOut,
                title: 'Передано смене',
                subtitle: 'Незавершённые заказы на выходе',
                color: kWarningColor,
                onTap: () => _open(
                  context,
                  CarryoverScreen(
                    period: _period,
                    incoming: false,
                    subtitle: widget.shiftName,
                  ),
                ),
              ),

              if (overview.cancellationReasons.isNotEmpty) ...[
                const SectionTitle('Причины отмен', icon: AppIcons.cancelled),
                CardBox(
                  child: Column(
                    children: [
                      for (final reason in overview.cancellationReasons)
                        NamedCountRow(
                          name: Fmt.text(reason.name),
                          count: reason.count,
                          amount: reason.foodAmount,
                        ),
                    ],
                  ),
                ),
              ],
              if (overview.mostOrderedProducts.isNotEmpty) ...[
                const SectionTitle('Спрос на блюда', icon: AppIcons.dish),
                CardBox(
                  child: Column(
                    children: [
                      for (final product in overview.mostOrderedProducts)
                        NamedCountRow(
                          name: Fmt.text(product.name),
                          count: product.quantity,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page),
      );

  Widget _money(BuildContext context, CashHandoff? handoff) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardBox(
            child: Column(
              children: [
                Row(
                  children: [
                    const AppIconBadge(AppIcons.handoff, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        Labels.handoffStatus(handoff?.status),
                        style: TextStyle(
                          fontFamily: gilroySemiBold,
                          fontSize: 14.5,
                          color: Labels.handoffStatusColor(handoff?.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                InfoRow(
                  label: 'Заказов в смену',
                  value: Fmt.count(_shift.orderCount),
                  icon: AppIcons.orders,
                ),
                InfoRow(
                  label: 'Получено в смену',
                  value: Fmt.money(_shift.collectedAmount),
                  icon: AppIcons.collected,
                ),
                InfoRow(
                  label: 'Ожидается к сдаче',
                  value: Fmt.money(_shift.expectedAmount),
                  icon: AppIcons.handoff,
                  strong: true,
                ),
                if (handoff != null) ...[
                  const Divider(height: 18, color: kBorderColor),
                  InfoRow(
                    label: 'Заявлено',
                    value: Fmt.money(handoff.declaredAmount),
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
                    label: 'Записей в пакете',
                    value: Fmt.count(handoff.settlementCount),
                  ),
                  InfoRow(
                    label: 'Передал',
                    value: handoff.submittedBy?.fullName ?? kUnknown,
                    icon: AppIcons.person,
                  ),
                  InfoRow(
                    label: 'Передан',
                    value:
                        Ashgabat.dateTimeLabel(handoff.submittedAt, kLocale) ??
                            kUnknown,
                  ),
                  if (handoff.isConfirmed) ...[
                    InfoRow(
                      label: 'Подтвердил',
                      value: handoff.confirmedBy?.fullName ?? kUnknown,
                      icon: AppIcons.confirmed,
                    ),
                    InfoRow(
                      label: 'Подтверждён',
                      value: Ashgabat.dateTimeLabel(
                              handoff.confirmedAt, kLocale) ??
                          kUnknown,
                    ),
                  ],
                  if ((handoff.note ?? '').trim().isNotEmpty)
                    InfoRow(
                      label: 'Комментарий',
                      value: handoff.note!.trim(),
                      icon: AppIcons.note,
                    ),
                  if ((handoff.confirmationNote ?? '').trim().isNotEmpty)
                    InfoRow(
                      label: 'При подтверждении',
                      value: handoff.confirmationNote!.trim(),
                      icon: AppIcons.note,
                    ),
                  if (!handoff.isConfirmed) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: kPositiveColor,
                          shape: const RoundedRectangleBorder(
                              borderRadius: borderRadius10),
                        ),
                        onPressed: () => confirmHandoff(
                          context,
                          handoff: handoff,
                          onDone: _reload,
                        ),
                        icon: const AppIcon(AppIcons.confirmed,
                            size: 18, color: Colors.white),
                        label: const Text(
                          'Подтвердить сумму',
                          style: TextStyle(
                            fontFamily: gilroySemiBold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ] else if (App.instance.auth.role.canCreateHandoff) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kBorderColor),
                        shape: const RoundedRectangleBorder(
                            borderRadius: borderRadius10),
                      ),
                      onPressed: () => createHandoff(
                        context,
                        shift: _shift,
                        onDone: _reload,
                      ),
                      icon: const AppIcon(AppIcons.handoff, size: 18),
                      label: const Text(
                        'Создать пакет',
                        style: TextStyle(
                          fontFamily: gilroySemiBold,
                          color: kPrimaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
}
