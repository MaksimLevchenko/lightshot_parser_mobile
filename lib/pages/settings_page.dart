// ignore_for_file: must_be_immutable

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lightshot_parser_mobile/parser/parser_db.dart';

class SettingsPage extends StatelessWidget {
  final Directory _photoDirectory;
  final Directory _databaseDirectory;
  final Directory _settingsDirectory;
  SettingsPage(
      {super.key,
      required Directory photoDirectory,
      required Directory databaseDirectory,
      required Directory settingsDirectory})
      : _settingsDirectory = settingsDirectory,
        _databaseDirectory = databaseDirectory,
        _photoDirectory = photoDirectory;

  final _formKey = GlobalKey<FormState>();

  late bool _useNewAddresses;
  late bool _useRandomAddress;
  late int _numOfImages;
  late String _startingUrl;

  Future<bool> _loadSettingsFromFile(Directory settingsDir) async {
    final File file =
        File('${settingsDir.path}/lightshot_parser/settings.json');
    if (file.existsSync()) {
      final String jsonString = await file.readAsString();
      final Map<String, dynamic> settings = json.decode(jsonString);
      _numOfImages = settings['numOfImages'] ?? 10;
      _useNewAddresses = settings['newAddresses'] ?? false;
      _startingUrl = settings['startingUrl'] ?? "";
      _useRandomAddress = _startingUrl == "" ? true : false;
    } else {
      _numOfImages = 10;
      _useNewAddresses = false;
      _startingUrl = '';
      _useRandomAddress = true;
    }
    return true;
  }

  void _saveSettingsInFile() {
    final Directory directory = _settingsDirectory;
    final File file = File('${directory.path}/lightshot_parser/settings.json');
    file.createSync(recursive: true);
    log('settings in ${file.path}');
    final Map<String, dynamic> settings = {
      'numOfImages': _numOfImages,
      'newAddresses': _useNewAddresses,
      'startingUrl': _startingUrl,
    };
    file.writeAsString(json.encode(settings));
  }

  TextFormField _numOfImagesFormField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Number of images to download",
        hintText: "Enter the number of images to download",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(width: 1.5),
        ),
      ),
      textInputAction: TextInputAction.next,
      maxLength: 5,
      keyboardType: TextInputType.number,
      autofocus: true,
      initialValue: _numOfImages.toString(),
      validator: (value) {
        value = value ?? '';
        if (value.isEmpty) {
          return "Please enter the number of images to download";
        } else if (int.tryParse(value) == null) {
          return "Please enter a valid number";
        } else if (int.parse(value) < 1) {
          return "Please enter a number greater than 0";
        } else {
          return null;
        }
      },
      onSaved: (newValue) => _numOfImages = int.parse(newValue!),
    );
  }

  Widget _useNewAddressCheckbox(Function setState) {
    return Row(
      children: [
        Checkbox(
          value: _useNewAddresses,
          onChanged: (value) {
            setState(
              () => _useNewAddresses = value!,
            );
          },
        ),
        const Text("Use new addresses"),
      ],
    );
  }

  Widget _useRandomAddressCheckbox(Function setState) {
    return Row(
      children: [
        Checkbox(
          value: _useRandomAddress,
          onChanged: (value) {
            setState(
              () => _useRandomAddress = value!,
            );
          },
        ),
        const Text("Use random addresses"),
      ],
    );
  }

  TextFormField _startingAddressFormField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Starting address",
        hintText: "Enter the starting address",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(width: 1.5),
        ),
      ),
      maxLength: _useNewAddresses ? 12 : 6,
      enabled: !_useRandomAddress,
      initialValue: _startingUrl,
      validator: (value) {
        if (_useRandomAddress) {
          return null;
        }
        value = value ?? '';
        RegExp mask = _useNewAddresses
            ? RegExp(r'^[a-zA-Z0-9_-]{12}$')
            : RegExp(r'^[a-z0-9]{6}$');
        if (value.isEmpty) {
          return "Please enter the starting address";
        } else if ((_useNewAddresses && value.length != 12) ||
            (!_useNewAddresses && value.length != 6)) {
          return "Please enter a max length address";
        } else if (!mask.hasMatch(value)) {
          return "Please enter a address with only a ${_useNewAddresses ? '(a-z, A-Z, 0-9, _ and -)' : '(a-z, 0-9)'}";
        } else {
          return null;
        }
      },
      onSaved: (newValue) => _startingUrl = _useRandomAddress ? '' : newValue!,
    );
  }

  void _saveSettings(BuildContext context) {
    log('starting save func');
    if (_formKey.currentState!.validate()) {
      log('validate starting complete');
      _formKey.currentState!.save();
      _saveSettingsInFile();
      log('form saved');
      ScaffoldMessenger.of(context)
          .showSnackBar(_getSnackBar(message: "Settings saved"));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(_getSnackBar(
          message: "Please enter the correct data", color: Colors.red));
    }
  }

  SnackBar _getSnackBar({required String message, Color color = Colors.green}) {
    return SnackBar(
      content: Center(child: Text(message)),
      duration: const Duration(seconds: 2),
      backgroundColor: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: FutureBuilder(
              future: _loadSettingsFromFile(_settingsDirectory),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                        "Error: ${snapshot.error.toString()} \nPlease try again"),
                  );
                }
                return Column(
                  children: [
                    _numOfImagesFormField(),
                    const SizedBox(height: 5),
                    StatefulBuilder(builder: (context, setState) {
                      return Column(
                        children: [
                          _useNewAddressCheckbox(setState),
                          const SizedBox(height: 10),
                          _useRandomAddressCheckbox(setState),
                          const SizedBox(height: 16),
                          _startingAddressFormField(),
                        ],
                      );
                    }),
                    ElevatedButton(
                      onPressed: () {
                        _saveSettings(context);
                      },
                      child: const Text("Save"),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ButtonStyle(
                              fixedSize: MaterialStateProperty.all(
                                  const Size(150, 30))),
                          child: const Text('Recreate database'),
                          onPressed: () {
                            DataBase db = DataBase(
                                fileDirectory: _databaseDirectory,
                                photosDirectory: _photoDirectory);
                            db.parseFolder();
                          },
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ButtonStyle(
                              fixedSize: MaterialStateProperty.all(
                                  const Size(150, 30))),
                          onPressed: () {
                            _photoDirectory.listSync().forEach((element) {
                              element.deleteSync(recursive: true);
                            });
                          },
                          child: const Text('Clear images'),
                        ),
                      ],
                    ),
                  ],
                );
              }),
        ),
      ),
    );
  }
}
