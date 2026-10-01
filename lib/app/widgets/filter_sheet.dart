import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/constants.dart';

/// What a filter sheet came back with.
///
/// Dismissing the sheet and clearing the filter are different answers, so
/// they cannot both be `null`: a dismissal returns null, and clearing
/// returns a choice whose [value] is null.
class FilterChoice {
  const FilterChoice(this.value);

  /// The exact value the API matches on, or null for "no filter".
  final String? value;
}

/// A full-width picker instead of a popup menu.
///
/// The old menu opened as a cramped list anchored to a small button, which
/// on a phone meant long captions were clipped and the current choice was
/// invisible. Here every option is one readable row and the current one is
/// ticked.
Future<FilterChoice?> showFilterSheet(
  BuildContext context, {
  required String title,
  required Map<String, String> entries,
  required String? selected,
  required String noneLabel,
  List<List<dynamic>> Function(String key)? iconFor,
}) =>
    showModalBottomSheet<FilterChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: kBorderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  const AppIcon(AppIcons.filter, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: gilroyBold,
                        fontSize: 17,
                        color: kBlackColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: kBorderColor),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                children: [
                  _Option(
                    label: noneLabel,
                    icon: AppIcons.clear,
                    selected: selected == null,
                    onTap: () =>
                        Navigator.of(context).pop(const FilterChoice(null)),
                  ),
                  for (final entry in entries.entries)
                    _Option(
                      label: entry.value,
                      icon: iconFor?.call(entry.key),
                      selected: selected == entry.key,
                      onTap: () =>
                          Navigator.of(context).pop(FilterChoice(entry.key)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final List<List<dynamic>>? icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
        child: Material(
          color: selected ? kSurfaceColor : Colors.transparent,
          borderRadius: borderRadius10,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              child: Row(
                children: [
                  if (icon != null) ...[
                    AppIcon(icon!,
                        size: 17,
                        color: selected ? kPrimaryColor : kMutedColor),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily:
                            selected ? gilroySemiBold : gilroyRegular,
                        fontSize: 14.5,
                        color: selected ? kPrimaryColor : kBlackColor,
                      ),
                    ),
                  ),
                  if (selected)
                    const AppIcon(AppIcons.confirmed,
                        size: 19, color: kPrimaryColor),
                ],
              ),
            ),
          ),
        ),
      );
}

/// The button that opens a [showFilterSheet], showing the current choice.
class FilterButton extends StatelessWidget {
  const FilterButton({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.icon = AppIcons.filter,
    this.compact = false,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final List<List<dynamic>> icon;

  /// Icon only, for a row that is already tight.
  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
        color: active ? kPrimaryColor : Colors.white,
        borderRadius: borderRadius10,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius10,
          child: Container(
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
            decoration: BoxDecoration(
              border: Border.all(color: active ? kPrimaryColor : kBorderColor),
              borderRadius: borderRadius10,
            ),
            child: Row(
              mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
              children: [
                AppIcon(icon,
                    size: 17, color: active ? Colors.white : kPrimaryColor),
                if (!compact) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: gilroySemiBold,
                        fontSize: 12.5,
                        color: active ? Colors.white : kBlackColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
