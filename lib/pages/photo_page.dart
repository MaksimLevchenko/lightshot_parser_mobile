import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class PhotoViewerPage extends StatelessWidget {
  PhotoViewerPage(
      {super.key,
      required this.galleryItems,
      required int startIndex,
      required Stream<File> imageStream})
      : _startIndex = startIndex,
        _imageStream = imageStream,
        currentIndex = startIndex;

  final Stream<File> _imageStream;
  final GlobalKey<State<StatefulWidget>> statefulKey =
      GlobalKey<State<StatefulWidget>>();
  final List<File> galleryItems;
  final int _startIndex;
  int currentIndex;

  Future<bool> saveImage(File image, BuildContext context) async {
    await Permission.manageExternalStorage.request().then((value) {
      if (value.isGranted) {
        final String path = image.path;
        final String fileName = path.substring(path.lastIndexOf('/') + 1);
        final String newPath = '/storage/emulated/0/Download/Parser/$fileName';
        final Directory downloadDir =
            Directory('/storage/emulated/0/Download/Parser');
        downloadDir.createSync(recursive: true);
        image.copy(newPath).then((value) {
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
                log('${galleryItems.length}');
                image.deleteSync();
                galleryItems.removeAt(currentIndex);
                statefulKey.currentState!.setState(() {});
                log('${galleryItems.length}');
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
      backgroundColor: Colors.white70,
      appBar: AppBar(
        title: const Text('Photo Viewer'),
        actions: [
          IconButton(
            onPressed: () {
              saveImage(galleryItems[currentIndex], context);
            },
            icon: const Icon(Icons.download),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share),
          ),
          IconButton(
            onPressed: () {
              deleteImage(galleryItems[currentIndex], context);
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
                  imageProvider: FileImage(galleryItems[index]),
                  initialScale: PhotoViewComputedScale.contained * 0.9,
                  maxScale: PhotoViewComputedScale.contained * 3.0,
                  minScale: PhotoViewComputedScale.contained * 0.8,
                );
              },
              itemCount: galleryItems.length,
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
