import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import 'app/constants/constants.dart';
import 'app/modules/home/views/main_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

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
      home: const MainPage(),
    );
  }
}
