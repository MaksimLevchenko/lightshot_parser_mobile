import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lightshot_parser_mobile/pages/photo_page.dart';
import 'package:lightshot_parser_mobile/parser/parser_db.dart';

class GalleryPage extends StatefulWidget {
  final Stream<File> imageStream;

  const GalleryPage({super.key, required this.imageStream});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final DataBase _db = DataBase.getInstance();

  @override
  Widget build(BuildContext context) {
    List<File> images = _db.getFilesListByDate();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
      ),
      body: StreamBuilder<File>(
        stream: widget.imageStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final newImage = snapshot.data!;
            images = [newImage, ...images];
          }
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
                        imageStream: widget.imageStream,
                      ),
                    ),
                  ).then((value) => setState(() {}));
                },
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
              );
            }),
          );
        },
      ),
    );
  }
}
