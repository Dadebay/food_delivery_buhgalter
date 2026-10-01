import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/constants.dart';
import '../data/app_state.dart';
import '../data/language.dart';
import '../data/strings.dart';

/// The language switch, shown as the flag of the language in use.
///
/// The choice is the person's and is remembered on this phone; nothing is
/// inferred from the handset's own locale.
class LanguageAction extends StatelessWidget {
  const LanguageAction({super.key});

  @override
  Widget build(BuildContext context) {
    final store = App.instance.language;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => IconButton(
        tooltip: S.language,
        onPressed: () => _pick(context, store),
        icon: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            store.current.flagAsset,
            width: 26,
            height: 18,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Text(
              store.current.short,
              style: const TextStyle(
                fontFamily: gilroyBold,
                fontSize: 12,
                color: kPrimaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, LanguageStore store) =>
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kBorderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  S.language,
                  style: const TextStyle(
                    fontFamily: gilroyBold,
                    fontSize: 17,
                    color: kBlackColor,
                  ),
                ),
                const SizedBox(height: 12),
                for (final language in AppLanguage.values)
                  _LanguageRow(
                    language: language,
                    selected: language == store.current,
                    onTap: () {
                      store.select(language);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
        ),
      );
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: selected ? kSurfaceColor : Colors.white,
          borderRadius: borderRadius15,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius15,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected ? kPrimaryColor : kBorderColor,
                ),
                borderRadius: borderRadius15,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      language.flagAsset,
                      width: 32,
                      height: 22,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        width: 32,
                        height: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      language.title,
                      style: const TextStyle(
                        fontFamily: gilroySemiBold,
                        fontSize: 15,
                        color: kBlackColor,
                      ),
                    ),
                  ),
                  if (selected)
                    const AppIcon(AppIcons.confirmed,
                        size: 20, color: kPrimaryColor),
                ],
              ),
            ),
          ),
        ),
      );
}
