// ignore_for_file: must_be_immutable, invalid_use_of_protected_member

import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lightshot_parser_mobile/pages/main_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';

class PhotoViewerPage extends StatelessWidget {
  PhotoViewerPage(
      {super.key, required List<File> galleryItems, required int startIndex})
      : _galleryItems = List.from(galleryItems),
        _startIndex = startIndex,
        currentIndex = startIndex;

  final GlobalKey<State<StatefulWidget>> statefulKey =
      GlobalKey<State<StatefulWidget>>();
  final List<File> _galleryItems;
  final int _startIndex;
  int currentIndex;

  bool shareImage(File image, BuildContext context) {
    Share.shareXFiles([XFile(image.path)],
        text: 'Check out this image from Lightshot Parser');
    return true;
  }

  Future<bool> saveImage(File image, BuildContext context) async {
    await Permission.manageExternalStorage.request().then((value) async {
      if (value.isGranted) {
        late final String fileName;
        final String path = image.path;
        if (path.substring(path.lastIndexOf(r'\') + 1).length <
            path.substring(path.lastIndexOf(r'/') + 1).length) {
          fileName = path.substring(path.lastIndexOf(r'\') + 1);
        }
        late final Directory downloadDir;
        if (Platform.isAndroid) {
          downloadDir = Directory('/storage/emulated/0/Download/');
        } else {
          downloadDir = await getDownloadsDirectory() ?? Directory.current;
          log(downloadDir.path);
        }
        final String newPath = '${downloadDir.path}/$fileName';
        downloadDir.createSync(recursive: true);
        await image.copy(newPath).then((value) {
          ScaffoldMessenger.of(context).showSnackBar(
            _getSnackBar(
              message: 'Image saved to $newPath',
            ),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          _getSnackBar(
            message: 'Permission denied',
            color: Colors.red,
          ),
        );
        return false;
      }
    });
    return true;
  }

  bool deleteImage(File image, BuildContext context) {
    bool isImageDeleted = false;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this image?'),
          actions: [
            TextButton(
              onPressed: () {
                isImageDeleted = false;
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                isImageDeleted = true;
                log('${_galleryItems.length}');
                image.deleteSync();
                _galleryItems.removeAt(currentIndex);
                statefulKey.currentState!.setState(() {});
                log('${_galleryItems.length}');
                needToUpdateGallery = true;
                Navigator.of(context).pop(); // Close the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  _getSnackBar(
                    message: 'Image deleted',
                  ),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return isImageDeleted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Viewer'),
        actions: [
          IconButton(
            onPressed: () {
              saveImage(_galleryItems[currentIndex], context);
            },
            icon: const Icon(Icons.download),
          ),
          IconButton(
            onPressed: () {
              shareImage(_galleryItems[currentIndex], context);
            },
            icon: const Icon(Icons.share),
          ),
          IconButton(
            onPressed: () {
              deleteImage(_galleryItems[currentIndex], context);
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: StatefulBuilder(
          key: statefulKey,
          builder: (context, setState) {
            return PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: FileImage(_galleryItems[index]),
                  initialScale: PhotoViewComputedScale.contained * 1,
                  maxScale: PhotoViewComputedScale.contained * 4.0,
                  minScale: PhotoViewComputedScale.contained * 1,
                );
              },
              itemCount: _galleryItems.length,
              loadingBuilder: (context, event) => Center(
                child: SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(
                    value: event == null
                        ? 0
                        : event.cumulativeBytesLoaded /
                            event.expectedTotalBytes!,
                  ),
                ),
              ),
              backgroundDecoration: const BoxDecoration(color: Colors.white70),
              pageController: PageController(initialPage: _startIndex),
              onPageChanged: (index) {
                currentIndex = index;
              },
            );
          }),
    );
  }

  SnackBar _getSnackBar({required String message, Color color = Colors.green}) {
    return SnackBar(
      content: Center(child: Text(message)),
      duration: const Duration(seconds: 2),
      backgroundColor: color,
    );
  }
}
