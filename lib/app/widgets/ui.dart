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
              style: TextStyle(
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
          final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
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
                style: TextStyle(
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
                style: TextStyle(
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
                  valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
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

/// One segment of [SegmentedTabBar].
class SegmentTab {
  const SegmentTab(this.label, {this.icon});

  final String label;
  final List<List<dynamic>>? icon;
}

/// A segmented control used as an app bar's tabs.
///
/// The segments share the width equally and never scroll sideways: on these
/// screens a tab that has to be swiped into view is a tab nobody presses. A
/// label too long for its share is scaled down rather than clipped, so the
/// Russian and the Turkmen wording both fit the same bar.
class SegmentedTabBar extends StatelessWidget implements PreferredSizeWidget {
  const SegmentedTabBar({super.key, required this.tabs, this.controller});

  final List<SegmentTab> tabs;
  final TabController? controller;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) => Container(
        height: 46,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kBorderColor),
          borderRadius: borderRadius30,
        ),
        child: TabBar(
          controller: controller,
          isScrollable: false,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          indicator: BoxDecoration(
            color: kPrimaryColor,
            borderRadius: borderRadius30,
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: kPrimaryColor.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          splashBorderRadius: borderRadius30,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          labelColor: Colors.white,
          unselectedLabelColor: kMutedColor,
          labelStyle: const TextStyle(
            fontFamily: gilroySemiBold,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: gilroyMedium,
            fontSize: 13,
          ),
          tabs: [
            for (final tab in tabs)
              Tab(
                height: 38,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (tab.icon != null) ...[
                        _SegmentIcon(tab.icon!),
                        const SizedBox(width: 6),
                      ],
                      Text(tab.label),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
}

/// The icon inside a segment, tinted by whether that segment is selected —
/// [TabBar] colours the text for us but not a Hugeicon.
class _SegmentIcon extends StatelessWidget {
  const _SegmentIcon(this.icon);

  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) => AppIcon(
        icon,
        size: 16,
        color: IconTheme.of(context).color ??
            DefaultTextStyle.of(context).style.color ??
            kMutedColor,
      );
}

/// A full-width button that opens the rest of a list that was cut short.
///
/// Cutting a list silently hides data the accountant came for, so the count
/// of what is still folded away is part of the label.
class ShowMoreButton extends StatelessWidget {
  const ShowMoreButton({
    super.key,
    required this.expanded,
    required this.label,
    required this.onPressed,
  });

  final bool expanded;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 44,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: kBorderColor),
            shape: const RoundedRectangleBorder(borderRadius: borderRadius15),
          ),
          onPressed: onPressed,
          icon: AppIcon(
            expanded ? AppIcons.collapse : AppIcons.expand,
            size: 17,
          ),
          label: Text(
            label,
            style: const TextStyle(
              fontFamily: gilroySemiBold,
              fontSize: 13.5,
              color: kPrimaryColor,
            ),
          ),
        ),
      );
}

/// A dashed rule, the way a paper receipt separates its blocks.
class DashedLine extends StatelessWidget {
  const DashedLine({super.key, this.color = kBorderColor});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 1,
        width: double.infinity,
        child: CustomPaint(painter: _DashedLinePainter(color)),
      );
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 4.0;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + dash > size.width ? size.width : x + dash, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

/// A slip of paper: a white block whose top and bottom edges are torn into
/// the scallops a printed receipt has.
///
/// It is the order's own money made to look like what the courier hands
/// over, so the figures on it are read as one document rather than as four
/// more rows of the same table.
class ReceiptPaper extends StatelessWidget {
  const ReceiptPaper({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 22, 18, 22),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => ClipPath(
        clipper: const _ScallopClipper(),
        child: Container(
          width: double.infinity,
          color: Colors.white,
          padding: padding,
          child: child,
        ),
      );
}

class _ScallopClipper extends CustomClipper<Path> {
  const _ScallopClipper();

  /// How deep each bite out of the edge is. Small enough that the block
  /// still reads as a card, large enough to read as torn paper.
  static const double radius = 6;

  @override
  Path getClip(Size size) {
    final path = Path();
    const step = radius * 2;
    // Top edge, left to right, biting a half-circle out of the paper for
    // every step so the block reads as torn rather than cut.
    path.moveTo(0, radius);
    for (var x = 0.0; x < size.width; x += step) {
      path.arcToPoint(
        Offset(x + step, radius),
        radius: const Radius.circular(radius),
        clockwise: true,
      );
    }
    path.lineTo(size.width, size.height - radius);
    for (var x = size.width; x > 0; x -= step) {
      path.arcToPoint(
        Offset(x - step, size.height - radius),
        radius: const Radius.circular(radius),
        clockwise: true,
      );
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_ScallopClipper old) => false;
}

/// A line on the receipt: a caption on the left and a figure on the right,
/// with the total set larger than the rows that add up to it.
class ReceiptRow extends StatelessWidget {
  const ReceiptRow({
    super.key,
    required this.label,
    required this.value,
    this.total = false,
    this.color,
  });

  final String label;
  final String value;
  final bool total;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: total ? 2 : 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: total ? gilroySemiBold : gilroyRegular,
                  fontSize: total ? 15 : 13,
                  color: total ? kBlackColor : kMutedColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: TextStyle(
                fontFamily: total ? gilroyBold : gilroySemiBold,
                fontSize: total ? 19 : 13,
                color: color ?? kBlackColor,
              ),
            ),
          ],
        ),
      );
}
