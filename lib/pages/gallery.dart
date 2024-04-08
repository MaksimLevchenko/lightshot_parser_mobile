import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lightshot_parser_mobile/parser/parser_db.dart';

class GalleryPage extends StatelessWidget {
  final Stream<File> imageStream;
  final DataBase _db = DataBase.getInstance();

  GalleryPage({super.key, required this.imageStream});

  @override
  Widget build(BuildContext context) {
    List<File> images = _db.getFilesListByDate();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
      ),
      body: StreamBuilder<File>(
        stream: imageStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final newImage = snapshot.data!;
            images = [newImage, ...images];
          }
          return GridView.count(
            crossAxisCount: 3,
            children: List.generate(images.length, (index) {
              //TODO implements photo viewer
              return GestureDetector(
                onTap: () {},
                child: InkWell(
                  onTap: () {},
                  child: Image.file(
                    images[index],
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded) {
                        return child;
                      }
                      return AnimatedOpacity(
                        child: child,
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(seconds: 1),
                        curve: Curves.easeOut,
                      );
                    },
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}