import 'package:flutter/material.dart';
import 'package:lightshot_parser_mobile/pages/main_page.dart';

void main() {
  runApp(MaterialApp(
    home: const MainPage(),
    theme: ThemeData.from(
        useMaterial3: false,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink)),
  ));
}
