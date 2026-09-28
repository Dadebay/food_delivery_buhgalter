import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_icons.dart';
import '../../constants/constants.dart';
import '../../data/app_state.dart';
import '../../data/strings.dart';
import '../../widgets/language_action.dart';
import '../../widgets/state_views.dart';

/// Phone + one-time code, in two clear steps.
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
  final _codeFocus = FocusNode();

  bool _codeRequested = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phone.addListener(() => setState(() {}));
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  /// The country code is printed in the field, so only the eight local
  /// digits are typed. Pasting a full number still works: the prefix is
  /// stripped rather than rejected.
  String get _localDigits {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    final local = digits.startsWith('993') ? digits.substring(3) : digits;
    return local.length > 8 ? local.substring(local.length - 8) : local;
  }

  String get _fullPhone => '+993$_localDigits';
  bool get _phoneReady => _localDigits.length == 8;
  bool get _codeReady => _code.text.trim().length >= 4;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestCode() => _run(() async {
        if (!_phoneReady) {
          setState(() => _error = S.enterPhone);
          return;
        }
        await App.instance.auth.requestCode(_fullPhone);
        if (!mounted) return;
        setState(() => _codeRequested = true);
        _codeFocus.requestFocus();
      });

  Future<void> _verify() => _run(() async {
        if (!_codeReady) {
          setState(() => _error = S.enterCode);
          return;
        }
        await App.instance.auth.verifyCode(_fullPhone, _code.text.trim());
        widget.onSignedIn();
      });

  @override
  Widget build(BuildContext context) {
    final language = App.instance.language;
    return AnimatedBuilder(
      animation: language,
      builder: (context, _) => Scaffold(
        backgroundColor: kSurfaceColor,
        body: Stack(
          children: [
            const _Backdrop(),
            SafeArea(
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: LanguageAction(),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        _header(),
                        const SizedBox(height: 28),
                        _card(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: borderRadius20,
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: kPrimaryColor.withOpacity(0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const AppIcon(AppIcons.money, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            S.appName,
            style: const TextStyle(
              fontFamily: gilroyBold,
              fontSize: 30,
              color: kBlackColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            S.loginSubtitle,
            style: const TextStyle(
              fontFamily: gilroyRegular,
              fontSize: 14.5,
              color: kMutedColor,
            ),
          ),
        ],
      );

  Widget _card() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius20,
          border: Border.all(color: kBorderColor),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _StepDot(active: true),
                const SizedBox(width: 6),
                _StepDot(active: _codeRequested),
                const SizedBox(width: 10),
                Text(
                  _codeRequested ? S.stepCode : S.stepPhone,
                  style: const TextStyle(
                    fontFamily: gilroyMedium,
                    fontSize: 12,
                    color: kMutedColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_codeRequested) _phoneStep() else _codeStep(),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: kNegativeColor.withOpacity(0.07),
                  borderRadius: borderRadius10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppIcon(AppIcons.warning,
                        size: 16, color: kNegativeColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontFamily: gilroyMedium,
                          fontSize: 12.5,
                          color: kNegativeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  disabledBackgroundColor: kBorderColor,
                  shape: const RoundedRectangleBorder(
                      borderRadius: borderRadius15),
                ),
                onPressed: _busy || (_codeRequested ? !_codeReady : !_phoneReady)
                    ? null
                    : (_codeRequested ? _verify : _requestCode),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _codeRequested ? S.signIn : S.getCode,
                            style: const TextStyle(
                              fontFamily: gilroySemiBold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppIcon(
                            _codeRequested ? AppIcons.signIn : AppIcons.forward,
                            size: 18,
                            color: Colors.white,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppIcon(AppIcons.access, size: 15, color: kMutedColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    S.loginAccessNote,
                    style: const TextStyle(
                      fontFamily: gilroyRegular,
                      fontSize: 12,
                      color: kMutedColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _phoneStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.phoneLabel,
            style: const TextStyle(
              fontFamily: gilroySemiBold,
              fontSize: 13.5,
              color: kBlackColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: kSurfaceColor,
              borderRadius: borderRadius15,
              border: Border.all(
                color: _phoneReady ? kPrimaryColor : kBorderColor,
              ),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 0, 8, 0),
                  child: Text(
                    '+993',
                    style: const TextStyle(
                      fontFamily: gilroyBold,
                      fontSize: 17,
                      color: kBlackColor,
                    ),
                  ),
                ),
                Container(width: 1, height: 26, color: kBorderColor),
                Expanded(
                  child: TextField(
                    controller: _phone,
                    enabled: !_busy,
                    autofocus: true,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _phoneReady ? _requestCode() : null,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    style: const TextStyle(
                      fontFamily: gilroyBold,
                      fontSize: 17,
                      letterSpacing: 1.2,
                      color: kBlackColor,
                    ),
                    decoration: const InputDecoration(
                      hintText: '6X XX XX XX',
                      hintStyle: TextStyle(
                        fontFamily: gilroyMedium,
                        fontSize: 16,
                        letterSpacing: 1.2,
                        color: kBorderColor,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _codeStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  S.codeSentTo(_fullPhone),
                  style: const TextStyle(
                    fontFamily: gilroyMedium,
                    fontSize: 13,
                    color: kMutedColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _codeRequested = false;
                          _code.clear();
                          _error = null;
                        }),
                child: Text(
                  S.changeNumber,
                  style: const TextStyle(
                    fontFamily: gilroySemiBold,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: kSurfaceColor,
              borderRadius: borderRadius15,
              border: Border.all(
                color: _codeReady ? kPrimaryColor : kBorderColor,
              ),
            ),
            child: TextField(
              controller: _code,
              focusNode: _codeFocus,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onSubmitted: (_) => _codeReady ? _verify() : null,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              style: const TextStyle(
                fontFamily: gilroyBold,
                fontSize: 26,
                letterSpacing: 10,
                color: kBlackColor,
              ),
              decoration: InputDecoration(
                hintText: '••••',
                hintStyle: const TextStyle(
                  fontSize: 22,
                  letterSpacing: 10,
                  color: kBorderColor,
                ),
                labelText: S.codeLabel,
                labelStyle: const TextStyle(
                  fontFamily: gilroyMedium,
                  color: kMutedColor,
                ),
                floatingLabelAlignment: FloatingLabelAlignment.center,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy ? null : _requestCode,
              child: Text(
                S.resendCode,
                style: const TextStyle(
                  fontFamily: gilroyMedium,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ],
      );
}

/// A soft tint behind the card, so the sign-in does not look like a form on
/// a blank page.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                // ignore: deprecated_member_use
                kPrimaryColor.withOpacity(0.10),
                kSurfaceColor,
              ],
              stops: const [0, 0.45],
            ),
          ),
        ),
      );
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) => Container(
        width: active ? 22 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: active ? kPrimaryColor : kBorderColor,
          borderRadius: BorderRadius.circular(4),
        ),
      );
}
