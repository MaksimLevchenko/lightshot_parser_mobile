import 'package:flutter/material.dart';
import 'package:lightshot_parser_mobile/pages/main_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    home: MainPage(),
    theme: ThemeData.from(
        useMaterial3: false,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink)),
  ));
}
