import 'dart:developer' show log;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:lightshot_parser_mobile/pages/main_page.dart';
import "dart:core";
import 'parser_db.dart' as db;

class CouldntConnectException implements Exception {
  String cause;
  CouldntConnectException(this.cause);
}

class CancelledByUserException implements Exception {
  String cause;
  CancelledByUserException(this.cause);
}

class NoPhotoException implements Exception {
  String cause;
  NoPhotoException(this.cause);
}

class LightshotParser {
  bool alreadyExists = false;
  late final db.DataBase database;
  late final Directory photosDirectory;
  late final Directory databaseDirectory;
  static final LightshotParser _instance = LightshotParser._();
  final Dio userClient = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 7),
  ));

  LightshotParser._();

  factory LightshotParser(
      {required Directory photosDirectory,
      required Directory databaseDirectory}) {
    if (_instance.alreadyExists == true) {
      log("The instance of LightshotParser already exists");
    } else {
      _instance.userClient.interceptors
          .add(InterceptorsWrapper(onRequest: (options, handler) {
        options.headers['User-Agent'] =
            'Mozilla/5.0 (X11; Linux x86_64; rv:78.0) Gecko/20100101 Firefox/78.0';
        return handler.next(options);
      }));
      if (!photosDirectory.existsSync()) {
        photosDirectory.createSync(recursive: true);
      }
      _instance.photosDirectory = photosDirectory;
      log('photo dir: ${_instance.photosDirectory.toString()}');
      _instance.databaseDirectory = databaseDirectory;
      _instance.database = db.DataBase(
          databaseFileDirectory: databaseDirectory,
          photosDirectory: photosDirectory);
      _instance.alreadyExists = true;
      log('The instance of LightshotParser created successfuly');
    }
    return _instance;
  }

  ///downloading image from {prnt.sc} url
  Future<File> getImage(Uri url) async {
    late final Response<dynamic> responseFromSite;
    try {
      responseFromSite = await userClient.getUri(url);
    } catch (e) {
      throw CouldntConnectException('No vpn');
    }
    final RegExp imgPattern = RegExp(r'https.*((png)|(jpg)|(jpeg))');

    // switch (responseFromSite.statusCode) {
    //   case 503:
    //     throw CouldntConnectException('Server wants to ban this IP');
    //   case 403:
    //     throw CouldntConnectException('IP got banned');
    //   case 200:
    //     break;
    // }
    final sourceCode = responseFromSite.data.toString();

    //looking for a direct address to the file
    var imageStringUrl = imgPattern.stringMatch(sourceCode);

    if (imageStringUrl == null) {
      throw NoPhotoException("The photo is missing");
    }

    //Cutting the image url after .jpg or .png
    imageStringUrl = imageStringUrl.substring(0, imageStringUrl.indexOf('"'));

    if (!imageStringUrl.contains(imgPattern)) {
      throw NoPhotoException("The photo is missing");
    }

    // var imageUrl = Uri.parse(imageStringUrl);
    // final responseFromImg = await userClient.getUri(imageUrl);

    // if (responseFromImg.statusCode != 200) {
    //   throw NoPhotoException(
    //       "The photo is missing with ${responseFromImg.statusCode}");
    // }

    //We filter out the imgur stubs that have 503 bites size
    // if (responseFromImg.data.bodyBytes.length == 503) {
    //   throw NoPhotoException("The photo $imageStringUrl is imgur stub");
    // }

    // //Download the photo
    // File downloadedFile = await File("${photosDirectory.path}/"
    //         '${url.pathSegments[url.pathSegments.length - 1]}'
    //         '${imageStringUrl.substring(imageStringUrl.lastIndexOf('.'))}')
    //     .writeAsBytes(responseFromImg.bodyBytes);

    final filePath = "${photosDirectory.path}/"
        '${url.pathSegments[url.pathSegments.length - 1]}'
        '${imageStringUrl.substring(imageStringUrl.lastIndexOf('.'))}';

    try {
      await userClient.download(imageStringUrl, filePath,
          cancelToken: cancelToken);
    } catch (e) {
      if (cancelToken.isCancelled) {
        log('The download of the file $imageStringUrl was canceled');
        throw CancelledByUserException('The download of the file was canceled');
      }
      log('Error while downloading the file $imageStringUrl from $url');
      throw NoPhotoException('No photo');
    }

    File downloadedFile = File(filePath);
    if (await downloadedFile.length() == 503) {
      downloadedFile.deleteSync();
      throw NoPhotoException("The photo $imageStringUrl is imgur stub");
    }

    log('file $imageStringUrl from $url downloaded successful');

    return downloadedFile;
  }

  Future<File?> downloadOneImage(Uri imageUrl) async {
    if (database.urlInDb(imageUrl)) {
      log('The page $imageUrl is already checked');
      return null;
    }
    File downloadedFile = await getImage(imageUrl);
    return downloadedFile;
  }
}
