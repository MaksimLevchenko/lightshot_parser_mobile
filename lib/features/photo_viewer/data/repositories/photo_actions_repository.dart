import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lightshot_parser_mobile/core/errors/app_exception.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';

class PhotoActionsRepository {
  PhotoActionsRepository(this._galleryRepository);

  static const MethodChannel _androidDownloadsChannel = MethodChannel(
    'com.valvekat.lightshotParserMobile/downloads',
  );

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
      return _saveImageOnAndroid(item);
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

  Future<String> _saveImageOnAndroid(GalleryItem item) async {
    final sdkInt = await _getAndroidSdkInt();
    if (sdkInt < 29) {
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        throw const StorageException('permission-denied');
      }
    }

    try {
      final savedPath = await _androidDownloadsChannel.invokeMethod<String>(
        'saveImageToDownloads',
        <String, String>{
          'sourcePath': item.path,
          'fileName': item.path.split(Platform.pathSeparator).last,
        },
      );

      if (savedPath == null || savedPath.isEmpty) {
        throw const StorageException('download-dir-missing');
      }

      return savedPath;
    } on PlatformException catch (error) {
      if (error.code == 'permission-denied') {
        throw const StorageException('permission-denied');
      }
      if (error.code == 'source-missing') {
        throw const StorageException();
      }
      throw StorageException(error.message ?? 'Storage operation failed');
    }
  }

  Future<int> _getAndroidSdkInt() async {
    final sdkInt = await _androidDownloadsChannel.invokeMethod<int>(
      'getAndroidSdkInt',
    );
    return sdkInt ?? 0;
  }
}
