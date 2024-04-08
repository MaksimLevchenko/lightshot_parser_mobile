import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' hide log;
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:lightshot_parser_mobile/pages/settings_page.dart';
import 'package:lightshot_parser_mobile/parser/parser.dart';
import 'package:lightshot_parser_mobile/parser/parser_db.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lightshot_parser_mobile/parser/url_generator.dart' as gen;

const _imageSize = 300.0;

class MainPage extends StatelessWidget {
  final Future<Directory> _appDocDir = getApplicationDocumentsDirectory();
  final Future<Directory?> _downloadDirectoryPath = getDownloadsDirectory();
  late Directory _photosDirectory;
  late Directory _databaseDirectory;
  late Directory _settingsDirectory;
  double _progress = 0;
  final galleryKey = GlobalKey();

  bool _downloading = false;
  late int wantedNumOfImages;
  late bool newAddresses;
  late String startingUrl;

  MainPage({super.key});

  Future<bool> _beginDownloading(
      BuildContext context, Function setState) async {
    _loadSettings(_settingsDirectory);
    var generator = startingUrl == ''
        ? gen.GetRandomUrl(newAddresses)
        : gen.GetNextUrl(newAddresses, startingUrl);
    LightshotParser parser = LightshotParser(
        photosDirectory: _photosDirectory,
        databaseDirectory: _databaseDirectory);
    _downloading = true;
    File? downloadedPhoto;
    for (int numOfDownloadedImages = 0;
        numOfDownloadedImages < wantedNumOfImages;) {
      if (_downloading == false) break;
      try {
        downloadedPhoto = await parser.downloadOneImage(generator.current);
        if (downloadedPhoto != null) {
          numOfDownloadedImages++;
        }
        parser.database.addUrlRecord(generator.current);
        generator.moveNext();
      } on CouldntConnectException {
        log('Coudnt connect to server');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(_getSnackBar(
            message: 'Download error. Try to change VPN',
            color: Colors.red,
          ));
        }
        setState(() {
          _downloading = false;
          _progress = 0;
        });
        return false;
      } on NoPhotoException {
        log('no photo on ${generator.current}');
        parser.database.addUrlRecord(generator.current);
        generator.moveNext();
      } catch (e) {
        log(e.toString());
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _getSnackBar(
              message: 'Unknown error: $e, please contact to the dev',
              color: Colors.red,
            ),
          );
        }
        setState(() {
          _downloading = false;
          _progress = 0;
        });
        return false;
      }
      setState(() {
        _progress = numOfDownloadedImages / wantedNumOfImages;
      });
    }
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _downloading = false;
      _progress = 0;
    });
    return true;
  }

  void _stopDownloading() {
    _downloading = false;
    _progress = 0;
  }

  SnackBar _getSnackBar({required String message, Color color = Colors.green}) {
    return SnackBar(
      content: Center(child: Text(message)),
      duration: const Duration(seconds: 2),
      backgroundColor: color,
    );
  }

  void _loadSettings(Directory settingsDir) {
    final File file =
        File('${settingsDir.path}/lightshot_parser/settings.json');
    if (file.existsSync()) {
      final String jsonString = file.readAsStringSync();
      final Map<String, dynamic> settings = json.decode(jsonString);
      wantedNumOfImages = (settings['numOfImages']);
      newAddresses = settings['newAddresses'];
      startingUrl = settings['startingUrl'];
    } else {
      wantedNumOfImages = 10;
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
          return child(context);
        }

        return const Center(
          child: Text('No download folder found'),
        );
      },
    );
  }

  Widget _mainScreen(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  galleryKey.currentState!.setState(() {});
                },
                icon: const Icon(Icons.refresh),
                color: Colors.pink,
              ),
              const Expanded(child: SizedBox()),
              TextButton(
                onPressed: () {},
                child: const Text('See all'),
              ),
            ],
          ),
          StatefulBuilder(
              key: galleryKey,
              builder: (context, setState) {
                return SizedBox(
                  width: double.infinity,
                  height: _imageSize,
                  child: _GalleryBuilder(
                      photosDirectory: _photosDirectory,
                      databaseDirectory: _databaseDirectory),
                );
              }),
          const SizedBox(height: 16),
          StatefulBuilder(builder: (context, setState) {
            return Column(
              children: [
                _downloading
                    ? Column(
                        children: [
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            tween: Tween<double>(
                              begin: 0,
                              end: _progress,
                            ),
                            builder: (context, value, _) =>
                                LinearProgressIndicator(value: value),
                          ),
                          const SizedBox(height: 10),
                          Text(
                              'Downloaded ${(_progress * wantedNumOfImages).round()} of $wantedNumOfImages'),
                          const SizedBox(height: 20)
                        ],
                      )
                    : const SizedBox(height: 50),
                _downloading
                    ? ElevatedButton(
                        onPressed: () => setState(() {
                          _stopDownloading();
                        }),
                        child: const Text('Cancel'),
                      )
                    : ElevatedButton(
                        onPressed: () => setState(() {
                          _beginDownloading(context, setState);
                        }),
                        child: const Text('Download'),
                      ),
              ],
            );
          }),
        ],
      ),
    );
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
    DataBase db = DataBase(
        photosDirectory: photosDirectory, fileDirectory: databaseDirectory);
    int downloadedPhotosNum = db.numOfDownloadedPhotos();
    if (downloadedPhotosNum > 0) {
      return _GalleryWithPhotos(
          photoDirectory: photosDirectory, numOfPhotos: downloadedPhotosNum);
    }
    return SizedBox(
      width: _imageSize,
      height: _imageSize,
      child: Center(
        child: Card(
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            splashColor: Colors.pink.withAlpha(30),
            onTap: () {},
            child: Center(
              child: Text('No photos'),
            ),
          ),
        ),
      ),
    );
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
            return const CircularProgressIndicator();
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
