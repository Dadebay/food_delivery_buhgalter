import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/constants.dart';
import '../data/formatting.dart';
import '../data/strings.dart';

/// The app's page frame: a Hugeicon back button, a title and an optional
/// subtitle that says which period is on screen.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: kSurfaceColor,
      appBar: AppBar(
        backgroundColor: kSurfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: canPop ? 0 : 16,
        leading: canPop
            ? IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const AppIcon(AppIcons.back, color: kBlackColor),
                tooltip: S.back,
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kBlackColor,
                fontFamily: gilroyBold,
                fontSize: 20,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kMutedColor,
                  fontFamily: gilroyMedium,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: actions,
        bottom: bottom,
      ),
      body: SafeArea(child: child),
    );
  }
}

/// A white rounded block. Everything on these screens is one of these.
class CardBox extends StatelessWidget {
  const CardBox({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        border: Border.all(color: kBorderColor),
        borderRadius: borderRadius15,
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius15,
        child: box,
      ),
    );
  }
}

/// A row on the overview: icon, title, subtitle, and a chevron that says it
/// opens something.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = kPrimaryColor,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => CardBox(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AppIconBadge(icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: kBlackColor,
                      fontFamily: gilroySemiBold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: kMutedColor,
                      fontFamily: gilroyRegular,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const AppIcon(AppIcons.forward, size: 18, color: kMutedColor),
          ],
        ),
      );
}

/// A headline number with its caption. Used for the money summary and the
/// order counters.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color = kBlackColor,
    this.hint,
  });

  final String label;
  final String value;
  final List<List<dynamic>>? icon;
  final Color color;
  final String? hint;

  @override
  Widget build(BuildContext context) => CardBox(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  AppIcon(icon!, size: 16, color: color),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    style: const TextStyle(
                      fontFamily: gilroyMedium,
                      fontSize: 12,
                      color: kMutedColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontFamily: gilroyBold,
                fontSize: 18,
                color: color,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(
                hint!,
                style: const TextStyle(
                  fontFamily: gilroyRegular,
                  fontSize: 11,
                  color: kMutedColor,
                ),
              ),
            ],
          ],
        ),
      );
}

/// Two tiles per row, and one per row on a 320 px screen, so nothing ever
/// scrolls sideways.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 340 ? 1 : 2;
          final width =
              (constraints.maxWidth - (columns - 1) * 10) / columns;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final tile in tiles) SizedBox(width: width, child: tile),
            ],
          );
        },
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.icon, this.trailing});

  final String text;
  final List<List<dynamic>>? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Row(
          children: [
            if (icon != null) ...[
              AppIcon(icon!, size: 18),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: gilroyBold,
                  fontSize: 17,
                  color: kBlackColor,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

/// Label on the left, value on the right, wrapping instead of overflowing:
/// long names and addresses are the normal case here.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = kBlackColor,
    this.icon,
    this.strong = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final List<List<dynamic>>? icon;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: AppIcon(icon!, size: 15, color: kMutedColor),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              flex: 4,
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: gilroyRegular,
                  fontSize: 13,
                  color: kMutedColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: strong ? gilroyBold : gilroySemiBold,
                  fontSize: 13,
                  color: valueColor,
                ),
              ),
            ),
          ],
        ),
      );
}

/// A small coloured caption — a status, a basis, a warning.
class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    this.color = kPrimaryColor,
    this.icon,
  });

  final String text;
  final Color color;
  final List<List<dynamic>>? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: color.withOpacity(0.10),
          borderRadius: borderRadius30,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              AppIcon(icon!, size: 13, color: color),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: gilroySemiBold,
                  fontSize: 11.5,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      );
}

/// A caveat the screen has to show rather than paper over: a missing
/// snapshot, an unknown courier, a provisional boundary.
class NoticeBox extends StatelessWidget {
  const NoticeBox(this.text, {super.key, this.color = kWarningColor});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: color.withOpacity(0.08),
          borderRadius: borderRadius10,
          // ignore: deprecated_member_use
          border: Border.all(color: color.withOpacity(0.30)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(AppIcons.info, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: gilroyMedium,
                  fontSize: 12.5,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      );
}

/// A name/count/food-money row — districts, kitchens, cancellation reasons.
class NamedCountRow extends StatelessWidget {
  const NamedCountRow({
    super.key,
    required this.name,
    required this.count,
    this.amount,
    this.share,
  });

  final String name;
  final int? count;
  final double? amount;
  final double? share;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontFamily: gilroySemiBold,
                      fontSize: 13.5,
                      color: kBlackColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  Fmt.count(count),
                  style: const TextStyle(
                    fontFamily: gilroyBold,
                    fontSize: 13.5,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
            if (share != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: share!.clamp(0, 1),
                  minHeight: 5,
                  backgroundColor: kBorderColor,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(kPrimaryColor),
                ),
              ),
            ],
            if (amount != null) ...[
              const SizedBox(height: 4),
              Text(
                Fmt.money(amount),
                style: const TextStyle(
                  fontFamily: gilroyRegular,
                  fontSize: 12,
                  color: kMutedColor,
                ),
              ),
            ],
          ],
        ),
      );
}

/// A segmented tab bar that looks like the rest of the app.
///
/// The Material default is an underline on a bare strip, which on these
/// screens read as part of the page rather than as a control. This is the
/// same rounded, tinted shape the filters and the month button use, and it
/// takes an explicit controller so no screen depends on an inherited one.
class PillTabBar extends StatelessWidget implements PreferredSizeWidget {
  const PillTabBar({
    super.key,
    required this.controller,
    required this.labels,
    this.icons,
  });

  final TabController controller;
  final List<String> labels;
  final List<List<List<dynamic>>>? icons;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: kBorderColor),
              borderRadius: borderRadius15,
            ),
            child: Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: _Segment(
                      label: labels[i],
                      icon: icons == null ? null : icons![i],
                      selected: controller.index == i,
                      onTap: () => controller.animateTo(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

class _Segment extends StatelessWidget {
  const _Segment({
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
  Widget build(BuildContext context) => Material(
        color: selected ? kPrimaryColor : Colors.transparent,
        borderRadius: borderRadius10,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius10,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  AppIcon(icon!,
                      size: 15,
                      color: selected ? Colors.white : kMutedColor),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: gilroySemiBold,
                      fontSize: 13,
                      color: selected ? Colors.white : kMutedColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// The stages of an order, drawn as a line rather than as a list of dates.
class Timeline extends StatelessWidget {
  const Timeline({super.key, required this.entries});

  final List<TimelineEntry> entries;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 26,
                    child: Column(
                      children: [
                        Container(
                          width: 11,
                          height: 11,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: entries[i].done ? kPrimaryColor : kBorderColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (i != entries.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: kBorderColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entries[i].title,
                            style: TextStyle(
                              fontFamily: gilroySemiBold,
                              fontSize: 13.5,
                              color: entries[i].done ? kBlackColor : kMutedColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entries[i].subtitle,
                            style: const TextStyle(
                              fontFamily: gilroyRegular,
                              fontSize: 12,
                              color: kMutedColor,
                            ),
                          ),
                          if (entries[i].note != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              entries[i].note!,
                              style: const TextStyle(
                                fontFamily: gilroyMedium,
                                fontSize: 12,
                                color: kBlackColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
}

class TimelineEntry {
  const TimelineEntry({
    required this.title,
    required this.subtitle,
    required this.done,
    this.note,
  });

  final String title;
  final String subtitle;

  /// A stage that has actually happened, as opposed to one still waiting.
  final bool done;
  final String? note;
}

/// One supporting line under a [HeadlineCard]'s headline figure.
class HeadlineRow {
  const HeadlineRow(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;
}

/// One headline figure with its supporting rows.
///
/// This replaced a grid of equal tiles: half a dozen numbers of the same size
/// say nothing about which one to read first.
class HeadlineCard extends StatelessWidget {
  const HeadlineCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.caption,
    required this.value,
    this.rows = const [],
  });

  final List<List<dynamic>> icon;
  final Color accent;
  final String caption;
  final String value;
  final List<HeadlineRow> rows;

  @override
  Widget build(BuildContext context) => CardBox(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIconBadge(icon, color: accent, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caption,
                        style: const TextStyle(
                          fontFamily: gilroyMedium,
                          fontSize: 12.5,
                          color: kMutedColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontFamily: gilroyBold,
                            fontSize: 24,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (rows.isNotEmpty) const Divider(height: 20, color: kBorderColor),
            for (final row in rows)
              InfoRow(
                label: row.label,
                value: row.value,
                valueColor: row.color ?? kBlackColor,
              ),
          ],
        ),
      );
}
