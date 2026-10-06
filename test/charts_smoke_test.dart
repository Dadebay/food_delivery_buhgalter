import 'package:accounting_app/app/data/ashgabat_time.dart';
import 'package:accounting_app/app/data/models/report.dart';
import 'package:accounting_app/app/widgets/daily_charts.dart';
import 'package:accounting_app/app/widgets/ranked_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => '.',
    );
    await GetStorage.init();
  });

  Future<void> pumpAt(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('charts and ranked cards lay out on a 360 px phone',
      (tester) async {
    final month = DateTime(2026, 10, 1);
    final money = alignMoney(month, [
      for (var d = 1; d <= 20; d++)
        DailyMoney(
            date: '2026-10-${d.toString().padLeft(2, '0')}',
            amount: 100.0 * d,
            orderCount: d),
    ]);
    await pumpAt(
      tester,
      Column(children: [
        DailyMoneyChart(points: money, onDayTap: (_) {}),
        const SizedBox(height: 14),
        DailyOrdersChart(points: money, onDayTap: (_) {}),
        const SizedBox(height: 14),
        RankedCard(
          title: 'Районы',
          icon: const [],
          rows: [
            for (var i = 0; i < 9; i++)
              RankRow(name: 'Район номер $i', count: 40 - i * 3, amount: 500.0 * i),
          ],
        ),
      ]),
    );
    expect(tester.takeException(), isNull);
    expect(Ashgabat.date(month), '2026-10-01');
  });
}
