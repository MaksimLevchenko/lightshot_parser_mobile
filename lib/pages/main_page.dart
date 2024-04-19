// ignore_for_file: must_be_immutable, invalid_use_of_protected_member

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' hide log;
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:lightshot_parser_mobile/generated/l10n.dart';
import 'package:lightshot_parser_mobile/pages/gallery.dart';
import 'package:lightshot_parser_mobile/pages/photo_page.dart';
import 'package:lightshot_parser_mobile/pages/settings_page.dart';
import 'package:lightshot_parser_mobile/parser/parser.dart';
import 'package:lightshot_parser_mobile/parser/parser_db.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lightshot_parser_mobile/parser/url_generator.dart' as gen;
import "package:dio/dio.dart";

const _imageSize = 300.0;
bool needToUpdateGallery = false;
var cancelToken = CancelToken();

class MainPage extends StatelessWidget {
  final Future<Directory> _appDocDir = getApplicationDocumentsDirectory();
  final Future<Directory?> _downloadDirectoryPath =
      getApplicationCacheDirectory();
  late Directory _photosDirectory;
  late Directory _databaseDirectory;
  late Directory _settingsDirectory;
  bool downloading = false;
  double _progress = 0;
  final StreamController<File> _imagesStream =
      StreamController<File>.broadcast();

  late int _wantedNumOfImages;
  late bool _newAddresses;
  late String _startingUrl;
  late bool _useProxy;
  late bool _useProxyAuth;
  late String _proxyAddress;
  late String _proxyPort;
  late String _proxyLogin;
  late String _proxyPassword;

  MainPage({super.key});

  Future<bool> _beginDownloading(
      BuildContext context, Function setProgressBarState) async {
    _loadSettings(_settingsDirectory);
    var generator = _startingUrl == ''
        ? gen.GetRandomUrl(_newAddresses)
        : gen.GetNextUrl(_newAddresses, _startingUrl);
    String? proxy;
    if (_useProxy) {
      if (_useProxyAuth) {
        proxy = 'PROXY $_proxyLogin:$_proxyPassword@$_proxyAddress:$_proxyPort';
      } else {
        proxy = 'PROXY $_proxyAddress:$_proxyPort';
      }
    }
    LightshotParser parser = LightshotParser(
        photosDirectory: _photosDirectory,
        databaseDirectory: _databaseDirectory,
        proxy: proxy);
    downloading = true;
    cancelToken = CancelToken();
    File? downloadedPhoto;
    int numOfDownloadedImages = 0;
    setProgressBarState(() {
      _progress = 0;
      numOfDownloadedImages = 0;
    });
    for (numOfDownloadedImages; numOfDownloadedImages < _wantedNumOfImages;) {
      if (downloading == false) break;
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
          ScaffoldMessenger.of(context).showSnackBar(getSnackBar(
            message: S.of(context).downloadErrorTryToChangeVpn,
            color: Colors.red,
          ));
        }
        setProgressBarState(() {
          downloading = false;
          _progress = 0;
        });
        return false;
      } on NoPhotoException {
        log('no photo on ${generator.current}');
        parser.database.addUrlRecord(generator.current);
        generator.moveNext();
      } on CancelledByUserException {
        log('Download cancelled by user');
        return false;
      } catch (e) {
        log(e.toString());
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            getSnackBar(
              message: S.of(context).unknownErrorEPleaseContactToTheDev(e),
              color: Colors.red,
            ),
          );
        }
        setProgressBarState(() {
          downloading = false;
          _progress = 0;
        });
        return false;
      }
      setProgressBarState(() {
        _progress = numOfDownloadedImages / _wantedNumOfImages;
      });
    }
    if (downloading) await Future.delayed(const Duration(milliseconds: 500));
    setProgressBarState(() {
      downloading = false;
      _progress = 0;
    });
    return true;
  }

  void _stopDownloading() {
    downloading = false;
    cancelToken.cancel();
  }

  void _loadSettings(Directory settingsDir) {
    final File file =
        File('${settingsDir.path}/lightshot_parser/settings.json');
    if (file.existsSync()) {
      final String jsonString = file.readAsStringSync();
      final Map<String, dynamic> settings = json.decode(jsonString);
      try {
        _wantedNumOfImages = (settings['numOfImages']) ?? 10;
        _newAddresses = settings['newAddresses'] ?? false;
        _startingUrl = settings['startingUrl'] ?? '';
        _useProxy = settings['useProxy'] ?? false;
        _useProxyAuth = settings['useProxyAuth'] ?? false;
        _proxyAddress = settings['proxyAddress'] ?? '';
        _proxyPort = settings['proxyPort'] ?? '';
        _proxyLogin = settings['proxyLogin'] ?? '';
        _proxyPassword = settings['proxyPassword'] ?? '';
      } on Exception catch (e) {
        log('Error while loading settings: $e');
        _wantedNumOfImages = 10;
        _newAddresses = false;
        _startingUrl = '';
        _useProxy = settings['useProxy'] ?? false;
        _useProxyAuth = settings['useProxyAuth'] ?? false;
        _proxyAddress = settings['proxyAddress'] ?? '';
        _proxyPort = settings['proxyPort'] ?? '';
        _proxyLogin = settings['proxyLogin'] ?? '';
        _proxyPassword = settings['proxyPassword'] ?? '';
      }
    } else {
      _wantedNumOfImages = 10;
      _newAddresses = false;
      _startingUrl = '';
      _useProxy = false;
      _useProxyAuth = false;
      _proxyAddress = '';
      _proxyPort = '';
      _proxyLogin = '';
      _proxyPassword = '';
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
            child: Text(S.of(context).errorError(snapshot.error!)),
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          _databaseDirectory = snapshot.data![1]!;
          _photosDirectory = Directory(snapshot.data![0]!.path + r'/Photos');
          DataBase(
            databaseFileDirectory: _databaseDirectory,
            photosDirectory: _photosDirectory,
          );
          log('${_databaseDirectory.path} is database path');
          _settingsDirectory = snapshot.data![1]!;
          _loadSettings(_settingsDirectory);
          return child(context);
        }

        return Center(
          child: Text(S.of(context).noDownloadFolderFound),
        );
      },
    );
  }

  Widget _mainScreen(BuildContext context) {
    return SingleChildScrollView(
      child: SafeArea(
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
                    ).then((_) {
                      needToUpdateGallery
                          ? _galleryStatefulKey.currentState?.setState(() {
                              _galleryStatefulKey.currentState
                                  ?._updateGalleryList();
                            })
                          : null;
                      needToUpdateGallery = false;
                    });
                  },
                  child: Text(S.of(context).seeAll),
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
            StatefulBuilder(builder: (context, setProgressBarState) {
              return Column(
                children: [
                  downloading
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
                            Text(S
                                .of(context)
                                .downloadedImagesOfWantednumofimages(
                                    (_progress * _wantedNumOfImages).round(),
                                    _wantedNumOfImages)),
                            const SizedBox(height: 20)
                          ],
                        )
                      : const SizedBox(height: 50),
                  downloading
                      ? ElevatedButton(
                          onPressed: () => setProgressBarState(() {
                            _stopDownloading();
                          }),
                          child: Text(S.of(context).cancel),
                        )
                      : ElevatedButton(
                          onPressed: () => setProgressBarState(() {
                            _beginDownloading(context, setProgressBarState);
                          }),
                          child: Text(S.of(context).download),
                        ),
                ],
              );
            }),
          ],
        ),
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
                        )),
              ).then((_) {
                needToUpdateGallery
                    ? _galleryStatefulKey.currentState?.setState(() {
                        _galleryStatefulKey.currentState?._updateGalleryList();
                      })
                    : null;
                needToUpdateGallery = false;
              });
            },
            icon: const Icon(Icons.settings),
          )
        ],
        title: Text(S.of(context).mainTitle),
        centerTitle: true,
      ),
      body: _createDatabaseAndFindFolders(
        _mainScreen,
      ),
    );
  }
}

final GlobalKey<__RowBuilderState> _galleryStatefulKey =
    GlobalKey<__RowBuilderState>();

class _GalleryBuilder extends StatelessWidget {
  _GalleryBuilder({
    required Stream<File> imagesStream,
  }) : _imagesStream = imagesStream;
  final Stream<File> _imagesStream;

  final DataBase _db = DataBase.getInstance();

  Widget _photoRow() {
    List<File> photosByDate = _db.getFilesListByDate();
    photosByDate.removeRange(min(15, photosByDate.length), photosByDate.length);
    _imagesStream.listen((event) {
      photosByDate.insert(0, event);
      _galleryStatefulKey.currentState?.setState(() {
        _galleryStatefulKey.currentState?._updateGalleryList();
      });
    });
    return _RowBuilder(
      key: _galleryStatefulKey,
      photosByDate: photosByDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _photoRow();
  }
}

SnackBar getSnackBar({required String message, Color color = Colors.green}) {
  return SnackBar(
    content: Center(child: Text(message)),
    duration: const Duration(seconds: 2),
    backgroundColor: color,
  );
}

class _RowBuilder extends StatefulWidget {
  _RowBuilder({super.key, required this.photosByDate});
  List<File> photosByDate;

  @override
  State<_RowBuilder> createState() => __RowBuilderState();
}

class __RowBuilderState extends State<_RowBuilder> {
  void setList(List<File> newPhotos) {
    widget.photosByDate = newPhotos;
  }

  void _updateGalleryList() {
    widget.photosByDate = DataBase.getInstance().getFilesListByDate();
    widget.photosByDate.removeRange(
        min(15, widget.photosByDate.length), widget.photosByDate.length);
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      int numOfPhotos = widget.photosByDate.length;
      if (numOfPhotos == 0) {
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
                child: Center(
                  child: Text(S.of(context).noPhotos),
                ),
              ),
            ),
          ),
        );
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => PhotoViewerPage(
                      galleryItems: widget.photosByDate,
                      startIndex: index,
                    ),
                  ),
                ).then((_) {
                  needToUpdateGallery
                      ? _galleryStatefulKey.currentState?.setState(() {
                          _galleryStatefulKey.currentState
                              ?._updateGalleryList();
                        })
                      : null;
                  needToUpdateGallery = false;
                });
              },
              onLongPress: () {},
              child: Container(
                padding: const EdgeInsets.all(16),
                width: _imageSize,
                child: Image.file(
                  widget.photosByDate[index],
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) {
                      return child;
                    }
                    return AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      child: child,
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
}
