import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lightshot_parser_mobile/generated/l10n.dart';
import 'package:lightshot_parser_mobile/pages/main_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    //locale: const Locale('en'),
    //locale: const Locale('uk'),
    //locale: const Locale('ru'),
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      S.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    scrollBehavior: const MaterialScrollBehavior().copyWith(dragDevices: {
      PointerDeviceKind.trackpad,
      PointerDeviceKind.touch,
      PointerDeviceKind.mouse,
      PointerDeviceKind.stylus,
    }),
    home: MainPage(),
    theme: ThemeData.from(
        useMaterial3: false,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink)),
  ));
}
