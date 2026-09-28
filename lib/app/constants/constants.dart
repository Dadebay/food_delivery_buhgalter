import 'package:flutter/material.dart';

const String serverURL = 'https://a7-tagam.com.tm/api/v1';

/// The web screen this app mirrors, for anyone comparing numbers by hand.
const String accountingWebUrl = 'https://a7-tagam.com.tm/accounting';

const Color kPrimaryColor = Color(0xff6366f1);
const Color kBlackColor = Color(0xff2b2b2b);
const Color kSurfaceColor = Color(0xfff6f6f9);
const Color kMutedColor = Color(0xff8a8a99);
const Color kBorderColor = Color(0xffe4e4ec);

/// Money in, money out, and the gap between what was declared and expected.
/// Used for amounts and for the chart series, so the two always agree.
const Color kPositiveColor = Color(0xff1e8e4e);
const Color kNegativeColor = Color(0xffc0392b);
const Color kWarningColor = Color(0xffe08a1e);

const BorderRadius borderRadius10 = BorderRadius.all(Radius.circular(10));
const BorderRadius borderRadius15 = BorderRadius.all(Radius.circular(15));
const BorderRadius borderRadius20 = BorderRadius.all(Radius.circular(20));
const BorderRadius borderRadius30 = BorderRadius.all(Radius.circular(30));

const String gilroyBold = 'GilroyBold';
const String gilroySemiBold = 'GilroySemiBold';
const String gilroyMedium = 'GilroyMedium';
const String gilroyRegular = 'GilroyRegular';

const String tmIcon = 'assets/image/tm.png';
const String ruIcon = 'assets/image/ru.png';

const String appName = 'Бухгалтерия';

/// The API's paging contract: `page` starts at 1, `limit` defaults to 25 and
/// is capped at 100. The first page is never the whole report.
const int kPageSize = 25;
const int kMaxPageSize = 100;

/// The longest range the API accepts in one call.
const int kMaxRangeDays = 366;

void showSnackBar(BuildContext context, String message, {Color? color}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: color ?? kBlackColor,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: borderRadius15),
        margin: const EdgeInsets.all(12),
        duration: const Duration(milliseconds: 2400),
        content: Text(
          message,
          style: const TextStyle(fontFamily: gilroyMedium, color: Colors.white),
        ),
      ),
    );
}
