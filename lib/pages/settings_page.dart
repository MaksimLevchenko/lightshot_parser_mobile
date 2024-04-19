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
  late bool _useProxy;
  late bool _useProxyAuth;
  late String _proxyAddress;
  late String _proxyPort;
  late String _proxyLogin;
  late String _proxyPassword;

  Future<bool> _loadSettingsFromFile(Directory settingsDir) async {
    final File file =
        File('${settingsDir.path}/lightshot_parser/settings.json');
    if (file.existsSync()) {
      final String jsonString = await file.readAsString();
      final Map<String, dynamic> settings = json.decode(jsonString);
      try {
        _numOfImages = settings['numOfImages'] ?? 10;
        _useNewAddresses = settings['newAddresses'] ?? false;
        _startingUrl = settings['startingUrl'] ?? '';
        _useRandomAddress = _startingUrl == "" ? true : false;
        _useProxy = settings['useProxy'] ?? false;
        _useProxyAuth = settings['useProxyAuth'] ?? false;
        _proxyAddress = settings['proxyAddress'] ?? '';
        _proxyPort = settings['proxyPort'] ?? '';
        _proxyLogin = settings['proxyLogin'] ?? '';
        _proxyPassword = settings['proxyPassword'] ?? '';
      } on Exception {
        _numOfImages = 10;
        _useNewAddresses = false;
        _startingUrl = '';
        _useRandomAddress = true;
        _useProxy = false;
        _useProxyAuth = false;
        _proxyAddress = '';
        _proxyPort = '';
        _proxyLogin = '';
        _proxyPassword = '';
      }
    } else {
      _numOfImages = 10;
      _useNewAddresses = false;
      _startingUrl = '';
      _useRandomAddress = true;
      _useProxy = false;
      _useProxyAuth = false;
      _proxyAddress = '';
      _proxyPort = '';
      _proxyLogin = '';
      _proxyPassword = '';
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
      'useProxy': _useProxy,
      'useProxyAuth': _useProxyAuth,
      'proxyAddress': _proxyAddress,
      'proxyPort': _proxyPort,
      'proxyLogin': _proxyLogin,
      'proxyPassword': _proxyPassword,
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
          String useThisSymbols =
              _useNewAddresses ? '(a-z, A-Z, 0-9, _ and -)' : '(a-z, 0-9)';
          return S.of(context).pleaseEnterAAddressWithOnlyAMask(useThisSymbols);
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

  Widget _useProxyCheckbox(BuildContext context, Function setState) {
    return Row(
      children: [
        Checkbox(
          value: _useProxy,
          onChanged: (value) {
            setState(
              () => _useProxy = value!,
            );
          },
        ),
        Text(S.of(context).useProxy),
      ],
    );
  }

  Widget _useProxyAuthCheckbox(BuildContext context, Function setState) {
    return Row(
      children: [
        Checkbox(
          value: _useProxyAuth,
          onChanged: (value) {
            setState(
              () => _useProxyAuth = value!,
            );
          },
        ),
        Text(S.of(context).useProxyAuth),
      ],
    );
  }

  Widget _proxyAddressForms(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: S.of(context).proxyAddress,
              hintText: S.of(context).enterTheProxyAddress,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(width: 1.5),
              ),
            ),
            textInputAction: TextInputAction.next,
            maxLength: 15,
            keyboardType: TextInputType.number,
            initialValue: _proxyAddress,
            validator: (value) {
              value = value ?? '';
              final addressMask =
                  RegExp(r'^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$');
              if (value.isEmpty) {
                return S.of(context).pleaseEnterTheProxyAddress;
              } else if (!addressMask.hasMatch(value)) {
                return S.of(context).pleaseEnterAValidIpAddress;
              } else {
                return null;
              }
            },
            onSaved: (newValue) => _proxyAddress = newValue!,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: S.of(context).proxyPort,
              hintText: S.of(context).enterTheProxyPort,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(width: 1.5),
              ),
            ),
            textInputAction: TextInputAction.next,
            maxLength: 5,
            keyboardType: TextInputType.number,
            initialValue: _proxyPort,
            validator: (value) {
              final portMask = RegExp(r'^[0-9]{1,5}$');
              value = value ?? '';
              if (value.isEmpty) {
                return S.of(context).pleaseEnterTheProxyPort;
              } else if (!portMask.hasMatch(value)) {
                return S.of(context).pleaseEnterAValidPort;
              } else {
                return null;
              }
            },
            onSaved: (newValue) => _proxyPort = newValue!,
          ),
        ),
      ],
    );
  }

  Widget _proxyLoginForms(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: S.of(context).proxyLogin,
              hintText: S.of(context).enterTheProxyLogin,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(width: 1.5),
              ),
            ),
            textInputAction: TextInputAction.next,
            maxLength: 20,
            keyboardType: TextInputType.text,
            initialValue: _proxyLogin,
            validator: (value) {
              value = value ?? '';
              if (value.isEmpty) {
                return S.of(context).pleaseEnterTheProxyLogin;
              } else {
                return null;
              }
            },
            onSaved: (newValue) => _proxyLogin = newValue!,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: S.of(context).proxyPassword,
              hintText: S.of(context).enterTheProxyPassword,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(width: 1.5),
              ),
            ),
            textInputAction: TextInputAction.done,
            maxLength: 20,
            keyboardType: TextInputType.text,
            initialValue: _proxyPassword,
            validator: (value) {
              value = value ?? '';
              if (value.isEmpty) {
                return S.of(context).pleaseEnterTheProxyPassword;
              } else {
                return null;
              }
            },
            onSaved: (newValue) => _proxyPassword = newValue!,
          ),
        ),
      ],
    );
  }

  // Widget _proxyTypeDropdown(Function setState) {
  //   return DropdownButton<String>(
  //     underline: Container(
  //       height: 2,
  //       color: Colors.pink[700],
  //     ),
  //     value: _proxyType != 'PROXY' ? _proxyType : 'HTTP',
  //     onChanged: (String? newValue) {
  //       log('Proxy type: $newValue');
  //       if (newValue != 'HTTP') {
  //         _proxyType = newValue!;
  //         if (_proxyType == 'SOCKS5') {
  //           _useProxyAuth = false;
  //         }
  //       } else {
  //         _proxyType = 'PROXY';
  //       }
  //       setState(() {});
  //     },
  //     items: <String>['HTTP', 'HTTPS', 'SOCKS4', 'SOCKS5']
  //         .map<DropdownMenuItem<String>>((String value) {
  //       return DropdownMenuItem<String>(
  //         value: value,
  //         child: Text(value),
  //       );
  //     }).toList(),
  //   );
  // }

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
      body: SingleChildScrollView(
        child: SafeArea(
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
                      StatefulBuilder(builder: (context, setState) {
                        if (!_useProxy) {
                          return _useProxyCheckbox(context, setState);
                        } else {
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _useProxyCheckbox(context, setState),
                                  // _proxyTypeDropdown(setState),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _useProxyAuthCheckbox(context, setState),
                              const SizedBox(height: 16),
                              _proxyAddressForms(context),
                              _useProxyAuth
                                  ? const SizedBox(height: 32)
                                  : Container(),
                              _useProxyAuth
                                  ? _proxyLoginForms(context)
                                  : Container(),
                              const SizedBox(height: 32)
                            ],
                          );
                        }
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
      ),
    );
  }
}
