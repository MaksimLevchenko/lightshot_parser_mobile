import 'dart:io';

import 'package:equatable/equatable.dart';

class GalleryItem extends Equatable {
  const GalleryItem({
    required this.path,
    required this.id,
  });

  final String path;
  final String id;

  File get file => File(path);

  factory GalleryItem.fromFile(File file) {
    final fileName = file.uri.pathSegments.last;
    final dotIndex = fileName.lastIndexOf('.');
    final id = dotIndex == -1 ? fileName : fileName.substring(0, dotIndex);
    return GalleryItem(path: file.path, id: id);
  }

  @override
  List<Object?> get props => [path, id];
}
