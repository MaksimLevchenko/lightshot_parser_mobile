import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lightshot_parser_mobile/pages/settings_page.dart';
import 'package:lightshot_parser_mobile/parser/parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
    return Placeholder();
  }

  Future<Directory> _appDocDir = getApplicationDocumentsDirectory();

  void _loadSettings() {
    _appDocDir.then((value) async {
      final File file = File('${value.path}/lightshot_parser/settings.json');
      if (file.existsSync()) {
        final Future<String> jsonString = file.readAsString();
        final Map<String, dynamic> settings = json.decode(await jsonString);
        numOfImages = int.parse(settings['numOfImages']);
        newAddresses = settings['newAddresses'];
        startingUrl = settings['startingUrl'];
      } else {
        numOfImages = 10;
        newAddresses = false;
        startingUrl = '';
      }
    });
  }

  Widget _futureCheck(Widget child) {
    return FutureBuilder(
      future: Future.wait([downloadDirectoryPath]),
      builder: (BuildContext context, snapshot) {
        _loadSettings();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return Center(
            child: Text('No download folder found'),
          );
        }
        print('${snapshot.data![0]!.path}/LightshotParser/Photos');
        this.photosDirectory =
            Directory('${snapshot.data![0]!.path}/LightshotParser/Photos');
        this.databaseDirectory =
            Directory('${snapshot.data![0]!.path}/LightshotParser/');

        return child;
      },
    );
  }

  Widget _mainScreen() {
    return SafeArea(
      minimum: EdgeInsets.all(16),
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
                    child: Text('Cancel'),
                  )
                : ElevatedButton(
                    onPressed: () {
                      _startDownloading();
                    },
                    child: Text('Download'),
                  ),
          ],
        ),
      ),
    );
  }

  void _startDownloading() {
    _loadSettings();
    LightshotParser parser = LightshotParser(
        photosDirectory: this.photosDirectory,
        databaseDirectory: this.databaseDirectory,
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
        photosDirectory: this.photosDirectory,
        databaseDirectory: this.databaseDirectory,
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
                    photoDirectory: this.photosDirectory,
                    databaseDirectory: this.databaseDirectory,
                  ),
                ),
              );
            },
            icon: Icon(Icons.settings),
          )
        ],
        title: Text('Lightshot Parser'),
        centerTitle: true,
      ),
      body: _futureCheck(_mainScreen()),
    );
  }
}
