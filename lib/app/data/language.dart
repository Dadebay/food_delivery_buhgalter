import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

/// The two languages the app speaks.
///
/// The choice is the person's, not the phone's: an accountant with a Russian
/// handset may well want Turkmen, so nothing is inferred from the system
/// locale. It is remembered on this device.
enum AppLanguage { russian, turkmen }

extension AppLanguageInfo on AppLanguage {
  String get code => this == AppLanguage.turkmen ? 'tm' : 'ru';

  /// What the language calls itself.
  String get title => this == AppLanguage.turkmen ? 'Türkmençe' : 'Русский';

  String get flagAsset =>
      this == AppLanguage.turkmen ? 'assets/image/tm.png' : 'assets/image/ru.png';

  String get short => this == AppLanguage.turkmen ? 'TM' : 'RU';
}

class LanguageStore extends ChangeNotifier {
  LanguageStore() {
    _current = _storage.read<String>(_key) == 'tm'
        ? AppLanguage.turkmen
        : AppLanguage.russian;
  }

  static const _key = 'language';
  final _storage = GetStorage();

  late AppLanguage _current;

  AppLanguage get current => _current;
  bool get isTurkmen => _current == AppLanguage.turkmen;

  void select(AppLanguage language) {
    if (language == _current) return;
    _current = language;
    _storage.write(_key, language.code);
    notifyListeners();
  }
}
