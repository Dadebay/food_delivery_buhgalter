import 'package:flutter/material.dart';

import '../../../constants/constants.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kSurfaceColor,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          appName,
          style: TextStyle(
            color: kBlackColor,
            fontFamily: gilroyBold,
            fontSize: 24,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: const [
            Text(
              'Обзор',
              style: TextStyle(
                color: kBlackColor,
                fontFamily: gilroyBold,
                fontSize: 28,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Смены, месяц и контроль действий',
              style: TextStyle(
                color: kMutedColor,
                fontFamily: gilroyMedium,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 24),
            _SectionCard(
              icon: Icons.schedule_rounded,
              title: 'Смены',
              subtitle: 'Текущие и завершённые смены',
            ),
            SizedBox(height: 12),
            _SectionCard(
              icon: Icons.calendar_month_rounded,
              title: 'Месяц',
              subtitle: 'Отчёты и динамика за месяц',
            ),
            SizedBox(height: 12),
            _SectionCard(
              icon: Icons.fact_check_outlined,
              title: 'Журнал',
              subtitle: 'История и контроль действий',
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kBorderColor),
        borderRadius: borderRadius15,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xffeeeeff),
              borderRadius: borderRadius15,
            ),
            child: Icon(icon, color: kPrimaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kBlackColor,
                    fontFamily: gilroySemiBold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: kMutedColor,
                    fontFamily: gilroyRegular,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
