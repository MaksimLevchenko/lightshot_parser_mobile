import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lightshot_parser_mobile/pages/settings_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view_gallery.dart';

class MainPage extends StatelessWidget {
  MainPage({super.key});

  late int numOfImages;
  late bool newAddresses;
  late String startingUrl;

  Widget _gallery() {
    return Placeholder();
  }

  Future<Directory> _appDocDir = getApplicationDocumentsDirectory();

  void _loadSettings() {
    _appDocDir.then((value) {
      final File file = File('${value.path}/settings.json');
      if (file.existsSync()) {
        final String jsonString = file.readAsStringSync();
        final Map<String, dynamic> settings = json.decode(jsonString);
        //TODO: implement settings
        //numOfImages = int.parse(settings[]);
        //newAddresses = settings[bool.parse(settings['newAddresses'])];
        //startingUrl = settings['startingUrl'];
      } else {
        numOfImages = 10;
        newAddresses = false;
        startingUrl = '';
      }
    });
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
                      builder: (BuildContext context) => SettingsPage()));
            },
            icon: Icon(Icons.settings),
          )
        ],
        title: Text('Lightshot Parser'),
        centerTitle: true,
      ),
      body: SafeArea(
        minimum: EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {},
                child: _gallery(),
              ),
              ElevatedButton(
                onPressed: () {},
                child: Text('Download'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
