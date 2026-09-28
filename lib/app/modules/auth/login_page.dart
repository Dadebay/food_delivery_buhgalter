import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_icons.dart';
import '../../constants/constants.dart';
import '../../data/app_state.dart';
import '../../data/auth_service.dart';
import '../../widgets/state_views.dart';

/// Phone + one-time code, the same sign-in the other staff apps use.
///
/// A wrong code and a wrong role are told apart on purpose: the first is a
/// typo, the second is a conversation with the owner. Being handed the
/// `ACCOUNTING` page does not by itself open this app — the server decides,
/// and the message here says so instead of looping on a silent 403.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onSignedIn});

  final VoidCallback onSignedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController();
  final _code = TextEditingController();

  bool _codeRequested = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on WrongRoleException catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestCode() => _run(() async {
        final phone = _phone.text.trim();
        if (phone.isEmpty) {
          setState(() => _error = 'Введите номер телефона.');
          return;
        }
        await App.instance.auth.requestCode(phone);
        if (mounted) setState(() => _codeRequested = true);
      });

  Future<void> _verify() => _run(() async {
        final code = _code.text.trim();
        if (code.isEmpty) {
          setState(() => _error = 'Введите код из сообщения.');
          return;
        }
        await App.instance.auth.verifyCode(_phone.text.trim(), code);
        widget.onSignedIn();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurfaceColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
          children: [
            const AppIconBadge(AppIcons.access, size: 64),
            const SizedBox(height: 20),
            const Text(
              appName,
              style: TextStyle(
                fontFamily: gilroyBold,
                fontSize: 28,
                color: kBlackColor,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Просмотр смен, денег и журнала действий. Раздел открыт '
              'бухгалтеру и владельцу.',
              style: TextStyle(
                fontFamily: gilroyRegular,
                fontSize: 14,
                color: kMutedColor,
              ),
            ),
            const SizedBox(height: 28),
            _Field(
              controller: _phone,
              icon: AppIcons.phone,
              label: 'Номер телефона',
              hint: '+993…',
              keyboardType: TextInputType.phone,
              enabled: !_busy && !_codeRequested,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
              ],
            ),
            if (_codeRequested) ...[
              const SizedBox(height: 12),
              _Field(
                controller: _code,
                icon: AppIcons.code,
                label: 'Код из сообщения',
                hint: '______',
                keyboardType: TextInputType.number,
                enabled: !_busy,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                style: const TextStyle(
                  fontFamily: gilroyMedium,
                  fontSize: 13,
                  color: kNegativeColor,
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: const RoundedRectangleBorder(
                      borderRadius: borderRadius15),
                ),
                onPressed:
                    _busy ? null : (_codeRequested ? _verify : _requestCode),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _codeRequested ? 'Войти' : 'Получить код',
                        style: const TextStyle(
                          fontFamily: gilroySemiBold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            if (_codeRequested && !_busy)
              TextButton(
                onPressed: () => setState(() {
                  _codeRequested = false;
                  _code.clear();
                  _error = null;
                }),
                child: const Text(
                  'Изменить номер',
                  style: TextStyle(fontFamily: gilroyMedium),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.icon,
    required this.label,
    required this.hint,
    required this.keyboardType,
    required this.enabled,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final List<List<dynamic>> icon;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(fontFamily: gilroySemiBold, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(
            fontFamily: gilroyMedium,
            color: kMutedColor,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: AppIcon(icon, size: 20),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: borderRadius15,
            borderSide: BorderSide(color: kBorderColor),
          ),
          disabledBorder: const OutlineInputBorder(
            borderRadius: borderRadius15,
            borderSide: BorderSide(color: kBorderColor),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: borderRadius15,
            borderSide: BorderSide(color: kPrimaryColor),
          ),
        ),
      );
}
