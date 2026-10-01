import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/constants.dart';
import '../data/strings.dart';
import 'ui.dart';

/// A ranked list that shows its head and keeps the tail one tap away.
///
/// Districts, kitchens, cancellation reasons and dish demand can each run to
/// dozens of rows. Printing them all turns a summary into a wall, and cutting
/// them silently hides data the accountant came for — so the first few are
/// shown and the rest are behind a count that says how many there are.
class ExpandableList extends StatefulWidget {
  const ExpandableList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.previewCount = 5,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int previewCount;

  @override
  State<ExpandableList> createState() => _ExpandableListState();
}

class _ExpandableListState extends State<ExpandableList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasMore = widget.itemCount > widget.previewCount;
    final shown = _expanded || !hasMore
        ? widget.itemCount
        : widget.previewCount;
    return CardBox(
      child: Column(
        children: [
          for (var i = 0; i < shown; i++) widget.itemBuilder(context, i),
          if (hasMore) ...[
            const Divider(height: 14, color: kBorderColor),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: borderRadius10,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _expanded ? S.showLess : S.showAll(widget.itemCount),
                      style: const TextStyle(
                        fontFamily: gilroySemiBold,
                        fontSize: 13,
                        color: kPrimaryColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AppIcon(
                      _expanded ? AppIcons.collapse : AppIcons.expand,
                      size: 15,
                      color: kPrimaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
