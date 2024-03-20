import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lightshot_parser_mobile/pages/settings_page.dart';
import 'package:lightshot_parser_mobile/parser/parser.dart';
import 'package:lightshot_parser_mobile/parser/parser_db.dart';
import 'package:path_provider/path_provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Directory photosDirectory = Directory('');
  Directory databaseDirectory = Directory('');

  Future<Directory?> downloadDirectoryPath = getDownloadsDirectory();
  bool _downloading = false;

  late int numOfImages;
  late bool newAddresses;
  late String startingUrl;

  Widget _gallery() {
    return Builder(builder: (context) {
      DataBase db = DataBase(
          photosDirectory: photosDirectory, fileDirectory: databaseDirectory);
      if (db.numOfDownloadedPhotos() < 15) {
        return const Placeholder();
      }
      return const Placeholder();
    });
  }

  final Future<Directory> _appDocDir = getApplicationDocumentsDirectory();

  Future<bool> _loadSettings() async {
    await _appDocDir.then((value) async {
      final File file = File('${value.path}/lightshot_parser/settings.json');
      if (file.existsSync()) {
        final Future<String> jsonString = file.readAsString();
        final Map<String, dynamic> settings = json.decode(await jsonString);
        numOfImages = settings['numOfImages'];
        newAddresses = settings['newAddresses'];
        startingUrl = settings['startingUrl'];
      } else {
        numOfImages = 10;
        newAddresses = false;
        startingUrl = '';
      }
    });
    return true;
  }

  Widget _futureCheck(Widget child) {
    return FutureBuilder(
      future: Future.wait([downloadDirectoryPath]),
      builder: (BuildContext context, snapshot) {
        _loadSettings();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: Text('No download folder found'),
          );
        }
        log('download to ${snapshot.data![0]!.path}/LightshotParser/Photos');
        photosDirectory =
            Directory('${snapshot.data![0]!.path}/LightshotParser/Photos');
        databaseDirectory =
            Directory('${snapshot.data![0]!.path}/LightshotParser/');

        return child;
      },
    );
  }

  Widget _mainScreen() {
    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {},
              child: _gallery(),
            ),
            const SizedBox(height: 16),
            _downloading
                ? ElevatedButton(
                    onPressed: _stopDownloading,
                    child: const Text('Cancel'),
                  )
                : ElevatedButton(
                    onPressed: () {
                      _startDownloading();
                    },
                    child: const Text('Download'),
                  ),
          ],
        ),
      ),
    );
  }

  void _startDownloading() {
    _loadSettings();
    LightshotParser parser = LightshotParser(
        photosDirectory: photosDirectory,
        databaseDirectory: databaseDirectory,
        downloading: true);
    setState(() {
      _downloading = true;
    });

    parser.parse(numOfImages, newAddresses, startingUrl).then((_) {
      setState(() {
        _downloading = false;
      });
    });
  }

  void _stopDownloading() {
    LightshotParser(
        photosDirectory: photosDirectory,
        databaseDirectory: databaseDirectory,
        downloading: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => SettingsPage(
                    photoDirectory: photosDirectory,
                    databaseDirectory: databaseDirectory,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.settings),
          )
        ],
        title: const Text('Lightshot Parser'),
        centerTitle: true,
      ),
      body: _futureCheck(_mainScreen()),
    );
  }
}
