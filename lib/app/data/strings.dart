import 'app_state.dart';

/// Russian and Turkmen side by side.
///
/// Every caption is one line with both wordings, so a translation can never
/// drift away from the text it belongs to, and nothing can be added in one
/// language and forgotten in the other. Server wording (error messages,
/// statuses it does not know) is never translated here: it is shown as the
/// server said it.
String _t(String ru, String tm) => App.instance.language.isTurkmen ? tm : ru;

class S {
  const S._();

  /// For dictionaries that live next to their data (statuses, audit actions)
  /// and still need the same two-column wording.
  static String pick(String ru, String tm) => _t(ru, tm);

  // ── Common ────────────────────────────────────────────────────────────
  static String get appName => _t('Бухгалтерия', 'Buhgalteriýa');
  static String get unknown => _t('неизвестно', 'näbelli');
  static String get minutesShort => _t('мин', 'min');
  static String get hoursShort => _t('ч', 'sag');
  static String get retry => _t('Повторить', 'Gaýtalamak');
  static String get cancel => _t('Отмена', 'Ýatyr');
  static String get confirm => _t('Подтвердить', 'Tassykla');
  static String get create => _t('Создать', 'Döret');
  static String get back => _t('Назад', 'Yza');
  static String get loadMore => _t('Загрузить ещё', 'Ýene ýükle');
  static String get noRecords => _t('Записей нет', 'Ýazgy ýok');
  static String get nothingForPeriod => _t(
        'За выбранный период сервер ничего не вернул.',
        'Saýlanan döwür üçin serwer hiç zat bermedi.',
      );
  static String shown(String on, String total) =>
      _t('Показано $on из $total', '$total-den $on görkezildi');
  static String totalRecords(String total) =>
      _t('Всего записей: $total', 'Jemi ýazgy: $total');

  // ── Errors ────────────────────────────────────────────────────────────
  static String get errNoAccess => _t('Нет доступа', 'Rugsat ýok');
  static String get errLoad =>
      _t('Не удалось загрузить', 'Ýüklemek başartmady');
  static String get errBadRequest => _t('Неверный запрос', 'Nädogry sorag');
  static String get errSession => _t('Сессия истекла', 'Sessiýa gutardy');
  static String get errNotFound => _t('Запись не найдена', 'Ýazgy tapylmady');
  static String get errConflict =>
      _t('Данные изменились', 'Maglumat üýtgedi');
  static String get errNetwork => _t('Нет соединения', 'Baglanyşyk ýok');
  static String get errServer =>
      _t('Ошибка сервера', 'Serwer ýalňyşlygy');

  static String get msgWrongRole => _t(
        'Журнал открыт бухгалтеру и владельцу. Выданная страница сама по себе '
            'доступ не открывает.',
        'Žurnal buhgaltere we eýesine açyk. Berlen sahypanyň özi rugsat '
            'açmaýar.',
      );
  static String get msgTryAgain =>
      _t('Попробуйте ещё раз.', 'Ýene bir gezek synanyşyň.');
  static String get msgBadRequest => _t(
        'Сервер не принял параметры запроса.',
        'Serwer soragyň parametrlerini kabul etmedi.',
      );
  static String get msgSession => _t(
        'Войдите заново, чтобы продолжить.',
        'Dowam etmek üçin täzeden giriň.',
      );
  static String get msgForbidden => _t(
        'У этой учётной записи нет права на раздел бухгалтерии.',
        'Bu hasabyň buhgalteriýa bölümine hukugy ýok.',
      );
  static String get msgNotFound => _t(
        'Заказ или запись отсутствует.',
        'Sargyt ýa-da ýazgy ýok.',
      );
  static String get msgConflict => _t(
        'Данные успели измениться. Обновите и посмотрите ответ сервера.',
        'Maglumat üýtgedi. Täzeläň we serweriň jogabyna serediň.',
      );
  static String get msgNetwork => _t(
        'Проверьте связь и повторите запрос.',
        'Baglanyşygy barlaň we soragy gaýtalaň.',
      );
  static String get msgServer => _t(
        'Сервер не смог ответить. Повторите позже.',
        'Serwer jogap berip bilmedi. Soňra gaýtalaň.',
      );

  // ── Login ─────────────────────────────────────────────────────────────
  static String get loginSubtitle => _t(
        'Просмотр дней, денег и журнала действий.',
        'Günlere, pula we hereketler žurnalyna syn.',
      );
  static String get loginAccessNote => _t(
        'Раздел открыт бухгалтеру и владельцу.',
        'Bölüm buhgaltere we eýesine açyk.',
      );
  static String get phoneLabel => _t('Номер телефона', 'Telefon belgisi');
  static String get codeLabel => _t('Код из сообщения', 'Habardaky kod');
  static String get signIn => _t('Войти', 'Gir');
  static String get getCode => _t('Получить код', 'Kod al');
  static String get changeNumber => _t('Изменить номер', 'Belgini üýtget');
  static String get resendCode =>
      _t('Отправить код заново', 'Kody täzeden iber');
  static String get enterPhone =>
      _t('Введите номер телефона.', 'Telefon belgiňizi ýazyň.');
  static String get enterCode =>
      _t('Введите код из сообщения.', 'Habardaky kody ýazyň.');
  static String codeSentTo(String phone) =>
      _t('Код отправлен на $phone', 'Kod $phone belgä iberildi');
  static String get stepPhone => _t('Шаг 1 из 2', '2-den 1-nji ädim');
  static String get stepCode => _t('Шаг 2 из 2', '2-den 2-nji ädim');

  // ── Home ──────────────────────────────────────────────────────────────
  static String get overview => _t('Обзор', 'Syn');
  static String get overviewSubtitle => _t(
        'Время Ашхабада, UTC+5.',
        'Aşgabat wagty, UTC+5.',
      );
  static String get today => _t('Сегодня', 'Şu gün');
  static String yearTotal(int year) =>
      _t('Заработано за $year год', '$year ýylda gazanylan');
  static String get monthEarnedHint => _t(
        'Деньги за еду по дню возврата, без доставки.',
        'Iýmit puly gaýdan güni boýunça, eltip bermesiz.',
      );
  static String get monthEarned => _t('Заработано за месяц', 'Aýda gazanylan');
  static String get todayToCollect =>
      _t('Сегодня нужно сдать', 'Şu gün tabşyrmaly');
  static String get todayCollected => _t('Уже получено', 'Eýýäm alyndy');
  static String get todayRemaining => _t('Осталось', 'Galan');
  static String get todayNoShifts =>
      _t('За сегодня данных нет', 'Şu gün üçin maglumat ýok');
  static String get overdueTitle =>
      _t('Остаток за прошлые дни', 'Öňki günlerden galan');
  static String packetsCount(int count) =>
      _t('Пакетов: $count', 'Bukja: $count');
  static String daysCount(int count) => _t('Дней: $count', 'Gün: $count');
  static String get account => _t('Учётная запись', 'Hasap');
  static String get staff => _t('Сотрудник', 'Işgär');
  static String get role => _t('Роль', 'Wezipe');
  static String get roleAccountant => _t('Бухгалтер', 'Buhgalter');
  static String get roleOwner => _t('Владелец', 'Eýesi');
  static String get rights => _t('Права', 'Hukuklar');
  static String get rightsValue => _t(
        'Просмотр и подтверждение денежного пакета',
        'Syn etmek we pul bukjasyny tassyklamak',
      );
  static String get signOut => _t('Выйти', 'Çykmak');
  static String get signOutQuestion =>
      _t('Выйти из приложения?', 'Programmadan çykylsynmy?');
  static String get language => _t('Язык', 'Dil');
  static String get selectMonth => _t('Выбрать месяц', 'Aý saýla');
  static String get previousMonth => _t('Предыдущий месяц', 'Öňki aý');
  static String get nextMonth => _t('Следующий месяц', 'Indiki aý');

  // ── Sections ──────────────────────────────────────────────────────────
  static String get orders => _t('Заказы', 'Sargytlar');
  static String get ordersSub => _t(
        'По созданию и по возврату денег',
        'Döredilişi we pul gaýdyşy boýunça',
      );
  static String get shiftsMoney => _t('Касса за день', 'Günüň kassasy');
  static String get shiftsMoneySub => _t(
        'Суммы за день, сдача денег и подтверждение',
        'Günüň möçberleri, pul tabşyrmak we tassyklamak',
      );
  static String get charts => _t('Графики', 'Grafikler');
  static String get chartsSub => _t(
        'Заказы, деньги, районы и блюда',
        'Sargytlar, pul, etraplar we tagamlar',
      );
  static String get journal => _t('Кто что сделал', 'Kim näme etdi');
  static String get journalSub =>
      _t('История и контроль действий', 'Taryh we hereketlere gözegçilik');
  static String get carryIn =>
      _t('Принято с прошлого дня', 'Öňki günden kabul edilen');
  static String get carryInSub => _t(
        'Незавершённые заказы на входе',
        'Girişdäki tamamlanmadyk sargytlar',
      );
  static String get carryOut => _t('Передано на следующий день', 'Indiki güne geçirilen');
  static String get carryOutSub => _t(
        'Незавершённые заказы на выходе',
        'Çykyşdaky tamamlanmadyk sargytlar',
      );

  // ── Orders ────────────────────────────────────────────────────────────
  static String get basisCreated => _t('По созданию', 'Döredilişi boýunça');
  static String get basisCash =>
      _t('По возврату денег', 'Pul gaýdyşy boýunça');
  static String get noOrders => _t('Заказов нет', 'Sargyt ýok');
  static String get noOrdersCreated => _t(
        'В выбранном периоде заказы не создавались.',
        'Saýlanan döwürde sargyt döredilmedi.',
      );
  static String get noOrdersCash => _t(
        'В выбранном периоде деньги не возвращали.',
        'Saýlanan döwürde pul gaýtarylmady.',
      );
  static String get orderNumberHint => _t('Номер заказа', 'Sargyt belgisi');
  static String get numberSearchNote => _t(
        'Поиск по номеру ограничен выбранным периодом.',
        'Belgi boýunça gözleg saýlanan döwür bilen çäklidir.',
      );
  static String get status => _t('Статус', 'Ýagdaý');
  static String get allStatuses => _t('Все статусы', 'Ähli ýagdaýlar');
  static String get allStatusesShort => _t('Все', 'Hemmesi');
  static String get created => _t('Создан', 'Döredildi');
  static String get cashReturned => _t('Деньги получены', 'Puly alnan');
  static String get dateUnknown => _t('дата неизвестна', 'senesi näbelli');
  static String get customer => _t('Клиент', 'Müşderi');
  static String get kitchen => _t('Кухня', 'Aşhana');
  static String get district => _t('Район', 'Etrap');
  static String get food => _t('Еда', 'Nahar');
  static String get delivery => _t('Доставка', 'Eltip berme');
  static String get total => _t('Итого', 'Jemi');
  static String get foodAmount => _t('Сумма еды', 'Nahar möçberi');
  static String orderNo(int number) => _t('Заказ №$number', '№$number sargyt');
  static String get order => _t('Заказ', 'Sargyt');

  // ── Order details ─────────────────────────────────────────────────────
  static String get orderTabOrder => _t('Заказ', 'Sargyt');
  static String get orderTabHistory => _t('История', 'Taryh');
  static String get orderDetailsSub => _t(
        'Состав, участники и история',
        'Düzümi, gatnaşyjylar we taryhy',
      );
  static String get source => _t('Источник', 'Çeşme');
  static String get name => _t('Имя', 'Ady');
  static String get phone => _t('Телефон', 'Telefon');
  static String get customerWish => _t('Пожелание', 'Islegi');
  static String get address => _t('Адрес', 'Salgy');
  static String get entrance => _t('Подъезд', 'Girelge');
  static String get floor => _t('Этаж', 'Gat');
  static String get apartment => _t('Квартира', 'Kwartira');
  static String composition(int count) =>
      _t('Состав ($count)', 'Düzümi ($count)');
  static String get noItems =>
      _t('Позиции не сохранены.', 'Harytlar saklanmandyr.');
  static String get gifts => _t('Подарки', 'Sowgatlar');
  static String points(String value) => _t('$value баллов', '$value bal');
  static String get amounts => _t('Суммы', 'Möçberler');
  static String get subtotal => _t('Сумма позиций', 'Harytlaryň möçberi');
  static String get discount => _t('Скидка', 'Arzanladyş');
  static String get loyalty => _t('Баллы', 'Ballar');
  static String loyaltyValue(String earned, String spent) => _t(
        'начислено $earned · списано $spent',
        'goşuldy $earned · ýazyldy $spent',
      );
  static String get rating => _t('Оценка', 'Baha');
  static String get participants => _t('Кто участвовал', 'Kim gatnaşdy');
  static String get courier => _t('Курьер', 'Kurýer');
  static String get cook => _t('Повар', 'Aşpez');
  static String get courierUnknownShort =>
      _t('неизвестен', 'näbelli');
  static String get courierUnknownNote => _t(
        'Фактический курьер неизвестен: назначение сделано технически при '
            'историческом закрытии заказа.',
        'Hakyky kurýer näbelli: bellenilme sargydyň taryhy ýapylyşynda '
            'tehniki taýdan edilen.',
      );
  static String get participantsNote => _t(
        'Должность сотрудника сама по себе не доказывает, что он готовил или '
            'доставлял этот заказ.',
        'Işgäriň wezipesi onuň bu sargydy taýýarlandygyny ýa-da '
            'eltendigini subut etmeýär.',
      );
  static String get stages => _t('Этапы', 'Tapgyrlar');
  static String get assignedAt =>
      _t('Назначен курьеру', 'Kurýere berildi');
  static String get packedAt =>
      _t('Сборка подтверждена', 'Ýygnalmagy tassyklandy');
  static String get deliveredAt => _t('Доставлен', 'Eltildi');
  static String get completedAt => _t('Завершён', 'Tamamlandy');
  static String get money => _t('Деньги', 'Pul');
  static String get noSettlement => _t(
        'Денежной записи по этому заказу нет.',
        'Bu sargyt boýunça pul ýazgysy ýok.',
      );
  static String get amount => _t('Сумма', 'Möçber');
  static String get state => _t('Состояние', 'Ýagdaýy');
  static String get reconciledAt => _t('Сверено', 'Deňeşdirildi');
  static String get operator => _t('Оператор', 'Operator');
  static String get accountant => _t('Бухгалтер', 'Buhgalter');
  static String get cashPacket => _t('Денежный пакет', 'Pul bukjasy');
  static String get handoverUnknownNote => _t(
        'Сверено; дата сдачи неизвестна. Такая запись не попадает ни в '
            'сегодняшний день, ни в денежный график по времени сверки.',
        'Deňeşdirildi; tabşyrylan senesi näbelli. Beýle ýazgy ne şu günki '
            'güne, ne-de pul grafigine düşýär.',
      );
  static String get historyNote => _t(
        'История заказа показывается целиком и не зависит от выбранного '
            'периода.',
        'Sargydyň taryhy doly görkezilýär we saýlanan döwre bagly däl.',
      );
  static String get historyEmpty => _t('История пуста', 'Taryh boş');
  static String get historyEmptyMessage => _t(
        'По этому заказу сохранённых действий нет.',
        'Bu sargyt boýunça saklanan hereket ýok.',
      );
  static String prepares(String value) =>
      _t('Готовится $value', 'Taýýarlanyşy $value');
  static String perPiece(String price) =>
      _t('$price за штуку', 'birligi $price');

  // ── Shifts ────────────────────────────────────────────────────────────
  static String get day => _t('День', 'Gün');
  static String get waitForHandoff => _t(
        'Администратор ещё не сдал эти деньги. Кнопка «Я принял деньги» '
            'появится, когда он их сдаст.',
        'Administrator bu puly entek tabşyrmady. Ol tabşyranda «Tölegi aldym» '
            'düwmesi peýda bolar.',
      );
  static String get receiveDayTitle =>
      _t('Принять деньги за день', 'Gün üçin puly kabul et');
  static String get receiveDayNote => _t(
        'Деньги будут сданы и сразу приняты одним действием.',
        'Pul tabşyrylar we derrew kabul ediler.',
      );
  static String get allDays => _t('Все дни', 'Ähli günler');
  static String get nothingOutstanding => _t(
        'Всё передано и принято.',
        'Hemmesi tabşyryldy we kabul edildi.',
      );
  static String get thisWeek => _t('Эта неделя', 'Şu hepde');
  static String get lastDays => _t('Последние дни', 'Soňky günler');
  static String get difference => _t('Разница', 'Tapawut');
  static String get moneyOfDay => _t('Деньги за день', 'Gün puly');
  static String get handedBy => _t('Сдал', 'Tabşyran');
  static String get acceptedBy => _t('Принял', 'Kabul eden');
  static String get wholeDay => _t('За день', 'Gün boýunça');
  static String get noShifts =>
      _t('За выбранный месяц данных нет.', 'Saýlanan aýda maglumat ýok.');
  static String get ordersCount => _t('Заказов', 'Sargyt');
  static String get collectedInShift => _t('Всего за день', 'Gün boýunça jemi');
  static String get expected => _t('К сдаче', 'Tabşyrmaly');
  static String get declared => _t('Заявлено', 'Yglan edilen');
  static String get discrepancy => _t('Расхождение', 'Tapawut');
  static String get submittedBy => _t('Передал', 'Tabşyran');
  static String get confirmedBy => _t('Подтвердил', 'Tassyklan');
  static String get submittedAt => _t('Передан', 'Tabşyrylan');
  static String get confirmedAt => _t('Подтверждён', 'Tassyklanan');
  static String get comment => _t('Комментарий', 'Bellik');
  static String get onConfirmation =>
      _t('При подтверждении', 'Tassyklananda');
  static String get recordsInPacket => _t('Записей в пакете', 'Bukjadaky ýazgy');
  static String get confirmAmount =>
      _t('Я принял деньги', 'Tölegi aldym');
  static String get createPacket => _t('Сдать деньги за день', 'Gün üçin pul tabşyr');
  static String get confirmPacketTitle =>
      _t('Подтвердить получение денег', 'Pulyň alnandygyny tassykla');
  static String get confirmReceipt =>
      _t('Подтвердить получение', 'Alnandygyny tassykla');
  static String get periodLabel => _t('Период', 'Döwür');
  static String get packetAuthorNote =>
      _t('Комментарий при сдаче', 'Tabşyranyň bellik');
  static String get accountantNote =>
      _t('Комментарий бухгалтера', 'Buhgalteriň bellik');
  static String get shortfall => _t('Недостача', 'Kemçilik');
  static String get surplus => _t('Излишек', 'Artykmaçlyk');
  static String get availableToHandOver =>
      _t('Не передано', 'Tabşyrylmadyk');
  static String get recordsOfDay => _t('Записей', 'Ýazgy');
  static String get previouslyHandedOver =>
      _t('Ранее передано', 'Öň tabşyrylan');
  static String get dayPacket => _t('Пакет дня', 'Güniň bukjasy');
  static String get awaitingConfirmation =>
      _t('Ожидают подтверждения', 'Tassyklanmaga garaşýar');
  static String get notHandedOver => _t('Не передано', 'Tabşyrylmadyk');
  static String get dayStillOpen => _t(
        'День ещё идёт: сдать деньги можно после полуночи по Ашхабаду.',
        'Gün entek dowam edýär: pul Aşgabat ýarym gijesinden soň tabşyrylýar.',
      );
  static String get declaredAmountError => _t(
        'Сумма — число от 0 до 99 999 999, не больше двух знаков после запятой.',
        'Möçber — 0-dan 99 999 999-a çenli san, nokatdan soň iň köp iki belgi.',
      );
  static String get createPacketNote => _t(
        'Сервер сам включит все подходящие денежные записи дня. Если сумму не '
            'указать, будет взята ожидаемая.',
        'Serweriň özi güniň ähli degişli pul ýazgylaryny goşar. Möçber '
            'görkezilmese, garaşylýan alnar.',
      );
  static String get createPacketTitle =>
      _t('Сдать деньги бухгалтеру', 'Pulu buhgaltere tabşyr');
  static String get expectedAmount => _t('Ожидаемая сумма', 'Garaşylýan möçber');
  static String get records => _t('Записей', 'Ýazgy');
  static String get noteOptional =>
      _t('Комментарий (необязательно)', 'Bellik (hökman däl)');
  static String get declaredOptional => _t(
        'Заявленная сумма (необязательно)',
        'Yglan edilen möçber (hökman däl)',
      );
  static String get packetConfirmed =>
      _t('Пакет подтверждён', 'Bukja tassyklandy');
  static String get packetCreated => _t('Пакет создан', 'Bukja döredildi');
  static String get confirmNote => _t(
        'Разница не мешает подтвердить.',
        'Tapawut tassyklamaga päsgel bermeýär.',
      );
  static String get checkPacketFirst => _t(
        'Сначала проверьте фактическое состояние пакета — операция могла '
            'пройти.',
        'Ilki bukjanyň hakyky ýagdaýyny barlaň — amal geçen bolmagy mümkin.',
      );
  static String get packetNotCreated =>
      _t('Пакет не создан', 'Bukja döredilmedi');
  static String get shiftOrders => _t('Заказы дня', 'Güniň sargytlary');
  static String get openSection => _t('Открыть', 'Aç');
  static String get ordersByCreation =>
      _t('Заказы по созданию', 'Döredilişi boýunça sargytlar');
  static String get ordersByCreationSub => _t(
        'Что заказали в этот день',
        'Şu gün näme sargyt edildi',
      );
  static String get moneyOfShift =>
      _t('Деньги, вернувшиеся за день', 'Gün içinde gaýdan pul');
  static String get moneyOfShiftSub => _t(
        'Заказы по этой сумме',
        'Şu möçber boýunça sargytlar',
      );
  static String get shiftJournal => _t('Журнал дня', 'Güniň žurnaly');
  static String get shiftActions =>
      _t('Действия в течение дня', 'Güniň dowamyndaky hereketler');
  static String get dishDemand => _t('Спрос на блюда', 'Tagamlara isleg');

  // ── Month / charts ────────────────────────────────────────────────────
  static String get chartsSubtitle => _t(
        'Спрос, деньги и причины отмен',
        'Isleg, pul we ýatyrylyş sebäpleri',
      );
  static String get ordersAndCancels =>
      _t('Заказы и отмены', 'Sargytlar we ýatyrylanlar');
  static String get createdOrders => _t('Создано заказов', 'Döredilen sargyt');
  static String get cancelledNow => _t('Отменено сейчас', 'Häzir ýatyrylan');
  static String get cancelledNowHint => _t(
        'состояние заказов, созданных в периоде',
        'döwürde döredilen sargytlaryň ýagdaýy',
      );
  static String get cancelShare => _t('Доля отмен', 'Ýatyrylyş paýy');
  static String get cancelEvents =>
      _t('Действий отмены', 'Ýatyrma hereketleri');
  static String get cancelEventsHint => _t(
        'переходы в отмену в течение периода',
        'döwürde ýatyrylyşa geçişler',
      );
  static String get editEvents => _t('Редактирований', 'Üýtgetmeler');
  static String get editEventsHint => _t(
        'в том числе заказов прошлых дней',
        'öňki günleriň sargytlary hem',
      );
  static String get received => _t('Получено', 'Alnan');
  static String get handedOver => _t('Передано', 'Tabşyrylan');
  static String get confirmedMoney => _t('Подтверждено', 'Tassyklanan');
  static String get outstanding => _t('Ещё не передано', 'Tabşyrylmadyk');
  static String get declaredByPackets =>
      _t('Заявлено пакетами', 'Bukjalar boýunça yglan');
  static String get declaredByPacketsHint => _t(
        'пакеты, период которых начался в этих датах',
        'döwri şu senelerde başlan bukjalar',
      );
  static String get discrepancyHint =>
      _t('заявлено минус ожидаемое', 'yglan minus garaşylýan');
  static String get discrepancyNote => _t(
        'Расхождение — это не комиссия за систему и не доказательство '
            'фактического пересчёта купюр.',
        'Tapawut ulgamyň komissiýasy däl we puluň hakykatdan sanalandygynyň '
            'subutnamasy däl.',
      );
  static String get checkName => _t('Чеки', 'Çek');
  static String get bestDay => _t('Лучший день', 'Iň gowy gün');
  static String get peakDay => _t('Пик', 'Iň ýokary');
  static String get otherLabel => _t('Другие', 'Beýlekiler');
  static String get shareOfTotal => _t('Доля', 'Paý');
  static String get cancelledBar => _t('Отменено', 'Ýatyrylan');
  static String get districts => _t('Районы', 'Etraplar');
  static String get kitchens => _t('Кухни', 'Aşhanalar');
  static String get cancelReasons =>
      _t('Причины отмен', 'Ýatyrylyş sebäpleri');
  static String get mostOrdered => _t('Часто заказывают', 'Köp sargyt edilýär');
  static String get leastOrdered => _t('Редко заказывают', 'Az sargyt edilýär');
  static String get demandNote => _t(
        'Популярность считается в порциях, а не в деньгах. Блюда, которых '
            'никто не заказывал, в «редкие» не попадают.',
        'Meşhurlyk pulda däl, porsiýada hasaplanýar. Hiç kim sargyt etmedik '
            'tagamlar «az» sanawyna girmeýär.',
      );
  static String get chartOrders => _t('Заказы по дням', 'Günlere görä sargyt');
  static String get chartMoney => _t(
        'Получено денег за еду по дням',
        'Günlere görä nahar üçin alnan pul',
      );
  static String get legendCreated => _t('Создано', 'Döredilen');
  static String get legendCancelled => _t('Отменено', 'Ýatyrylan');
  static String get legendReceived => _t('Получено, TMT', 'Alnan, TMT');
  static String get chartTapHint => _t(
        'Нажмите на день, чтобы открыть его заказы.',
        'Gününiň sargytlaryny açmak üçin güne basyň.',
      );
  static String get chartZeroNote => _t(
        'Дни без поступлений сервер может не присылать — на оси они показаны '
            'нулём.',
        'Girdejisiz günleri serwer ibermän biler — okda olar nol görkezilýär.',
      );

  // ── Journal ───────────────────────────────────────────────────────────
  static String get noActions => _t('Действий нет', 'Hereket ýok');
  static String get noActionsMessage => _t(
        'За выбранный период сохранённых действий нет.',
        'Saýlanan döwürde saklanan hereket ýok.',
      );
  static String get allActions => _t('Все действия', 'Ähli hereketler');
  static String get allSections => _t('Все разделы', 'Ähli bölümler');
  static String get noFilter => _t('Без фильтра', 'Süzgüçsiz');
  static String get journalNote => _t(
        'Журнал фиксирует бизнес-действия, а не нажатия и перемещение по '
            'меню. Он не заменяет физическую сверку денег и остатков.',
        'Žurnal basyşlary däl, iş hereketlerini belleýär. Ol puluň we '
            'galyndylaryň fiziki deňeşdirilmesini çalyşmaýar.',
      );
  static String get authorNotRecorded =>
      _t('Автор не сохранён', 'Awtor saklanmadyk');
  static String showAll(int count) =>
      _t('Показать все ($count)', 'Ählisini görkez ($count)');
  static String get showLess => _t('Свернуть', 'Ýygna');
  static String get filter => _t('Фильтр', 'Süzgüç');
  static String get chooseSection => _t('Раздел', 'Bölüm');
  static String get chooseAction => _t('Действие', 'Hereket');
  static String get whatChanged => _t('Что изменилось', 'Näme üýtgedi');
  static String changedFields(String list) =>
      _t('Изменено: $list', 'Üýtgedi: $list');
  static String eventNamed(String action) =>
      _t('Событие: $action', 'Waka: $action');
  static String get beforeChange => _t('До изменения', 'Üýtgedilmezden öň');
  static String get afterChange => _t('После изменения', 'Üýtgedilenden soň');
  static String get openOrder => _t('Открыть заказ', 'Sargydy aç');
  static String get section => _t('Раздел', 'Bölüm');
  static String get time => _t('Время', 'Wagt');
  static String get recordParticipants =>
      _t('Участники записи', 'Ýazgynyň gatnaşyjylary');
  static String get technicalDetails =>
      _t('Технические детали', 'Tehniki maglumatlar');
  static String get noComparison => _t(
        'Для этого события сохранённого сравнения нет. Старые записи без '
            'снимка восстановить задним числом нельзя.',
        'Bu waka üçin saklanan deňeşdirme ýok. Surata düşürilmedik köne '
            'ýazgylary soňundan dikeldip bolmaýar.',
      );
  static String get empty => _t('пусто', 'boş');
  static String get yes => _t('Да', 'Hawa');
  static String get no => _t('Нет', 'Ýok');
  static String get changedItemAdded => _t('добавлено', 'goşuldy');
  static String itemRemoved(String was) =>
      _t('убрано (было × $was)', 'aýryldy (× $was bardy)');
  static String itemUnchanged(String now) =>
      _t('× $now, без изменений', '× $now, üýtgemedi');

  // ── Carryover ─────────────────────────────────────────────────────────
  static String get noCarryover =>
      _t('Переходящих заказов нет', 'Geçýän sargyt ýok');
  static String get noCarryIn => _t(
        'На входе периода незавершённых заказов не было.',
        'Döwrüň girişinde tamamlanmadyk sargyt ýokdy.',
      );
  static String get noCarryOut => _t(
        'На выходе периода незавершённых заказов не осталось.',
        'Döwrüň çykyşynda tamamlanmadyk sargyt galmady.',
      );
  static String get boundary => _t('Граница', 'Araçäk');
  static String get carriedStates => _t('Переходят', 'Geçýänler');
  static String get carriedStatesValue => _t(
        'Готовится, готов, у курьера, в доставке, доставлен',
        'Taýýarlanýar, taýýar, kurýerde, ýolda, eltilen',
      );
  static String get provisionalNote => _t(
        'Период ещё не завершён: это срез на текущий момент, а не '
            'окончательная передача.',
        'Döwür heniz gutarmady: bu häzirki pursadyň kesimi, gutarnykly '
            'geçirim däl.',
      );
  static String get statusAtBoundary =>
      _t('Статус на границе', 'Araçäkdäki ýagdaý');
  static String get statusNow => _t('Статус сейчас', 'Häzirki ýagdaý');
  static String get noSnapshotNote => _t(
        'Снимок на границе не сохранялся — исторический состав и суммы этого '
            'заказа показать нельзя.',
        'Araçäkdäki surat saklanmandyr — bu sargydyň taryhy düzümini we '
            'möçberini görkezip bolmaýar.',
      );
  static String get atBoundary => _t('На границе дня', 'Güniň araçäginde');
  static String get wasLabel => _t('Было', 'Ozal');
  static String get nowLabel => _t('Сейчас', 'Häzir');
  static String get unchanged => _t('Без изменений', 'Üýtgemedi');
  static String get itemsCount => _t('Позиций', 'Haryt sany');
  static String get currentDiffersNote => _t(
        'Текущие значения заказа могут отличаться — они показаны в карточке '
            'заказа.',
        'Sargydyň häzirki bahalary tapawutlanyp biler — olar sargyt '
            'kartasynda görkezilýär.',
      );

  // ── Receipt / order tabs ──────────────────────────────────────────────
  static String get orderTabReceipt => _t('Чек', 'Çek');
  static String get receiptTitle => _t('Чек заказа', 'Sargyt çeki');
  static String get receiptItems => _t('Позиции', 'Harytlar');
  static String get receiptNote => _t(
        'Это не фискальный чек: суммы показаны так, как их сохранил сервер.',
        'Bu fiskal çek däl: möçberler serweriň saklaýşy ýaly görkezilýär.',
      );
  static String get deliveryStatus =>
      _t('Статус доставки', 'Eltip berme ýagdaýy');
  static String get moneyStatus => _t('Состояние денег', 'Puluň ýagdaýy');
  static String get qty => _t('Кол-во', 'Sany');
  static String get price => _t('Цена', 'Bahasy');
  static String get sum => _t('Сумма', 'Möçber');
  static String get markCashReturned =>
      _t('Отметить деньги сданными', 'Puly tabşyrylan diýip belle');
  static String get markCashReturnedTitle => _t(
        'Отметить деньги по заказу как сданные',
        'Sargyt boýunça puly tabşyrylan diýip belle',
      );
  static String get markCashReturnedNote => _t(
        'Используйте это, только если курьер не смог подтвердить сдачу денег '
            'в своём приложении. Сервер сам создаёт денежную запись на сумму '
            'еды.',
        'Muny diňe kurýer öz goşundysynda puly tabşyrandygyny tassyklap '
            'bilmedik bolsa ulanyň. Serweriň özi iýmit möçberine pul ýazgysyny '
            'döredýär.',
      );
  static String get cashReturnedMarked =>
      _t('Деньги отмечены как сданные', 'Pul tabşyrylan diýip bellendi');
  static String get checkOrderFirst => _t(
        'Сначала проверьте фактическое состояние заказа — операция могла '
            'пройти.',
        'Ilki sargydyň hakyky ýagdaýyny barlaň — amal geçen bolmagy mümkin.',
      );

  // ── Today / show more ─────────────────────────────────────────────────
  static String get todayDay => _t('Сегодня', 'Şu gün');
  static String get noDaysTodayInMonth => _t(
        'За сегодня данных ещё нет. Откройте остальные дни месяца.',
        'Şu gün üçin entek maglumat ýok. Aýyň beýleki günlerini açyň.',
      );
  static String get earlierDays => _t('Прошлые дни', 'Öňki günler');
  static String showOtherDays(int count) =>
      _t('Показать другие дни ($count)', 'Beýleki günleri görkez ($count)');
  static String get hideOtherDays =>
      _t('Скрыть другие дни', 'Beýleki günleri gizle');
  static String get showMore => _t('Показать ещё', 'Ýene görkez');

  // ── Chart tabs ────────────────────────────────────────────────────────
  static String get tabMoney => _t('Деньги', 'Pul');
  static String get tabOrders => _t('Заказы', 'Sargytlar');
  static String get tabBreakdown => _t('Разбивка', 'Bölünişi');
}
