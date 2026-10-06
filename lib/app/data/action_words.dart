import 'strings.dart';

/// Turns the backend's event codes (`address.activated`, `product.created`,
/// `promo_code.deleted`, …) into a sentence in the reader's language.
///
/// The server names an event `<what>.<what happened>`. Writing out one caption
/// per combination cannot keep up with a backend that adds sections, so this
/// translates the two halves separately and joins them — and agrees the
/// Russian verb with the noun («Адрес активирован», «Блюдо активировано»,
/// «Настройки активированы»). A half it does not know yields `null`, and the
/// caller falls back to a generic caption: a wrong translation is worse than
/// an honest «Изменение записи».
class ActionWords {
  const ActionWords._();

  /// `address.activated` → «Адрес активирован». Null when the entity or the
  /// verb is not in the dictionaries.
  static String? describe(String? code) {
    if (code == null) return null;
    final parts = code.toLowerCase().split('.').where((p) => p.isNotEmpty);
    if (parts.length < 2) return null;
    final list = parts.toList();
    final noun = _entities[_norm(list.sublist(0, list.length - 1).join('_'))] ??
        _entities[_norm(list.first)];
    if (noun == null) return null;
    final verb = _verbs[_norm(list.last)];
    if (verb != null) {
      return verb.invariant
          ? '${noun.name}: ${verb.text(noun.gender)}'
          : '${noun.name} ${verb.text(noun.gender)}';
    }
    return null;
  }

  /// The noun alone, for an entity type like `ADDRESS` or `PROMO_CODE`.
  static String? entity(String? type) {
    if (type == null) return null;
    return _entities[_norm(type)]?.name;
  }

  /// Entity keys with their names, for a filter list.
  static Map<String, String> get entityNames => {
        for (final entry in _entities.entries)
          if (entry.value.listed) entry.key.toUpperCase(): entry.value.name,
      };

  static bool isNegative(String? code) => _verbKey(code).let(_negative.contains);
  static bool isPositive(String? code) => _verbKey(code).let(_positive.contains);
  static bool isEdit(String? code) => _verbKey(code).let(_edits.contains);

  static String? entityKey(String? code) {
    if (code == null) return null;
    final list = code.toLowerCase().split('.').where((p) => p.isNotEmpty).toList();
    if (list.length < 2) return null;
    final joined = _norm(list.sublist(0, list.length - 1).join('_'));
    if (_entities.containsKey(joined)) return joined;
    final first = _norm(list.first);
    return _entities.containsKey(first) ? first : null;
  }

  static String? _verbKey(String? code) {
    if (code == null) return null;
    final list = code.toLowerCase().split('.').where((p) => p.isNotEmpty);
    if (list.length < 2) return null;
    return _norm(list.last);
  }

  static String _norm(String value) =>
      value.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  static const _negative = {
    'deleted', 'removed', 'cancelled', 'canceled', 'rejected', 'blocked',
    'deactivated', 'disabled', 'archived', 'refunded',
  };
  static const _positive = {
    'created', 'added', 'activated', 'enabled', 'confirmed', 'approved',
    'accepted', 'assigned', 'restored', 'published', 'completed', 'paid',
  };
  static const _edits = {
    'updated', 'edited', 'changed', 'status_changed', 'price_changed',
    'reordered', 'sort_changed',
  };

  static const Map<String, _Noun> _entities = {
    'address': _Noun(_m, 'Адрес', 'Salgy'),
    'customer_address': _Noun(_m, 'Адрес клиента', 'Müşderiniň salgysy'),
    'product': _Noun(_n, 'Блюдо', 'Tagam'),
    'dish': _Noun(_n, 'Блюдо', 'Tagam', listed: false),
    'variant': _Noun(_m, 'Вариант блюда', 'Tagamyň görnüşi'),
    'category': _Noun(_f, 'Категория', 'Kategoriýa'),
    'branch': _Noun(_m, 'Филиал', 'Şahamça'),
    'kitchen': _Noun(_f, 'Кухня', 'Aşhana'),
    'promo_code': _Noun(_m, 'Промокод', 'Promokod'),
    'promocode': _Noun(_m, 'Промокод', 'Promokod', listed: false),
    'promo': _Noun(_m, 'Промокод', 'Promokod', listed: false),
    'banner': _Noun(_m, 'Баннер', 'Banner'),
    'contact': _Noun(_m, 'Контакт', 'Habarlaşmak'),
    'contacts': _Noun(_m, 'Контакт', 'Habarlaşmak', listed: false),
    'user': _Noun(_m, 'Сотрудник', 'Işgär'),
    'users': _Noun(_m, 'Сотрудник', 'Işgär', listed: false),
    'staff': _Noun(_m, 'Сотрудник', 'Işgär', listed: false),
    'employee': _Noun(_m, 'Сотрудник', 'Işgär', listed: false),
    'customer': _Noun(_m, 'Клиент', 'Müşderi'),
    'client': _Noun(_m, 'Клиент', 'Müşderi', listed: false),
    'courier': _Noun(_m, 'Курьер', 'Kurýer'),
    'cook': _Noun(_m, 'Повар', 'Aşpez'),
    'schedule': _Noun(_n, 'Расписание', 'Tertip'),
    'settings': _Noun(_pl, 'Настройки', 'Sazlamalar'),
    'setting': _Noun(_pl, 'Настройки', 'Sazlamalar', listed: false),
    'stock': _Noun(_m, 'Склад', 'Ammar'),
    'tariff': _Noun(_m, 'Тариф', 'Nyrh'),
    'delivery_tariff': _Noun(_m, 'Тариф доставки', 'Eltip bermegiň nyrhy'),
    'district': _Noun(_m, 'Район', 'Etrap'),
    'etrap': _Noun(_m, 'Район', 'Etrap', listed: false),
    'delivery_zone': _Noun(_f, 'Зона доставки', 'Eltip bermek zolagy'),
    'order': _Noun(_m, 'Заказ', 'Sargyt'),
    'cash_handoff': _Noun(_m, 'Денежный пакет', 'Pul bukjasy'),
    'review': _Noun(_m, 'Отзыв', 'Syn'),
    'rating': _Noun(_f, 'Оценка', 'Baha'),
    'notification': _Noun(_n, 'Уведомление', 'Habarnama'),
    'gift': _Noun(_m, 'Подарок', 'Sowgat'),
    'loyalty': _Noun(_pl, 'Баллы', 'Utuşlar'),
    'payment': _Noun(_f, 'Оплата', 'Töleg'),
    'menu': _Noun(_n, 'Меню', 'Menýu'),
    'ingredient': _Noun(_m, 'Ингредиент', 'Düzüm bölegi'),
    'image': _Noun(_n, 'Фото', 'Surat'),
    'page': _Noun(_f, 'Страница', 'Sahypa'),
    'role': _Noun(_f, 'Роль', 'Wezipe'),
    'access': _Noun(_m, 'Доступ', 'Elýeterlilik'),
    'session': _Noun(_f, 'Сессия', 'Sessiýa'),
  };

  static const Map<String, _Verb> _verbs = {
    'created': _Verb('создан', 'döredildi'),
    'create': _Verb('создан', 'döredildi'),
    'added': _Verb('добавлен', 'goşuldy'),
    'updated': _Verb('обновлён', 'täzelendi'),
    'update': _Verb('обновлён', 'täzelendi'),
    'edited': _Verb('отредактирован', 'üýtgedildi'),
    'changed': _Verb('изменён', 'üýtgedildi'),
    'deleted': _Verb('удалён', 'pozuldy'),
    'delete': _Verb('удалён', 'pozuldy'),
    'removed': _Verb('удалён', 'pozuldy'),
    'activated': _Verb('активирован', 'işjeňleşdirildi'),
    'activate': _Verb('активирован', 'işjeňleşdirildi'),
    'enabled': _Verb('включён', 'açyldy'),
    'deactivated': _Verb('деактивирован', 'işjeňsizleşdirildi'),
    'deactivate': _Verb('деактивирован', 'işjeňsizleşdirildi'),
    'disabled': _Verb('отключён', 'öçürildi'),
    'blocked': _Verb('заблокирован', 'bloklandy'),
    'unblocked': _Verb('разблокирован', 'blokdan çykaryldy'),
    'approved': _Verb('одобрен', 'makullandy'),
    'accepted': _Verb('принят', 'kabul edildi'),
    'rejected': _Verb('отклонён', 'ret edildi'),
    'cancelled': _Verb('отменён', 'ýatyryldy'),
    'canceled': _Verb('отменён', 'ýatyryldy'),
    'confirmed': _Verb('подтверждён', 'tassyklandy'),
    'submitted': _Verb('передан', 'tabşyryldy'),
    'assigned': _Verb('назначен', 'bellenildi'),
    'reassigned': _Verb('переназначен', 'täzeden bellenildi'),
    'restored': _Verb('восстановлен', 'dikeldildi'),
    'archived': _Verb('архивирован', 'arhiwlendi'),
    'published': _Verb('опубликован', 'çap edildi'),
    'completed': _Verb('завершён', 'tamamlandy'),
    'paid': _Verb('оплачен', 'tölendi'),
    'refunded': _Verb('возвращён', 'yzyna gaýtaryldy'),
    'sent': _Verb('отправлен', 'iberildi'),
    'uploaded': _Verb('загружен', 'ýüklendi'),
    'verified': _Verb('проверен', 'barlandy'),
    'requested': _Verb('запрошен', 'soraldy'),
    'opened': _Verb('открыт', 'açyldy'),
    'closed': _Verb('закрыт', 'ýapyldy'),
    'status_changed':
        _Verb.phrase('статус изменён', 'ýagdaýy üýtgedildi'),
    'price_changed': _Verb.phrase('цена изменена', 'bahasy üýtgedildi'),
    'reordered': _Verb.phrase('порядок изменён', 'tertibi üýtgedildi'),
    'sort_changed': _Verb.phrase('порядок изменён', 'tertibi üýtgedildi'),
    'password_changed':
        _Verb.phrase('пароль изменён', 'parol üýtgedildi'),
    'role_changed': _Verb.phrase('роль изменена', 'wezipesi üýtgedildi'),
    'set_default':
        _Verb.phrase('выбран основным', 'esasy edip saýlandy'),
  };
}

const int _m = 0;
const int _f = 1;
const int _n = 2;
const int _pl = 3;

class _Noun {
  const _Noun(this.gender, this.ru, this.tm, {this.listed = true});

  final int gender;
  final String ru;
  final String tm;
  final bool listed;

  String get name => S.pick(ru, tm);
}

class _Verb {
  const _Verb(this.ru, this.tm) : invariant = false;
  const _Verb.phrase(this.ru, this.tm) : invariant = true;

  /// A phrase that carries its own agreement («цена изменена») and is
  /// written after a colon instead of agreeing with the noun.
  final bool invariant;
  final String ru;
  final String tm;

  String text(int gender) {
    if (S.pick('ru', 'tm') == 'tm') return tm;
    if (invariant || gender == _m) return ru;
    // «-ён» takes «е» in every other form: отклонён → отклонена.
    final stem = ru.endsWith('ён') ? '${ru.substring(0, ru.length - 2)}ен' : ru;
    final ending = switch (gender) {
      _f => 'а',
      _n => 'о',
      _ => 'ы',
    };
    return '$stem$ending';

  }
}

extension _Let<T> on T {
  R let<R>(R Function(T value) block) => block(this);
}
