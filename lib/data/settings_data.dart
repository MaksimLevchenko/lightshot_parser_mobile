import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:lightshot_parser_mobile/parser/parser_db.dart';
import 'package:path_provider/path_provider.dart';

class SettingsData {
  static late int wantedNumOfImages;
  static late bool newAddresses;
  static late String startingUrl;
  static late bool useProxy;
  static late bool useProxyAuth;
  static late String proxyAddress;
  static late String proxyPort;
  static late String proxyLogin;
  static late String proxyPassword;
  static late bool useRandomAddress;

  static late final Directory photosDirectory;
  static late final Directory databaseDirectory;
  static late final Directory settingsDirectory;

  final Future<Directory> _appDocDir = getApplicationDocumentsDirectory();
  final Future<Directory?> _downloadDirectoryPath =
      getApplicationCacheDirectory();

  Future<bool> initSettings() async {
    final Directory appDocDir = await _appDocDir;
    final Directory? downloadDirectoryPath = await _downloadDirectoryPath;

    photosDirectory = Directory('${downloadDirectoryPath!.path}/Photos');
    databaseDirectory = Directory(appDocDir.path);
    settingsDirectory = Directory('${appDocDir.path}/lightshot_parser');

    if (!await photosDirectory.exists()) {
      await photosDirectory.create(recursive: true);
    }
    if (!await databaseDirectory.exists()) {
      await databaseDirectory.create(recursive: true);
    }
    if (!await settingsDirectory.exists()) {
      await settingsDirectory.create(recursive: true);
    }

    DataBase(
      databaseFileDirectory: databaseDirectory,
      photosDirectory: photosDirectory,
    );

    await _loadSettingsFromFile();

    return true;
  }

  static void saveSettingsToFile() {
    final Directory directory = settingsDirectory;
    final File file = File('${directory.path}/settings.json');
    file.createSync(recursive: true);
    log('settings in ${file.path}');
    final Map<String, dynamic> settings = {
      'numOfImages': wantedNumOfImages,
      'newAddresses': newAddresses,
      'startingUrl': startingUrl,
      'useProxy': useProxy,
      'useProxyAuth': useProxyAuth,
      'proxyAddress': proxyAddress,
      'proxyPort': proxyPort,
      'proxyLogin': proxyLogin,
      'proxyPassword': proxyPassword,
    };
    file.writeAsString(json.encode(settings));
  }

  Future<bool> _loadSettingsFromFile() async {
    final File file = File('${settingsDirectory.path}/settings.json');
    if (file.existsSync()) {
      final String jsonString = await file.readAsString();
      final Map<String, dynamic> settings = json.decode(jsonString);
      try {
        wantedNumOfImages = settings['numOfImages'] ?? 10;
        newAddresses = settings['newAddresses'] ?? false;
        startingUrl = settings['startingUrl'] ?? '';
        useRandomAddress = startingUrl == "" ? true : false;
        useProxy = settings['useProxy'] ?? false;
        useProxyAuth = settings['useProxyAuth'] ?? false;
        proxyAddress = settings['proxyAddress'] ?? '';
        proxyPort = settings['proxyPort'] ?? '';
        proxyLogin = settings['proxyLogin'] ?? '';
        proxyPassword = settings['proxyPassword'] ?? '';
      } on Exception {
        wantedNumOfImages = 10;
        newAddresses = false;
        startingUrl = '';
        useRandomAddress = true;
        useProxy = false;
        useProxyAuth = false;
        proxyAddress = '';
        proxyPort = '';
        proxyLogin = '';
        proxyPassword = '';
      }
    } else {
      wantedNumOfImages = 10;
      newAddresses = false;
      startingUrl = '';
      useRandomAddress = true;
      useProxy = false;
      useProxyAuth = false;
      proxyAddress = '';
      proxyPort = '';
      proxyLogin = '';
      proxyPassword = '';
    }
    return true;
  }
}
