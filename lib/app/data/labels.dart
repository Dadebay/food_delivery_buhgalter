import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/constants.dart';
import 'formatting.dart';
import 'strings.dart';

String _t(String ru, String tm) => S.pick(ru, tm);

/// The wording dictionary, mirroring the web client's
/// `widgets/accounting-dashboard/model/inspection.ts`.
///
/// It is a dictionary of captions, not a second status machine: nothing here
/// decides what happened, it only names what the server already said. An
/// action this build does not know is never hidden — [auditAction] falls back
/// to «Изменение записи» and the screen shows the raw payload with it.
class Labels {
  const Labels._();

  static Map<String, String> get auditActions => {
        'order.created':
            _t('Заказ создан в приложении', 'Sargyt programmada döredildi'),
        'order.created_by_staff':
            _t('Заказ оформлен по телефону', 'Sargyt telefon arkaly alyndy'),
        'order.admin-edited':
            _t('Заказ отредактирован', 'Sargyt üýtgedildi'),
        'order.cancelled': _t('Заказ отменён', 'Sargyt ýatyryldy'),
        'order.packing-confirmed':
            _t('Сборка подтверждена', 'Ýygnalmagy tassyklandy'),
        'order.courier-assigned':
            _t('Курьер назначен', 'Kurýer bellenildi'),
        'order.courier-reassigned':
            _t('Курьер заменён', 'Kurýer çalşyryldy'),
        'order.transitioned':
            _t('Статус заказа изменён', 'Sargydyň ýagdaýy üýtgedi'),
        'order.request.rejected':
            _t('Действие с заказом отклонено', 'Sargyt hereketi ret edildi'),
        'app.request.rejected': _t(
          'Запрос из приложения отклонён',
          'Programmadan gelen sorag ret edildi',
        ),
        'users.request.rejected': _t(
          'Запрос по сотрудникам отклонён',
          'Işgärler boýunça sorag ret edildi',
        ),
        'receipt.delivery_result': _t(
          'Результат отправки чека',
          'Çekiň iberiliş netijesi',
        ),
        'receipt.reprint_requested': _t(
          'Запрошена повторная печать чека',
          'Çekiň gaýtadan çap edilmegi soraldy',
        ),
        'receipt.printed': _t('Чек напечатан', 'Çek çap edildi'),
        'receipt.print_failed': _t('Чек не напечатан', 'Çek çap edilmedi'),
        'receipt.queued': _t('Чек поставлен в очередь', 'Çek nobata goýuldy'),
        'receipt.created': _t('Чек создан', 'Çek döredildi'),
        'receipt.cancelled': _t('Чек отменён', 'Çek ýatyryldy'),
        'cash_handoff.submitted':
            _t('Деньги смены переданы', 'Çalşygyň puly tabşyryldy'),
        'cash_handoff.confirmed':
            _t('Деньги смены подтверждены', 'Çalşygyň puly tassyklandy'),
        'order.historical-cash-reconciled': _t(
          'Отмечена ранее сданная оплата',
          'Öň tabşyrylan töleg bellenildi',
        ),
        'order.historical-completion-requested': _t(
          'Историческое завершение по поручению владельца',
          'Eýesiniň tabşyrygy boýunça taryhy tamamlama',
        ),
      };

  /// An action this build does not know is never hidden. A rejected request
  /// is recognised by its shape even when the section is one the app has not
  /// been told about, because «запрос отклонён» is the part that matters.
  static String auditAction(String? action) {
    final known = auditActions[action];
    if (known != null) return known;
    if (action != null && action.endsWith('.request.rejected')) {
      return _t('Запрос отклонён', 'Sorag ret edildi');
    }
    return _t('Изменение записи', 'Ýazgynyň üýtgemegi');
  }

  static bool isKnownAction(String? action) =>
      action != null && auditActions.containsKey(action);

  static Map<String, String> get entities => {
        'ORDER': _t('Заказ', 'Sargyt'),
        'CASH_HANDOFF': _t('Денежный пакет', 'Pul bukjasy'),
        'PRODUCT': _t('Блюдо', 'Tagam'),
        'CATEGORY': _t('Категория', 'Kategoriýa'),
        'BRANCH': _t('Филиал', 'Şahamça'),
        'PROMO_CODE': _t('Промокод', 'Promokod'),
        'BANNER': _t('Баннер', 'Banner'),
        'CONTACT': _t('Контакт', 'Habarlaşmak'),
        'USER': _t('Сотрудник', 'Işgär'),
        'STAFF': _t('Сотрудник', 'Işgär'),
        'SCHEDULE': _t('Расписание', 'Tertip'),
        'SETTINGS': _t('Настройки', 'Sazlamalar'),
        'STOCK': _t('Склад', 'Ammar'),
        'TARIFF': _t('Тариф', 'Nyrh'),
        'RECEIPT': _t('Чек', 'Çek'),
        'SETTLEMENT': _t('Денежная запись', 'Pul ýazgysy'),
        'CUSTOMER': _t('Клиент', 'Müşderi'),
        'COURIER': _t('Курьер', 'Kurýer'),
        'VARIANT': _t('Вариант блюда', 'Tagamyň görnüşi'),
        'ETRAP': _t('Район', 'Etrap'),
        'DISTRICT': _t('Район', 'Etrap'),
        'ROLE': _t('Роль', 'Wezipe'),
        'PERMISSION': _t('Право доступа', 'Rugsat'),
        'DEVICE': _t('Устройство', 'Enjam'),
        'PRINTER': _t('Принтер', 'Printer'),
        'NOTIFICATION': _t('Уведомление', 'Habarnama'),
        'LOYALTY': _t('Баллы', 'Ballar'),
      };

  static String entity(String? type) =>
      entities[(type ?? '').toUpperCase()] ?? (type ?? kDash);

  /// Field names inside a before/after comparison. Unknown keys keep their
  /// raw name so nothing is silently dropped.
  static Map<String, String> get fields => {
        'status': _t('Статус', 'Ýagdaý'),
        'total': _t('Итого', 'Jemi'),
        'subtotal': _t('Сумма позиций', 'Harytlaryň möçberi'),
        'discount': _t('Скидка', 'Arzanladyş'),
        'foodAmount': _t('Сумма еды', 'Nahar möçberi'),
        'deliveryFee': _t('Доставка', 'Eltip berme'),
        'address': _t('Адрес', 'Salgy'),
        'entrance': _t('Подъезд', 'Girelge'),
        'floor': _t('Этаж', 'Gat'),
        'apartment': _t('Квартира', 'Kwartira'),
        'items': _t('Состав', 'Düzümi'),
        'courierId': _t('Курьер', 'Kurýer'),
        'cookId': _t('Повар', 'Aşpez'),
        'cancelReason': _t('Причина отмены', 'Ýatyrylyş sebäbi'),
        'cancellationReason': _t('Причина отмены', 'Ýatyrylyş sebäbi'),
        'note': _t('Комментарий', 'Bellik'),
        'customerName': _t('Клиент', 'Müşderi'),
        'customerPhone': _t('Телефон', 'Telefon'),
        'customerNote': _t('Пожелание клиента', 'Müşderiniň islegi'),
        'branchName': _t('Кухня', 'Aşhana'),
        'branchId': _t('Кухня', 'Aşhana'),
        'deliveryEtrapName': _t('Район', 'Etrap'),
        'preparationMinutes':
            _t('Время приготовления', 'Taýýarlanyş wagty'),
        'name': _t('Название', 'Ady'),
        'price': _t('Цена', 'Bahasy'),
        'isActive': _t('Активно', 'Işjeň'),
        'declaredAmount': _t('Заявленная сумма', 'Yglan edilen möçber'),
        'expectedAmount': _t('Ожидаемая сумма', 'Garaşylýan möçber'),
        'quantity': _t('Количество', 'Mukdary'),
        'productName': _t('Блюдо', 'Tagam'),
        'variantName': _t('Вариант', 'Görnüşi'),
        'unitPrice': _t('Цена за штуку', 'Birligiň bahasy'),
        'lineTotal': _t('Сумма строки', 'Setiriň jemi'),
        'reason': _t('Причина', 'Sebäbi'),
        'comment': _t('Комментарий', 'Bellik'),
        'phone': _t('Телефон', 'Telefon'),
        'role': _t('Роль', 'Wezipe'),
        'startsAt': _t('Начало', 'Başlanýar'),
        'endsAt': _t('Конец', 'Gutarýar'),
        'createdAt': _t('Создано', 'Döredildi'),
        'updatedAt': _t('Изменено', 'Üýtgedildi'),
        'printedAt': _t('Напечатано', 'Çap edildi'),
        'receiptId': _t('Чек', 'Çek'),
        'printerName': _t('Принтер', 'Printer'),
        'success': _t('Успешно', 'Üstünlikli'),
        'error': _t('Ошибка', 'Ýalňyşlyk'),
      };

  static String field(String key) => fields[key] ?? key;

  static Map<String, String> get orderStatuses => {
        'NEW': _t('Новый', 'Täze'),
        'PENDING': _t('Ожидает', 'Garaşýar'),
        'ACCEPTED': _t('Принят', 'Kabul edildi'),
        'COOKING': _t('Готовится', 'Taýýarlanýar'),
        'READY': _t('Готов', 'Taýýar'),
        'ASSIGNED_TO_COURIER': _t('Назначен курьеру', 'Kurýere berildi'),
        'OUT_FOR_DELIVERY': _t('В доставке', 'Ýolda'),
        'DELIVERED': _t('Доставлен', 'Eltildi'),
        'CASH_RETURNED': _t('Деньги возвращены', 'Pul gaýtaryldy'),
        'RECONCILED': _t('Сверен', 'Deňeşdirilen'),
        'CANCELLED': _t('Отменён', 'Ýatyryldy'),
        'DRAFT': _t('Черновик', 'Çyzgy'),
        'CONFIRMED': _t('Подтверждён', 'Tassyklandy'),
        'PREPARING': _t('Готовится', 'Taýýarlanýar'),
        'ON_THE_WAY': _t('В доставке', 'Ýolda'),
        'COMPLETED': _t('Завершён', 'Tamamlandy'),
        'RETURNED': _t('Возвращён', 'Yzyna gaýtaryldy'),
        'REJECTED': _t('Отклонён', 'Ret edildi'),
        'WAITING_PAYMENT': _t('Ожидает оплаты', 'Töleg garaşýar'),
        'PAID': _t('Оплачен', 'Tölendi'),
      };

  static String orderStatus(String? status) =>
      orderStatuses[(status ?? '').toUpperCase()] ?? (status ?? kDash);

  static Color orderStatusColor(String? status) =>
      switch ((status ?? '').toUpperCase()) {
        'CANCELLED' => kNegativeColor,
        'RECONCILED' || 'CASH_RETURNED' => kPositiveColor,
        'DELIVERED' => kPrimaryColor,
        'COOKING' || 'READY' || 'ASSIGNED_TO_COURIER' || 'OUT_FOR_DELIVERY' =>
          kWarningColor,
        _ => kMutedColor,
      };

  static Map<String, String> get handoffStatuses => {
        'SUBMITTED': _t('Ждёт подтверждения', 'Tassyklanmaga garaşýar'),
        'CONFIRMED': _t('Подтверждён', 'Tassyklandy'),
        'PENDING': _t('Не передан', 'Tabşyrylmadyk'),
        'REJECTED': _t('Отклонён', 'Ret edildi'),
        'DRAFT': _t('Черновик', 'Çyzgy'),
        'CANCELLED': _t('Отменён', 'Ýatyryldy'),
      };

  static String handoffStatus(String? status) =>
      handoffStatuses[(status ?? '').toUpperCase()] ??
      (status ?? S.packetNotCreated);

  static Color handoffStatusColor(String? status) =>
      switch ((status ?? '').toUpperCase()) {
        'CONFIRMED' => kPositiveColor,
        'SUBMITTED' => kWarningColor,
        'REJECTED' => kNegativeColor,
        _ => kMutedColor,
      };

  /// A participant's action, including the `transition:<OrderStatus>` shape
  /// the API assembles from the stored events.
  static String participantAction(String action) {
    if (action.startsWith('transition:')) {
      final status = orderStatus(action.substring('transition:'.length));
      return _t('Статус → $status', 'Ýagdaý → $status');
    }
    return auditActions[action] ?? action;
  }

  /// `first`/`second` when the settings have not been read yet. The real
  /// names and times come from `GET /accounting/settings`; 09:30/19:00 is
  /// never baked into the app.
  static String shiftSlot(String slot) => switch (slot) {
        'first' => S.firstShift,
        'second' => S.secondShift,
        _ => S.shift,
      };

  static String orderSource(String? source) =>
      switch ((source ?? '').toUpperCase()) {
        'APP' || 'MOBILE' => _t('Приложение', 'Programma'),
        'STAFF' || 'CALL' || 'PHONE' => _t('По телефону', 'Telefon arkaly'),
        'WEB' => _t('Сайт', 'Saýt'),
        _ => source == null || source.isEmpty ? kUnknown : source,
      };

  static List<List<dynamic>> auditIcon(String? action) => switch (action) {
        'order.created' || 'order.created_by_staff' => AppIcons.orders,
        'order.admin-edited' => AppIcons.edited,
        'order.cancelled' || 'order.request.rejected' => AppIcons.cancelled,
        'order.packing-confirmed' => AppIcons.packing,
        'order.courier-assigned' ||
        'order.courier-reassigned' =>
          AppIcons.courier,
        'order.transitioned' => AppIcons.transition,
        'receipt.printed' ||
        'receipt.created' ||
        'receipt.queued' ||
        'receipt.delivery_result' ||
        'receipt.reprint_requested' ||
        'receipt.print_failed' ||
        'receipt.cancelled' =>
          AppIcons.note,
        'cash_handoff.submitted' => AppIcons.submitted,
        'cash_handoff.confirmed' => AppIcons.confirmed,
        'order.historical-cash-reconciled' ||
        'order.historical-completion-requested' =>
          AppIcons.history,
        _ => (action ?? '').endsWith('.request.rejected')
            ? AppIcons.cancelled
            : AppIcons.details,
      };
}
