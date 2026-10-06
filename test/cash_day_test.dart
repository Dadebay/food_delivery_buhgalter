import 'package:flutter_test/flutter_test.dart';
import 'package:accounting_app/app/data/models/shift.dart';

Map<String, dynamic> packet(String id, String status, {String key = '2026-10-04:day'}) => {
      'id': id,
      'shiftKey': key,
      'status': status,
      'expectedAmount': 1250.5,
      'declaredAmount': 1200,
      'periodStart': '2026-10-03T19:00:00.000Z',
      'periodEnd': '2026-10-04T19:00:00.000Z',
    };

void main() {
  test('day card parses packets, dedups by id and finds pending ones', () {
    final day = CashDay.fromJson({
      'shiftKey': '2026-10-04:day',
      'isComplete': true,
      'expectedAmount': 1250.5,
      'availableAmount': 0,
      'settlementCount': 12,
      'canSubmit': false,
      'state': 'SUBMITTED',
      'handoff': packet('a', 'SUBMITTED'),
      'historicalHandoffs': [
        packet('a', 'SUBMITTED'),
        packet('b', 'CONFIRMED', key: '2026-10-04:first'),
        packet('c', 'SUBMITTED', key: '2026-10-04:second'),
      ],
    });
    expect(day.dayKey, '2026-10-04');
    expect(day.packets.map((p) => p.id), ['a', 'b', 'c']);
    expect(day.pending.map((p) => p.id), ['a', 'c']);
    expect(day.packets.first.discrepancy, closeTo(-50.5, 0.001));
    expect(day.canCreatePacket, isFalse);
  });

  test('a finished day with money and no packet can be handed over', () {
    final day = CashDay.fromJson({
      'shiftKey': '2026-10-04:day',
      'isComplete': true,
      'canSubmit': true,
      'state': 'READY',
      'handoff': null,
      'historicalHandoffs': [],
    });
    expect(day.canCreatePacket, isTrue);
    expect(day.pending, isEmpty);
  });
}
