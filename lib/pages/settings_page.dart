// ignore_for_file: must_be_immutable

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lightshot_parser_mobile/generated/l10n.dart';
import 'package:lightshot_parser_mobile/pages/main_page.dart';
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
      try {
        _numOfImages = settings['numOfImages'] ?? 10;
        _useNewAddresses = settings['newAddresses'] ?? false;
        _startingUrl = settings['startingUrl'] ?? "";
        _useRandomAddress = _startingUrl == "" ? true : false;
      } on Exception {
        _numOfImages = 10;
        _useNewAddresses = false;
        _startingUrl = '';
        _useRandomAddress = true;
      }
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

  TextFormField _numOfImagesFormField(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: S.of(context).numberOfImagesToDownload,
        hintText: S.of(context).enterTheNumberOfImagesToDownload,
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
          return S.of(context).pleaseEnterTheNumberOfImagesToDownload;
        } else if (int.tryParse(value) == null) {
          return S.of(context).pleaseEnterAValidNumber;
        } else if (int.parse(value) < 1) {
          return S.of(context).pleaseEnterANumberGreaterThan0;
        } else {
          return null;
        }
      },
      onSaved: (newValue) => _numOfImages = int.parse(newValue!),
    );
  }

  Widget _useNewAddressCheckbox(BuildContext context, Function setState) {
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
        Text(S.of(context).useNewAddresses),
      ],
    );
  }

  Widget _useRandomAddressCheckbox(BuildContext context, Function setState) {
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
        Text(S.of(context).useRandomAddresses),
      ],
    );
  }

  TextFormField _startingAddressFormField(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: S.of(context).startingAddress,
        hintText: S.of(context).enterTheStartingAddress,
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
          return S.of(context).pleaseEnterTheStartingAddress;
        } else if ((_useNewAddresses && value.length != 12) ||
            (!_useNewAddresses && value.length != 6)) {
          return S.of(context).pleaseEnterAMaxLengthAddress;
        } else if (!mask.hasMatch(value)) {
          String mask =
              _useNewAddresses ? '(a-z, A-Z, 0-9, _ and -)' : '(a-z, 0-9)';
          return S.of(context).pleaseEnterAAddressWithOnlyAMask(mask);
        } else {
          return null;
        }
      },
      onSaved: (newValue) => _startingUrl = _useRandomAddress ? '' : newValue!,
    );
  }

  void _saveSettings(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _saveSettingsInFile();
      log('Settings saved');
      ScaffoldMessenger.of(context)
          .showSnackBar(_getSnackBar(message: S.of(context).settingsSaved));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(_getSnackBar(
          message: S.of(context).pleaseEnterTheCorrectData, color: Colors.red));
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
    ButtonStyle settingsButtonStyle = ButtonStyle(
      alignment: Alignment.center,
      minimumSize: MaterialStateProperty.all(const Size(150, 30)),
      maximumSize: MaterialStateProperty.all(const Size(150, 45)),
      padding: MaterialStateProperty.all(const EdgeInsets.all(12)),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).settings),
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
                    child: Text(S
                        .of(context)
                        .errorErrorNpleaseTryAgain(snapshot.error!)),
                  );
                }
                return Column(
                  children: [
                    _numOfImagesFormField(context),
                    const SizedBox(height: 5),
                    StatefulBuilder(builder: (context, setState) {
                      return Column(
                        children: [
                          _useNewAddressCheckbox(context, setState),
                          const SizedBox(height: 10),
                          _useRandomAddressCheckbox(context, setState),
                          const SizedBox(height: 16),
                          _startingAddressFormField(context),
                        ],
                      );
                    }),
                    ElevatedButton(
                      style: settingsButtonStyle,
                      onPressed: () {
                        _saveSettings(context);
                      },
                      child: Text(
                        S.of(context).save,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: settingsButtonStyle,
                          onPressed: () {
                            DataBase db = DataBase(
                                databaseFileDirectory: _databaseDirectory,
                                photosDirectory: _photoDirectory);
                            db.parseFolder();
                          },
                          child: FittedBox(
                            child: Text(
                              S.of(context).recreateDatabase,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: settingsButtonStyle,
                          onPressed: () {
                            needToUpdateGallery = true;
                            _photoDirectory.listSync().forEach((element) {
                              element.deleteSync(recursive: true);
                            });
                          },
                          child: FittedBox(
                            child: Text(
                              S.of(context).clearImages,
                              textAlign: TextAlign.center,
                            ),
                          ),
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
