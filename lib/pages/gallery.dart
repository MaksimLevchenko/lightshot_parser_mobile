// ignore_for_file: invalid_use_of_protected_member

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lightshot_parser_mobile/pages/photo_page.dart';
import 'package:lightshot_parser_mobile/parser/parser_db.dart';

class GalleryPage extends StatelessWidget {
  final Stream<File> imageStream;
  final GlobalKey<State<StatefulWidget>> galleryKey =
      GlobalKey<State<StatefulWidget>>();
  GalleryPage({super.key, required this.imageStream});

  final DataBase _db = DataBase.getInstance();

  @override
  Widget build(BuildContext context) {
    List<File> images = _db.getFilesListByDate();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
      ),
      body: Builder(builder: (context) {
        imageStream.listen((event) {
          images.insert(0, event);
          galleryKey.currentState?.setState(() {});
        });
        return StatefulBuilder(
            key: galleryKey,
            builder: (context, setGalleryState) {
              return GridView.count(
                crossAxisCount: 3,
                children: List.generate(images.length, (index) {
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => PhotoViewerPage(
                            galleryItems: images,
                            startIndex: index,
                          ),
                        ),
                      ).then((value) => setGalleryState(() {
                            images = _db.getFilesListByDate();
                          }));
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white70,
                      ),
                      padding: const EdgeInsets.all(8.0),
                      child: Image.file(
                        images[index],
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
                  );
                }),
              );
            });
      }),
    );
  }
}
