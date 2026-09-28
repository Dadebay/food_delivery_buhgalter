import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../constants/constants.dart';
import '../../../data/accounting_service.dart';
import '../../../data/app_state.dart';
import '../../../data/auth_service.dart';
import '../../../data/formatting.dart';
import '../../../widgets/month_bar.dart';
import '../../../widgets/ui.dart';
import '../../audit/audit_page.dart';
import '../../carryover/carryover_screen.dart';
import '../../month/month_page.dart';
import '../../orders/orders_page.dart';
import '../../shifts/shifts_page.dart';

/// The overview: the month at the top, and the sections the spec asks for.
///
/// Every card opens something — the month chosen here is the month each
/// section loads, and it survives coming back.
class MainPage extends StatelessWidget {
  const MainPage({super.key, required this.onSignedOut});

  final VoidCallback onSignedOut;

  @override
  Widget build(BuildContext context) {
    final period = App.instance.period;
    final auth = App.instance.auth;
    return Scaffold(
      backgroundColor: kSurfaceColor,
      appBar: AppBar(
        backgroundColor: kSurfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          appName,
          style: TextStyle(
            color: kBlackColor,
            fontFamily: gilroyBold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Выйти',
            onPressed: () => _signOut(context),
            icon: const AppIcon(AppIcons.signOut, size: 20),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: period,
          builder: (context, _) {
            // Rebuilt with the month so every card carries the current range.
            final range = Period.range(period.fromDate, period.toDate);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              children: [
                const Text(
                  'Обзор',
                  style: TextStyle(
                    color: kBlackColor,
                    fontFamily: gilroyBold,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Смены, месяц и контроль действий. Все данные — время '
                  'Ашхабада, UTC+5.',
                  style: TextStyle(
                    color: kMutedColor,
                    fontFamily: gilroyMedium,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                const MonthBar(subtitle: 'Период для всех разделов'),
                const SizedBox(height: 16),
                SectionCard(
                  icon: AppIcons.orders,
                  title: 'Заказы',
                  subtitle: 'По созданию и по возврату денег',
                  onTap: () => _open(
                    context,
                    OrdersPage(
                      period: range,
                      basis: OrderBasis.created,
                      title: 'Заказы',
                      subtitle: 'Период: ${period.fromDate} — ${period.toDate}',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SectionCard(
                  icon: AppIcons.shifts,
                  title: 'Смены и деньги',
                  subtitle: 'Суммы к сдаче, пакеты и их авторы',
                  color: kPositiveColor,
                  onTap: () => _open(context, const ShiftsPage()),
                ),
                const SizedBox(height: 10),
                SectionCard(
                  icon: AppIcons.charts,
                  title: 'Графики',
                  subtitle: 'Заказы, деньги, районы и блюда за месяц',
                  onTap: () => _open(context, const MonthPage()),
                ),
                const SizedBox(height: 10),
                SectionCard(
                  icon: AppIcons.journal,
                  title: 'Кто что сделал',
                  subtitle: 'История и контроль действий',
                  onTap: () => _open(
                    context,
                    AuditPage(
                      period: range,
                      title: 'Кто что сделал',
                      subtitle: 'Период: ${period.fromDate} — ${period.toDate}',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SectionCard(
                  icon: AppIcons.carryIn,
                  title: 'Принято от смены',
                  subtitle: 'Незавершённые заказы на входе периода',
                  color: kWarningColor,
                  onTap: () => _open(
                    context,
                    CarryoverScreen(
                      period: range,
                      incoming: true,
                      subtitle: '${period.fromDate} — ${period.toDate}',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SectionCard(
                  icon: AppIcons.carryOut,
                  title: 'Передано смене',
                  subtitle: 'Незавершённые заказы на выходе периода',
                  color: kWarningColor,
                  onTap: () => _open(
                    context,
                    CarryoverScreen(
                      period: range,
                      incoming: false,
                      subtitle: '${period.fromDate} — ${period.toDate}',
                    ),
                  ),
                ),
                const SectionTitle('Учётная запись', icon: AppIcons.access),
                CardBox(
                  child: Column(
                    children: [
                      InfoRow(
                        label: 'Сотрудник',
                        value: (auth.displayName ?? '').trim().isEmpty
                            ? (auth.phone ?? kUnknown)
                            : auth.displayName!.trim(),
                        icon: AppIcons.person,
                      ),
                      InfoRow(
                        label: 'Роль',
                        value: switch (auth.role) {
                          StaffRole.accountant => 'Бухгалтер',
                          StaffRole.superAdmin => 'Владелец',
                          StaffRole.other => kUnknown,
                        },
                        icon: AppIcons.access,
                      ),
                      const InfoRow(
                        label: 'Права',
                        // The accountant gets a view, not the right to edit or
                        // cancel orders.
                        value: 'Просмотр и подтверждение денежного пакета',
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page),
      );

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: borderRadius15),
        title: const Text(
          'Выйти из приложения?',
          style: TextStyle(fontFamily: gilroySemiBold, fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена',
                style: TextStyle(fontFamily: gilroyMedium)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Выйти',
              style:
                  TextStyle(fontFamily: gilroySemiBold, color: kNegativeColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await App.instance.signOut();
    onSignedOut();
  }
}
