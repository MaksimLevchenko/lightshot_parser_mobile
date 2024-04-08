import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' hide log;
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:lightshot_parser_mobile/pages/gallery.dart';
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
  final StreamController<File> _imagesStream =
      StreamController<File>.broadcast();

  bool _downloading = false;
  late int _wantedNumOfImages;
  late bool _newAddresses;
  late String _startingUrl;

  MainPage({super.key});

  Future<bool> _beginDownloading(
      BuildContext context, Function setState) async {
    _loadSettings(_settingsDirectory);
    var generator = _startingUrl == ''
        ? gen.GetRandomUrl(_newAddresses)
        : gen.GetNextUrl(_newAddresses, _startingUrl);
    LightshotParser parser = LightshotParser(
        photosDirectory: _photosDirectory,
        databaseDirectory: _databaseDirectory);
    _downloading = true;
    File? downloadedPhoto;
    for (int numOfDownloadedImages = 0;
        numOfDownloadedImages < _wantedNumOfImages;) {
      if (_downloading == false) break;
      try {
        downloadedPhoto = await parser.downloadOneImage(generator.current);
        if (downloadedPhoto != null) {
          numOfDownloadedImages++;
          _imagesStream.add(downloadedPhoto);
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
        _progress = numOfDownloadedImages / _wantedNumOfImages;
      });
    }
    if (_downloading) await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _downloading = false;
      _progress = 0;
    });
    return true;
  }

  void _stopDownloading() {
    _downloading = false;
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
      _wantedNumOfImages = (settings['numOfImages']);
      _newAddresses = settings['newAddresses'];
      _startingUrl = settings['startingUrl'];
    } else {
      _wantedNumOfImages = 10;
      _newAddresses = false;
      _startingUrl = '';
    }
  }

  Widget _createDatabaseAndFindFolders(Function child) {
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
          DataBase(
            fileDirectory: _databaseDirectory,
            photosDirectory: _photosDirectory,
          );
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
              const Expanded(child: SizedBox()),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => GalleryPage(
                        imageStream: _imagesStream.stream,
                      ),
                    ),
                  );
                },
                child: const Text('See all'),
              ),
            ],
          ),
          // Gallery widget
          SizedBox(
            width: double.infinity,
            height: _imageSize,
            child: _GalleryBuilder(
              imagesStream: _imagesStream.stream,
            ),
          ),
          const SizedBox(height: 16),
          // Download button and progress bar
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
                              'Downloaded ${(_progress * _wantedNumOfImages).round()} of $_wantedNumOfImages'),
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
      body: _createDatabaseAndFindFolders(
        _mainScreen,
      ),
    );
  }
}

class _GalleryBuilder extends StatelessWidget {
  _GalleryBuilder({
    required Stream<File> imagesStream,
  }) : _imagesStream = imagesStream;
  final Stream<File> _imagesStream;
  final DataBase _db = DataBase.getInstance();

  Widget _photoRow(int numOfPhotos) {
    final photosByDate = _db.getFilesListByDate();
    return StreamBuilder<File>(
        stream: _imagesStream,
        builder: (context, streamSnapshot) {
          if (streamSnapshot.hasData) {
            photosByDate.insert(0, streamSnapshot.data!);
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
              return Card(
                color: Colors.white70,
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  splashColor: Colors.pink.withAlpha(30),
                  onTap: () {},
                  onLongPress: () {},
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    width: _imageSize,
                    child: Image.file(
                      photosByDate[index],
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded) {
                          return child;
                        }
                        return AnimatedOpacity(
                          child: child,
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(microseconds: 500),
                          curve: Curves.easeOut,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            scrollDirection: Axis.horizontal,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    int downloadedPhotosNum = _db.numOfDownloadedPhotos();
    if (downloadedPhotosNum > 0) {
      return _photoRow(downloadedPhotosNum);
    }
    return SizedBox(
      width: _imageSize,
      height: _imageSize,
      child: Center(
        child: Card(
          color: Colors.white70,
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            splashColor: Colors.pink.withAlpha(30),
            onTap: () {},
            onLongPress: () {},
            child: const Center(
              child: Text('No photos'),
            ),
          ),
        ),
      ),
    );
  }
}
