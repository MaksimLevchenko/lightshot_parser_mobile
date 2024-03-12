import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});

  final _formKey = GlobalKey<FormState>();
  final Future<Directory> _appDocDir = getApplicationDocumentsDirectory();

  void _clearSettingsFile() async {
    final Directory directory = await _appDocDir;
    final File file = File('${directory.path}/settings.json');
    file.open(mode: FileMode.writeOnly);
  }

  void _saveValue(var value, {required String name}) async {
    Directory directory = await _appDocDir;
    final File file = File('${directory.path}/settings.json');
    final jsonValue = json.encode({name: name, value: value.toString()});
    await file.writeAsString(jsonValue, mode: FileMode.writeOnlyAppend);
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      _clearSettingsFile();
      _formKey.currentState!.save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
