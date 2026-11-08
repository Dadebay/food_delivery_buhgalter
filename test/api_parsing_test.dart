import 'package:accounting_app/app/data/models/overview.dart';
import 'package:accounting_app/app/data/models/paged.dart';
import 'package:accounting_app/app/data/models/report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('missing accounting totals are rejected instead of shown as zero', () {
    expect(
        () => AccountingReport.fromJson({'daily': []}), throwsFormatException);
    expect(() => AccountingOverview.fromJson({'daily': []}),
        throwsFormatException);
  });

  test('a missing paging envelope is rejected instead of shown as empty', () {
    expect(
      () => Paged<Map<String, dynamic>>.fromJson(
        {'items': []},
        (value) => value,
      ),
      throwsFormatException,
    );
  });
}
