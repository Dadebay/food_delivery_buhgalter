import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/constants.dart';
import 'formatting.dart';

/// The wording dictionary, mirroring the web client's
/// `widgets/accounting-dashboard/model/inspection.ts`.
///
/// It is a dictionary of captions, not a second status machine: nothing here
/// decides what happened, it only names what the server already said. An
/// action this build does not know is never hidden — [auditActionLabel] falls
/// back to «Изменение записи» and the screen shows the raw payload with it.
class Labels {
  const Labels._();

  static const Map<String, String> auditActions = {
    'order.created': 'Заказ создан в приложении',
    'order.created_by_staff': 'Заказ оформлен по телефону',
    'order.admin-edited': 'Заказ отредактирован',
    'order.cancelled': 'Заказ отменён',
    'order.packing-confirmed': 'Сборка подтверждена',
    'order.courier-assigned': 'Курьер назначен',
    'order.courier-reassigned': 'Курьер заменён',
    'order.transitioned': 'Статус заказа изменён',
    'order.request.rejected': 'Действие с заказом отклонено',
    'cash_handoff.submitted': 'Деньги смены переданы',
    'cash_handoff.confirmed': 'Деньги смены подтверждены',
    'order.historical-cash-reconciled': 'Отмечена ранее сданная оплата',
    'order.historical-completion-requested':
        'Историческое завершение по поручению владельца',
  };

  static String auditAction(String? action) =>
      auditActions[action] ?? 'Изменение записи';

  static bool isKnownAction(String? action) =>
      action != null && auditActions.containsKey(action);

  static const Map<String, String> entities = {
    'ORDER': 'Заказ',
    'CASH_HANDOFF': 'Денежный пакет',
    'PRODUCT': 'Блюдо',
    'CATEGORY': 'Категория',
    'BRANCH': 'Филиал',
    'PROMO_CODE': 'Промокод',
    'BANNER': 'Баннер',
    'CONTACT': 'Контакт',
    'USER': 'Сотрудник',
    'STAFF': 'Сотрудник',
    'SCHEDULE': 'Расписание',
    'SETTINGS': 'Настройки',
    'STOCK': 'Склад',
    'TARIFF': 'Тариф',
  };

  static String entity(String? type) =>
      entities[(type ?? '').toUpperCase()] ?? (type ?? kDash);

  /// Field names inside a before/after comparison. Unknown keys keep their
  /// raw name so nothing is silently dropped.
  static const Map<String, String> fields = {
    'status': 'Статус',
    'total': 'Итого',
    'subtotal': 'Сумма позиций',
    'discount': 'Скидка',
    'foodAmount': 'Сумма еды',
    'deliveryFee': 'Доставка',
    'address': 'Адрес',
    'entrance': 'Подъезд',
    'floor': 'Этаж',
    'apartment': 'Квартира',
    'items': 'Состав',
    'courierId': 'Курьер',
    'cookId': 'Повар',
    'cancelReason': 'Причина отмены',
    'cancellationReason': 'Причина отмены',
    'note': 'Комментарий',
    'customerName': 'Клиент',
    'customerPhone': 'Телефон',
    'customerNote': 'Пожелание клиента',
    'branchName': 'Кухня',
    'branchId': 'Кухня',
    'deliveryEtrapName': 'Район',
    'preparationMinutes': 'Время приготовления',
    'name': 'Название',
    'price': 'Цена',
    'isActive': 'Активно',
    'declaredAmount': 'Заявленная сумма',
    'expectedAmount': 'Ожидаемая сумма',
  };

  static String field(String key) => fields[key] ?? key;

  static const Map<String, String> orderStatuses = {
    'NEW': 'Новый',
    'PENDING': 'Ожидает',
    'ACCEPTED': 'Принят',
    'COOKING': 'Готовится',
    'READY': 'Готов',
    'ASSIGNED_TO_COURIER': 'Назначен курьеру',
    'OUT_FOR_DELIVERY': 'В доставке',
    'DELIVERED': 'Доставлен',
    'CASH_RETURNED': 'Деньги возвращены',
    'RECONCILED': 'Сверен',
    'CANCELLED': 'Отменён',
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

  static const Map<String, String> handoffStatuses = {
    'SUBMITTED': 'Передан, ждёт подтверждения',
    'CONFIRMED': 'Подтверждён',
    'PENDING': 'Не передан',
    'REJECTED': 'Отклонён',
  };

  static String handoffStatus(String? status) =>
      handoffStatuses[(status ?? '').toUpperCase()] ??
      (status ?? 'Пакет не создан');

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
      return 'Статус → ${orderStatus(action.substring('transition:'.length))}';
    }
    return auditActions[action] ?? action;
  }

  /// `first`/`second` when the settings have not been read yet. The real
  /// names and times come from `GET /accounting/settings`; 09:30/19:00 is
  /// never baked into the app.
  static String shiftSlot(String slot) => switch (slot) {
        'first' => 'Первая смена',
        'second' => 'Вторая смена',
        _ => 'Смена',
      };

  /// The source an order came from.
  static String orderSource(String? source) => switch ((source ?? '').toUpperCase()) {
        'APP' || 'MOBILE' => 'Приложение',
        'STAFF' || 'CALL' || 'PHONE' => 'По телефону',
        'WEB' => 'Сайт',
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
        _ => AppIcons.details,
      };
}
