import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lightshot_parser_mobile/pages/settings_page.dart';
import 'package:lightshot_parser_mobile/parser/parser.dart';
import 'package:lightshot_parser_mobile/parser/parser_db.dart';
import 'package:path_provider/path_provider.dart';

const _imageSize = 300.0;

class MainPage extends StatelessWidget {
  final Future<Directory> _appDocDir = getApplicationDocumentsDirectory();
  final Future<Directory?> _downloadDirectoryPath = getDownloadsDirectory();
  late Directory _photosDirectory;
  late Directory _databaseDirectory;
  late Directory _settingsDirectory;

  bool _downloading = false;
  late int numOfImages;
  late bool newAddresses;
  late String startingUrl;

  MainPage({super.key});

  void _loadSettings(Directory settingsDir) {
    final File file =
        File('${settingsDir.path}/lightshot_parser/settings.json');
    if (file.existsSync()) {
      final String jsonString = file.readAsStringSync();
      final Map<String, dynamic> settings = json.decode(jsonString);
      numOfImages = settings['numOfImages'];
      newAddresses = settings['newAddresses'];
      startingUrl = settings['startingUrl'];
    } else {
      numOfImages = 10;
      newAddresses = false;
      startingUrl = '';
    }
  }

  Widget _waitForDirectories(Function child) {
    return FutureBuilder(
      future: Future.wait([_downloadDirectoryPath, _appDocDir]),
      builder: (BuildContext context, snapshot) {
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
        if (snapshot.connectionState == ConnectionState.done) {
          _databaseDirectory = snapshot.data![0]!;
          _photosDirectory = Directory(_databaseDirectory.path + r'/Photos');
          _settingsDirectory = snapshot.data![1]!;
          _loadSettings(_settingsDirectory);
          return child();
        }

        return const Center(
          child: Text('No download folder found'),
        );
      },
    );
  }

  Widget _mainScreen() {
    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.refresh),
                color: Colors.pink,
              ),
              const Expanded(child: SizedBox()),
              TextButton(
                onPressed: () {},
                child: Text('See all'),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            height: _imageSize,
            child: _GalleryBuilder(
                photosDirectory: _photosDirectory,
                databaseDirectory: _databaseDirectory),
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
    );
  }

  void _startDownloading() {
    _loadSettings(_settingsDirectory);
    LightshotParser parser = LightshotParser(
        photosDirectory: _photosDirectory,
        databaseDirectory: _databaseDirectory,
        downloading: true);
    _downloading = true;
    parser.parse(numOfImages, newAddresses, startingUrl).then((_) {
      _downloading = false;
    });
  }

  void _stopDownloading() {
    LightshotParser(
        photosDirectory: _photosDirectory,
        databaseDirectory: _databaseDirectory,
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
                    photoDirectory: _photosDirectory,
                    databaseDirectory: _databaseDirectory,
                    settingsDirectory: _settingsDirectory,
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
      body: _waitForDirectories(
        _mainScreen,
      ),
    );
  }
}

class _GalleryBuilder extends StatelessWidget {
  const _GalleryBuilder({
    required this.photosDirectory,
    required this.databaseDirectory,
  });

  final Directory photosDirectory;
  final Directory databaseDirectory;

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      DataBase db = DataBase(
          photosDirectory: photosDirectory, fileDirectory: databaseDirectory);
      int downloadedPhotosNum = db.numOfDownloadedPhotos();
      if (downloadedPhotosNum > 0) {
        return _GalleryWithPhotos(
            photoDirectory: photosDirectory, numOfPhotos: downloadedPhotosNum);
      }
      return Container(
        width: _imageSize,
        height: _imageSize,
        child: Center(child: Text('NoPhoto')),
      );
    });
  }
}

class _GalleryWithPhotos extends StatelessWidget {
  const _GalleryWithPhotos({
    required this.photoDirectory,
    required this.numOfPhotos,
  });

  final Directory photoDirectory;
  final int numOfPhotos;

  Future<List<File>> _getFilesListByDate(Directory directory) async {
    List<FileSystemEntity> entities = directory.listSync();

    entities.sort((FileSystemEntity first, FileSystemEntity second) {
      FileStat statFirst = first.statSync();
      FileStat statSecond = second.statSync();
      return statSecond.modified.compareTo(statFirst.modified);
    });

    return entities.cast();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<File>>(
        future: _getFilesListByDate(photoDirectory),
        builder: (context, snapshot) {
          if (snapshot.hasData == false) {
            return CircularProgressIndicator();
          }
          return ListView.separated(
            itemCount: min(15, numOfPhotos),
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            separatorBuilder: (context, index) {
              return const SizedBox(
                width: 10,
              );
            },
            itemBuilder: (context, index) {
              return Container(
                width: _imageSize,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    color: Colors.grey),
                child: Image.file(snapshot.data![index]),
              );
            },
            scrollDirection: Axis.horizontal,
          );
        });
  }
}
