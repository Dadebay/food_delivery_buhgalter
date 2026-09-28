import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

import 'accounting_service.dart';
import 'api_client.dart';
import 'ashgabat_time.dart';
import 'auth_service.dart';
import 'models/shift.dart';

/// The single place the screens reach for the API.
///
/// Small on purpose: one client, one session, one accounting service. The
/// shift settings are cached here because every screen that prints a shift
/// name needs them and they change about once a year.
class App {
  App._();

  static final App instance = App._();

  final ApiClient api = ApiClient();
  late final AuthService auth = AuthService(api);
  late final AccountingService accounting = AccountingService(api);
  final PeriodStore period = PeriodStore();

  AccountingSettings? _settings;
  Future<AccountingSettings>? _settingsRequest;

  /// The configured shift names and windows, fetched once per run. A failure
  /// is not cached: the next screen retries instead of being stuck with
  /// generic labels forever.
  Future<AccountingSettings> settings() {
    final cached = _settings;
    if (cached != null) return Future.value(cached);
    return _settingsRequest ??= accounting.settings().then((value) {
      _settings = value;
      _settingsRequest = null;
      return value;
    }).catchError((Object error) {
      _settingsRequest = null;
      throw error;
    });
  }

  AccountingSettings? get cachedSettings => _settings;

  /// Signing out drops everything a different account must not inherit.
  Future<void> signOut() async {
    await auth.signOut();
    _settings = null;
    _settingsRequest = null;
  }
}

/// The month every section is looking at.
///
/// The spec asks for the month to be visible at the top and for the chosen
/// period to survive going back, so it lives above the screens and is
/// remembered on this phone between runs.
class PeriodStore extends ChangeNotifier {
  PeriodStore() {
    final saved = _storage.read<String>(_key);
    final parsed = Ashgabat.parseDate(saved);
    _month = Ashgabat.firstOfMonth(parsed ?? Ashgabat.now());
  }

  static const _key = 'selectedMonth';
  final _storage = GetStorage();

  late DateTime _month;

  /// Always the first day of the chosen month, in Ashgabat time.
  DateTime get month => _month;

  String get fromDate => Ashgabat.date(Ashgabat.firstOfMonth(_month));
  String get toDate => Ashgabat.date(Ashgabat.lastOfMonth(_month));

  /// The current month is the last one worth offering: there are no future
  /// books to inspect.
  bool get isCurrentMonth {
    final now = Ashgabat.now();
    return _month.year == now.year && _month.month == now.month;
  }

  void select(DateTime month) {
    final first = Ashgabat.firstOfMonth(month);
    if (first == _month) return;
    _month = first;
    _storage.write(_key, Ashgabat.date(first));
    notifyListeners();
  }

  void previous() => select(DateTime(_month.year, _month.month - 1, 1));

  void next() {
    if (isCurrentMonth) return;
    select(DateTime(_month.year, _month.month + 1, 1));
  }
}
