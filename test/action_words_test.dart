import 'package:accounting_app/app/data/action_words.dart';
import 'package:accounting_app/app/data/labels.dart';
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

  test('event codes are translated half by half and agree in gender', () {
    expect(ActionWords.describe('address.activated'), 'Адрес активирован');
    expect(ActionWords.describe('product.activated'), 'Блюдо активировано');
    expect(ActionWords.describe('category.deleted'), 'Категория удалена');
    expect(ActionWords.describe('settings.updated'), 'Настройки обновлены');
    expect(ActionWords.describe('promo-code.rejected'), 'Промокод отклонён');
    expect(ActionWords.describe('banner.rejected'), 'Баннер отклонён');
    expect(ActionWords.describe('product.price_changed'),
        'Блюдо: цена изменена');
  });

  test('unknown halves are not guessed', () {
    expect(ActionWords.describe('spaceship.launched'), isNull);
    expect(ActionWords.describe('address'), isNull);
    expect(Labels.auditAction('spaceship.launched'), 'Изменение записи');
    expect(Labels.auditAction('address.teleported'), 'Адрес: изменение');
  });

  test('exact captions still win', () {
    expect(Labels.auditAction('order.cancelled'), 'Заказ отменён');
    expect(Labels.field('branchId'), 'Кухня');
  });
}
