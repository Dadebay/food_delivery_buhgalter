import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/constants/constants.dart';
import 'app/data/app_state.dart';
import 'app/modules/auth/login_page.dart';
import 'app/modules/home/views/main_page.dart';
import 'app/widgets/month_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  // Months, days and times are printed in Russian; the data itself is always
  // Ashgabat time, whatever the phone is set to.
  await initializeDateFormatting(kLocale);

  runApp(const AccountingApp());
}

class AccountingApp extends StatelessWidget {
  const AccountingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
        fontFamily: gilroyRegular,
        scaffoldBackgroundColor: kSurfaceColor,
        useMaterial3: true,
      ),
      home: const _Root(),
    );
  }
}

/// Signed in or not. The app refuses the same set of roles the server does,
/// so a wrong account is told why at the login instead of at every request.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  @override
  Widget build(BuildContext context) {
    if (!App.instance.auth.isSignedIn) {
      return LoginPage(onSignedIn: () => setState(() {}));
    }
    return MainPage(onSignedOut: () => setState(() {}));
  }
}
