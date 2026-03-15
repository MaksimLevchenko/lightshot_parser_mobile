import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lightshot_parser_mobile/core/errors/app_exception.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';

class PhotoActionsRepository {
  PhotoActionsRepository(this._galleryRepository);

  final GalleryRepository _galleryRepository;

  Future<void> shareImage(GalleryItem item, String text) {
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile(item.path)],
        text: text,
      ),
    );
  }

  Future<String> saveImage(GalleryItem item) async {
    if (Platform.isAndroid) {
      final permission = await Permission.manageExternalStorage.request();
      if (!permission.isGranted) {
        throw const StorageException('permission-denied');
      }
      final downloadDir = Directory('/storage/emulated/0/Download');
      return _galleryRepository.saveImageToDownloads(item, downloadDir);
    }

    final downloadDir = await getDownloadsDirectory();
    if (downloadDir == null) {
      throw const StorageException('download-dir-missing');
    }
    return _galleryRepository.saveImageToDownloads(item, downloadDir);
  }

  Future<void> deleteImage(GalleryItem item) {
    return _galleryRepository.deleteItem(item);
  }
}
