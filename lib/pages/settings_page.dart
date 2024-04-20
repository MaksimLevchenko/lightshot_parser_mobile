// ignore_for_file: must_be_immutable

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:lightshot_parser_mobile/data/settings_data.dart';
import 'package:lightshot_parser_mobile/generated/l10n.dart';
import 'package:lightshot_parser_mobile/pages/main_page.dart';
import 'package:lightshot_parser_mobile/parser/parser_db.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});

  final _formKey = GlobalKey<FormState>();

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
      initialValue: SettingsData.wantedNumOfImages.toString(),
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
      onSaved: (newValue) =>
          SettingsData.wantedNumOfImages = int.parse(newValue!),
    );
  }

  Widget _useNewAddressCheckbox(BuildContext context, Function setState) {
    return Row(
      children: [
        Checkbox(
          value: SettingsData.newAddresses,
          onChanged: (value) {
            setState(
              () => SettingsData.newAddresses = value!,
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
          value: SettingsData.useRandomAddress,
          onChanged: (value) {
            setState(
              () => SettingsData.useRandomAddress = value!,
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
      maxLength: SettingsData.newAddresses ? 12 : 6,
      enabled: !SettingsData.useRandomAddress,
      initialValue: SettingsData.startingUrl,
      validator: (value) {
        if (SettingsData.useRandomAddress) {
          return null;
        }
        value = value ?? '';
        RegExp mask = SettingsData.newAddresses
            ? RegExp(r'^[a-zA-Z0-9_-]{12}$')
            : RegExp(r'^[a-z0-9]{6}$');
        if (value.isEmpty) {
          return S.of(context).pleaseEnterTheStartingAddress;
        } else if ((SettingsData.newAddresses && value.length != 12) ||
            (!SettingsData.newAddresses && value.length != 6)) {
          return S.of(context).pleaseEnterAMaxLengthAddress;
        } else if (!mask.hasMatch(value)) {
          String useThisSymbols = SettingsData.newAddresses
              ? '(a-z, A-Z, 0-9, _ and -)'
              : '(a-z, 0-9)';
          return S.of(context).pleaseEnterAAddressWithOnlyAMask(useThisSymbols);
        } else {
          return null;
        }
      },
      onSaved: (newValue) => SettingsData.startingUrl =
          SettingsData.useRandomAddress ? '' : newValue!,
    );
  }

  void _saveSettings(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      SettingsData.saveSettingsToFile();
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
          value: SettingsData.useProxy,
          onChanged: (value) {
            setState(
              () => SettingsData.useProxy = value!,
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
          value: SettingsData.useProxyAuth,
          onChanged: (value) {
            setState(
              () => SettingsData.useProxyAuth = value!,
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
            initialValue: SettingsData.proxyAddress,
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
            onSaved: (newValue) => SettingsData.proxyAddress = newValue!,
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
            initialValue: SettingsData.proxyPort,
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
            onSaved: (newValue) => SettingsData.proxyPort = newValue!,
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
            initialValue: SettingsData.proxyLogin,
            validator: (value) {
              value = value ?? '';
              if (value.isEmpty) {
                return S.of(context).pleaseEnterTheProxyLogin;
              } else {
                return null;
              }
            },
            onSaved: (newValue) => SettingsData.proxyLogin = newValue!,
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
            initialValue: SettingsData.proxyPassword,
            validator: (value) {
              value = value ?? '';
              if (value.isEmpty) {
                return S.of(context).pleaseEnterTheProxyPassword;
              } else {
                return null;
              }
            },
            onSaved: (newValue) => SettingsData.proxyPassword = newValue!,
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
        padding: EdgeInsets.only(top: 10),
        child: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: Form(
              key: _formKey,
              child: Column(
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
                    if (!SettingsData.useProxy) {
                      return _useProxyCheckbox(context, setState);
                    } else {
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _useProxyCheckbox(context, setState),
                              // _proxyTypeDropdown(setState),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _useProxyAuthCheckbox(context, setState),
                          const SizedBox(height: 16),
                          _proxyAddressForms(context),
                          SettingsData.useProxyAuth
                              ? const SizedBox(height: 32)
                              : Container(),
                          SettingsData.useProxyAuth
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
                              databaseFileDirectory:
                                  SettingsData.databaseDirectory,
                              photosDirectory: SettingsData.photosDirectory);
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
                          SettingsData.photosDirectory
                              .listSync()
                              .forEach((element) {
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
              )),
        ),
      ),
    );
  }
}
