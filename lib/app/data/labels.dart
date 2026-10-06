import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/constants.dart';
import 'action_words.dart';
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
        'cash_handoff.submitted':
            _t('Деньги за день переданы', 'Güniň puly tabşyryldy'),
        'cash_handoff.confirmed':
            _t('Деньги за день подтверждены', 'Güniň puly tassyklandy'),
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
    // `address.activated`, `product.created`, … — translated half by half.
    final composed = ActionWords.describe(action);
    if (composed != null) return composed;
    // The section is known but the verb is not: say which section changed.
    final noun = ActionWords.entity(ActionWords.entityKey(action));
    if (noun != null) return '$noun: ${_t('изменение', 'üýtgeşme')}';
    return _t('Изменение записи', 'Ýazgynyň üýtgemegi');
  }

  static bool isKnownAction(String? action) =>
      action != null &&
      (auditActions.containsKey(action) ||
          ActionWords.describe(action) != null);

  /// The colour an event reads in: red for what removes or refuses, green
  /// for what adds or approves, orange for a hand-over, indigo otherwise.
  static Color auditColor(String? action) {
    if (action == null) return kPrimaryColor;
    if (action.endsWith('.rejected') || action.endsWith('.cancelled')) {
      return kNegativeColor;
    }
    if (action.startsWith('cash_handoff.submitted') ||
        action == 'order.transitioned') {
      return kWarningColor;
    }
    if (ActionWords.isNegative(action)) return kNegativeColor;
    if (ActionWords.isPositive(action) ||
        action == 'cash_handoff.confirmed') {
      return kPositiveColor;
    }
    return kPrimaryColor;
  }

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
        ...ActionWords.entityNames,
      };

  static String entity(String? type) =>
      entities[(type ?? '').toUpperCase()] ??
      ActionWords.entity(type) ??
      (type ?? kDash);

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
        'title': _t('Название', 'Ady'),
        'description': _t('Описание', 'Düşündiriş'),
        'phone': _t('Телефон', 'Telefon'),
        'email': _t('Почта', 'E-poçta'),
        'firstName': _t('Имя', 'Ady'),
        'lastName': _t('Фамилия', 'Familiýasy'),
        'role': _t('Роль', 'Wezipe'),
        'code': _t('Код', 'Kod'),
        'street': _t('Улица', 'Köçe'),
        'house': _t('Дом', 'Jaý'),
        'city': _t('Город', 'Şäher'),
        'district': _t('Район', 'Etrap'),
        'latitude': _t('Широта', 'Giňlik'),
        'longitude': _t('Долгота', 'Uzaklyk'),
        'isDefault': _t('Основной', 'Esasy'),
        'isBlocked': _t('Заблокирован', 'Bloklanan'),
        'isAvailable': _t('Доступно', 'Elýeterli'),
        'active': _t('Активно', 'Işjeň'),
        'image': _t('Фото', 'Surat'),
        'imageUrl': _t('Фото', 'Surat'),
        'photo': _t('Фото', 'Surat'),
        'sortOrder': _t('Порядок', 'Tertip'),
        'position': _t('Порядок', 'Tertip'),
        'quantity': _t('Количество', 'Sany'),
        'amount': _t('Сумма', 'Möçber'),
        'percent': _t('Процент', 'Göterim'),
        'discountPercent': _t('Скидка, %', 'Arzanladyş, %'),
        'startsAt': _t('Начало', 'Başlangyç'),
        'endsAt': _t('Конец', 'Soňy'),
        'startDate': _t('Начало', 'Başlangyç'),
        'endDate': _t('Конец', 'Soňy'),
        'categoryId': _t('Категория', 'Kategoriýa'),
        'categoryName': _t('Категория', 'Kategoriýa'),
        'productName': _t('Блюдо', 'Tagam'),
        'variantName': _t('Вариант', 'Görnüş'),
        'type': _t('Тип', 'Görnüşi'),
        'language': _t('Язык', 'Dil'),
        'deliveryAddress': _t('Адрес доставки', 'Eltip bermek salgysy'),
        'cookingTime': _t('Время приготовления', 'Taýýarlanyş wagty'),
        'version': _t('Версия', 'Wersiýa'),
        'addressLandmark': _t('Ориентир', 'Nyşan'),
        'landmark': _t('Ориентир', 'Nyşan'),
        'addressLocationStatus':
            _t('Статус геопозиции', 'Ýerleşiş ýagdaýy'),
        'locationStatus': _t('Статус геопозиции', 'Ýerleşiş ýagdaýy'),
        'addressLatitude': _t('Широта', 'Giňlik'),
        'addressLongitude': _t('Долгота', 'Uzaklyk'),
        'addressText': _t('Адрес', 'Salgy'),
        'addressNote': _t('Комментарий к адресу', 'Salgy barada bellik'),
      };

  /// A saved field name in words. An exact caption wins; a trailing `Id` is
  /// dropped so `branchId`-style keys find their noun; anything still unknown
  /// keeps its raw name rather than being guessed at.
  static String field(String key) {
    final exact = fields[key];
    if (exact != null) return exact;
    if (key.length > 2 && key.endsWith('Id')) {
      final base = fields[key.substring(0, key.length - 2)];
      if (base != null) return base;
    }
    // `addressEntrance`, `addressFloor`, … — the same field, prefixed with
    // the section it belongs to.
    if (key.length > 7 && key.startsWith('address')) {
      final rest = key.substring(7);
      final base = fields['${rest[0].toLowerCase()}${rest.substring(1)}'];
      if (base != null) return base;
    }
    return key;
  }

  /// A saved value that is a status-like word, in the reader's language.
  static String? valueWord(String value) => switch (value.toUpperCase()) {
        'ACTIVE' => _t('Активно', 'Işjeň'),
        'INACTIVE' => _t('Неактивно', 'Işjeň däl'),
        'ENABLED' => _t('Включено', 'Açyk'),
        'DISABLED' => _t('Отключено', 'Öçük'),
        'BLOCKED' => _t('Заблокировано', 'Bloklanan'),
        'ARCHIVED' => _t('В архиве', 'Arhiwde'),
        'DRAFT' => _t('Черновик', 'Garalama'),
        'PUBLISHED' => _t('Опубликовано', 'Çap edildi'),
        'GPS' => _t('По GPS', 'GPS boýunça'),
        'MANUAL' => _t('Вручную', 'Elde'),
        'UNKNOWN' => _t('Неизвестно', 'Näbelli'),
        'NOT_SET' || 'NONE' => _t('Не указано', 'Görkezilmedi'),
        'VERIFIED' || 'CONFIRMED' => _t('Подтверждено', 'Tassyklandy'),
        'UNVERIFIED' => _t('Не подтверждено', 'Tassyklanmady'),
        'APPROXIMATE' => _t('Приблизительно', 'Takmynan'),
        'EXACT' => _t('Точно', 'Takyk'),
        'TRUE' => S.yes,
        'FALSE' => S.no,
        _ => null,
      };

  static Map<String, String> get orderStatuses => {
        'NEW': _t('Новый', 'Täze'),
        'PENDING': _t('Ожидает', 'Garaşýar'),
        'ACCEPTED': _t('Принят', 'Kabul edildi'),
        'COOKING': _t('Готовится', 'Taýýarlanýar'),
        'READY': _t('Готов', 'Taýýar'),
        'ASSIGNED_TO_COURIER': _t('Назначен курьеру', 'Kurýere berildi'),
        'OUT_FOR_DELIVERY': _t('В доставке', 'Ýolda'),
        'DELIVERED': _t('Доставлен', 'Eltildi'),
        'CASH_RETURNED': _t('Деньги получены', 'Puly alnan'),
        'RECONCILED': _t('Сверен', 'Deňeşdirilen'),
        'CANCELLED': _t('Отменён', 'Ýatyryldy'),
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
        'CONFIRMED': _t('Принято', 'Kabul edildi'),
        'PENDING': _t('Не передан', 'Tabşyrylmadyk'),
        'REJECTED': _t('Отклонён', 'Ret edildi'),
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

  /// The state of a whole day card, as `/accounting/days` reports it.
  static String dayState(String? state) =>
      switch ((state ?? '').toUpperCase()) {
        'OPEN' => _t('День идёт', 'Gün dowam edýär'),
        'EMPTY' => _t('Денег нет', 'Pul ýok'),
        'READY' => _t('Можно сдать', 'Tabşyrmaga taýyn'),
        'SUBMITTED' => _t('Ждёт подтверждения', 'Tassyklanmaga garaşýar'),
        'CONFIRMED' => _t('Принято', 'Kabul edildi'),
        _ => state == null || state.isEmpty ? kDash : state,
      };

  static Color dayStateColor(String? state) =>
      switch ((state ?? '').toUpperCase()) {
        'CONFIRMED' => kPositiveColor,
        'SUBMITTED' => kWarningColor,
        'READY' => kPrimaryColor,
        _ => kMutedColor,
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
        'cash_handoff.submitted' => AppIcons.submitted,
        'cash_handoff.confirmed' => AppIcons.confirmed,
        'order.historical-cash-reconciled' ||
        'order.historical-completion-requested' =>
          AppIcons.history,
        _ => _genericIcon(action),
      };

  /// For an event the app has no exact icon for: the section it belongs to if
  /// that has a recognisable glyph, otherwise what happened to it.
  static List<List<dynamic>> _genericIcon(String? action) {
    if ((action ?? '').endsWith('.request.rejected')) return AppIcons.cancelled;
    switch (ActionWords.entityKey(action)) {
      case 'address' || 'customer_address' || 'district' || 'etrap':
        return AppIcons.address;
      case 'product' || 'dish' || 'variant' || 'menu' || 'category':
        return AppIcons.dish;
      case 'branch' || 'kitchen':
        return AppIcons.branch;
      case 'courier':
        return AppIcons.courier;
      case 'user' || 'users' || 'staff' || 'employee' || 'customer':
        return AppIcons.person;
    }
    if (ActionWords.isNegative(action)) return AppIcons.cancelled;
    if (ActionWords.isEdit(action)) return AppIcons.edited;
    if (ActionWords.isPositive(action)) return AppIcons.confirmed;
    return AppIcons.details;
  }

  /// Normalises a server key so `cash_returned`, `CASH-RETURNED` and
  /// «Cash Returned» all find the same caption.
  static String _key(String? value) => (value ?? '')
      .trim()
      .toUpperCase()
      .replaceAll(RegExp(r'[\s\-]+'), '_');

  /// The money record's own state, as shown on an order.
  ///
  /// It is a different machine from the order status — money can still be
  /// with the operator after the food was delivered — so it has its own
  /// dictionary. An unknown state falls back to the order statuses and only
  /// then to the raw word, so nothing the server invents is ever hidden.
  static Map<String, String> get settlementStatuses => {
        'PENDING': _t('Ожидает возврата', 'Gaýtarylmagyna garaşýar'),
        'NOT_RETURNED': _t('Деньги не вернули', 'Pul gaýtarylmady'),
        'WITH_COURIER': _t('У курьера', 'Kurýerde'),
        'WITH_OPERATOR': _t('У оператора', 'Operatorda'),
        'RETURNED': _t('Деньги получены', 'Puly alnan'),
        'CASH_RETURNED': _t('Деньги получены', 'Puly alnan'),
        'COLLECTED': _t('Получено', 'Alyndy'),
        'SUBMITTED': _t('Передано в пакете', 'Bukjada tabşyryldy'),
        'HANDED_OVER': _t('Передано в пакете', 'Bukjada tabşyryldy'),
        'CONFIRMED': _t('Подтверждено', 'Tassyklandy'),
        'RECONCILED': _t('Сверено', 'Deňeşdirilen'),
        'CANCELLED': _t('Отменено', 'Ýatyryldy'),
        'REFUNDED': _t('Возврат клиенту', 'Müşderä gaýtaryldy'),
        'WRITTEN_OFF': _t('Списано', 'Hasapdan öçürildi'),
      };

  static String settlementStatus(String? status) {
    final key = _key(status);
    return settlementStatuses[key] ??
        orderStatuses[key] ??
        (status == null || status.trim().isEmpty ? kDash : status);
  }

  static Color settlementStatusColor(String? status) =>
      switch (_key(status)) {
        'RECONCILED' || 'CONFIRMED' || 'RETURNED' || 'CASH_RETURNED' =>
          kPositiveColor,
        'CANCELLED' || 'REFUNDED' || 'WRITTEN_OFF' => kNegativeColor,
        'SUBMITTED' || 'HANDED_OVER' || 'COLLECTED' => kPrimaryColor,
        'PENDING' || 'NOT_RETURNED' || 'WITH_COURIER' || 'WITH_OPERATOR' =>
          kWarningColor,
        _ => kMutedColor,
      };

  /// A staff role as the server spells it. Roles reach the screens straight
  /// from the account record, so they are translated here rather than shown
  /// as `SUPER_ADMIN`.
  static Map<String, String> get roles => {
        'SUPER_ADMIN': _t('Владелец', 'Eýesi'),
        'ADMIN': _t('Администратор', 'Administrator'),
        'ACCOUNTANT': _t('Бухгалтер', 'Buhgalter'),
        'MANAGER': _t('Менеджер', 'Menejer'),
        'OPERATOR': _t('Оператор', 'Operator'),
        'CALL_CENTER': _t('Колл-центр', 'Kol-merkez'),
        'CASHIER': _t('Кассир', 'Kassir'),
        'COURIER': _t('Курьер', 'Kurýer'),
        'COOK': _t('Повар', 'Aşpez'),
        'CHEF': _t('Шеф-повар', 'Baş aşpez'),
        'PACKER': _t('Сборщик', 'Ýygnaýjy'),
        'WAITER': _t('Официант', 'Ofisiant'),
        'STAFF': _t('Сотрудник', 'Işgär'),
        'CLIENT': _t('Клиент', 'Müşderi'),
        'CUSTOMER': _t('Клиент', 'Müşderi'),
        'SYSTEM': _t('Система', 'Ulgam'),
      };

  static String role(String? value) {
    if (value == null || value.trim().isEmpty) return S.staff;
    return roles[_key(value)] ?? value.trim();
  }

  /// Why an order was cancelled. The server sends either a key or free text
  /// somebody typed; a key is translated and free text is shown as written,
  /// because paraphrasing somebody's note would change the record.
  static Map<String, String> get cancelReasons => {
        'CUSTOMER_REQUEST': _t('Просьба клиента', 'Müşderiniň haýyşy'),
        'CUSTOMER_CANCELLED': _t('Клиент отменил', 'Müşderi ýatyrdy'),
        'CUSTOMER_NOT_AVAILABLE':
            _t('Клиент недоступен', 'Müşderi elýeterli däl'),
        'NO_ANSWER': _t('Клиент не отвечает', 'Müşderi jogap bermeýär'),
        'WRONG_NUMBER': _t('Неверный номер', 'Nädogry belgi'),
        'WRONG_ADDRESS': _t('Неверный адрес', 'Nädogry salgy'),
        'ADDRESS_NOT_FOUND': _t('Адрес не найден', 'Salgy tapylmady'),
        'OUT_OF_DELIVERY_ZONE':
            _t('Вне зоны доставки', 'Eltip berme zolagyndan daşda'),
        'OUT_OF_STOCK': _t('Нет продуктов', 'Önüm ýok'),
        'PRODUCT_UNAVAILABLE': _t('Блюдо недоступно', 'Tagam elýeterli däl'),
        'KITCHEN_BUSY': _t('Кухня перегружена', 'Aşhana ýüklenen'),
        'KITCHEN_CLOSED': _t('Кухня закрыта', 'Aşhana ýapyk'),
        'NO_COURIER': _t('Нет курьера', 'Kurýer ýok'),
        'COURIER_UNAVAILABLE': _t('Курьер недоступен', 'Kurýer elýeterli däl'),
        'LATE': _t('Долгая доставка', 'Eltip berme gijikdi'),
        'DUPLICATE': _t('Дубликат заказа', 'Sargydyň nusgasy'),
        'TEST_ORDER': _t('Тестовый заказ', 'Synag sargydy'),
        'PAYMENT_FAILED': _t('Оплата не прошла', 'Töleg geçmedi'),
        'PRICE_DISAGREEMENT':
            _t('Не согласен с ценой', 'Baha bilen ylalaşmady'),
        'STAFF_MISTAKE': _t('Ошибка сотрудника', 'Işgäriň ýalňyşlygy'),
        'WEATHER': _t('Погода', 'Howa şertleri'),
        'TECHNICAL': _t('Техническая причина', 'Tehniki sebäp'),
        'OTHER': _t('Другая причина', 'Başga sebäp'),
        'UNKNOWN': _t('Причина не указана', 'Sebäbi görkezilmedik'),
      };

  static String cancelReason(String? value) {
    if (value == null || value.trim().isEmpty) return cancelReasons['UNKNOWN']!;
    return cancelReasons[_key(value)] ?? value.trim();
  }
}
