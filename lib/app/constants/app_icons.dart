import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'constants.dart';

/// Every icon in this app comes from Hugeicons (stroke-rounded), listed here
/// once and named by meaning rather than by drawing.
///
/// Naming them by meaning is what keeps "the money packet" the same glyph in
/// the shift list, the order card and the journal: a screen asks for
/// [AppIcons.handoff], not for a wallet.
class AppIcons {
  const AppIcons._();

  // Sections of the app.
  static const List<List<dynamic>> orders = HugeIcons.strokeRoundedInvoice01;
  static const List<List<dynamic>> shifts = HugeIcons.strokeRoundedClock01;
  static const List<List<dynamic>> charts = HugeIcons.strokeRoundedAnalytics01;
  static const List<List<dynamic>> journal = HugeIcons.strokeRoundedTaskDone01;
  static const List<List<dynamic>> carryIn =
      HugeIcons.strokeRoundedArrowDownLeft01;
  static const List<List<dynamic>> carryOut =
      HugeIcons.strokeRoundedArrowUpRight01;

  // Money.
  static const List<List<dynamic>> money = HugeIcons.strokeRoundedMoney03;
  static const List<List<dynamic>> handoff = HugeIcons.strokeRoundedMoneyBag01;
  static const List<List<dynamic>> collected =
      HugeIcons.strokeRoundedMoneyReceive01;
  static const List<List<dynamic>> submitted =
      HugeIcons.strokeRoundedMoneySend01;
  static const List<List<dynamic>> outstanding = HugeIcons.strokeRoundedCoins01;
  static const List<List<dynamic>> confirmed =
      HugeIcons.strokeRoundedCheckmarkBadge01;

  // People.
  static const List<List<dynamic>> person = HugeIcons.strokeRoundedUserCircle;
  static const List<List<dynamic>> courier =
      HugeIcons.strokeRoundedDeliveryTruck01;
  static const List<List<dynamic>> cook = HugeIcons.strokeRoundedChefHat;
  static const List<List<dynamic>> customer = HugeIcons.strokeRoundedUser;
  static const List<List<dynamic>> phone = HugeIcons.strokeRoundedCall;
  static const List<List<dynamic>> access = HugeIcons.strokeRoundedShieldUser;
  static const List<List<dynamic>> signOut = HugeIcons.strokeRoundedLogout01;
  static const List<List<dynamic>> signIn = HugeIcons.strokeRoundedLogin01;
  static const List<List<dynamic>> code = HugeIcons.strokeRoundedLockPassword;

  // Orders and their life.
  static const List<List<dynamic>> dish = HugeIcons.strokeRoundedDish01;
  static const List<List<dynamic>> gift = HugeIcons.strokeRoundedGift;
  static const List<List<dynamic>> rating = HugeIcons.strokeRoundedStar;
  static const List<List<dynamic>> packing = HugeIcons.strokeRoundedPackage;
  static const List<List<dynamic>> delivered =
      HugeIcons.strokeRoundedPackageDelivered;
  static const List<List<dynamic>> address = HugeIcons.strokeRoundedLocation01;
  static const List<List<dynamic>> branch = HugeIcons.strokeRoundedStore01;
  static const List<List<dynamic>> note = HugeIcons.strokeRoundedNote01;
  static const List<List<dynamic>> preparation = HugeIcons.strokeRoundedTimer01;
  static const List<List<dynamic>> edited = HugeIcons.strokeRoundedEdit02;
  static const List<List<dynamic>> cancelled =
      HugeIcons.strokeRoundedCancelCircle;
  static const List<List<dynamic>> transition =
      HugeIcons.strokeRoundedArrowDataTransferHorizontal;
  static const List<List<dynamic>> history = HugeIcons.strokeRoundedWorkHistory;

  // Chrome.
  static const List<List<dynamic>> back = HugeIcons.strokeRoundedArrowLeft01;
  static const List<List<dynamic>> forward =
      HugeIcons.strokeRoundedArrowRight01;
  static const List<List<dynamic>> previousMonth =
      HugeIcons.strokeRoundedArrowLeft01;
  static const List<List<dynamic>> nextMonth =
      HugeIcons.strokeRoundedArrowRight01;
  static const List<List<dynamic>> calendar = HugeIcons.strokeRoundedCalendar03;
  static const List<List<dynamic>> day = HugeIcons.strokeRoundedCalendar01;
  static const List<List<dynamic>> search = HugeIcons.strokeRoundedSearch01;
  static const List<List<dynamic>> filter =
      HugeIcons.strokeRoundedFilterHorizontal;
  static const List<List<dynamic>> refresh = HugeIcons.strokeRoundedRefresh;
  static const List<List<dynamic>> clear = HugeIcons.strokeRoundedCancel01;
  static const List<List<dynamic>> info =
      HugeIcons.strokeRoundedInformationCircle;
  static const List<List<dynamic>> warning = HugeIcons.strokeRoundedAlert02;
  static const List<List<dynamic>> empty = HugeIcons.strokeRoundedFolderOpen;
  static const List<List<dynamic>> districts = HugeIcons.strokeRoundedPieChart;
  static const List<List<dynamic>> ranking = HugeIcons.strokeRoundedBarChart;
  static const List<List<dynamic>> details = HugeIcons.strokeRoundedLayers01;
  static const List<List<dynamic>> expand = HugeIcons.strokeRoundedArrowDown01;
  static const List<List<dynamic>> collapse = HugeIcons.strokeRoundedArrowUp01;
}

/// A Hugeicon with this app's defaults, so screens never repeat the size and
/// colour of every glyph.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.color,
    this.size = 22,
  });

  final List<List<dynamic>> icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) => HugeIcon(
        icon: icon,
        color: color ?? kPrimaryColor,
        size: size,
      );
}

/// The rounded tinted square the section cards and list rows use.
class AppIconBadge extends StatelessWidget {
  const AppIconBadge(
    this.icon, {
    super.key,
    this.color = kPrimaryColor,
    this.size = 48,
  });

  final List<List<dynamic>> icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: color.withOpacity(0.10),
          borderRadius: borderRadius15,
        ),
        child: AppIcon(icon, color: color, size: size * 0.48),
      );
}
