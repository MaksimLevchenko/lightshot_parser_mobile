import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import "dart:core";
import 'parser_db.dart' as db;

class CouldntConnectException implements Exception {
  String cause;
  CouldntConnectException(this.cause);
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
  final HttpClient userClient = HttpClient();

  LightshotParser._();

  factory LightshotParser(
      {required Directory photosDirectory,
      required Directory databaseDirectory}) {
    if (_instance.alreadyExists == true) {
      log("The instance of LightshotParser already exists");
    } else {
      // It is necessary in order not to be banned immediately
      _instance.userClient.userAgent =
          'Mozilla/5.0 (X11; Linux x86_64; rv:78.0) Gecko/20100101 Firefox/78.0';
      _instance.userClient.idleTimeout = const Duration(seconds: 5);
      _instance.userClient.connectionTimeout = const Duration(seconds: 5);
      _instance.userClient.maxConnectionsPerHost = 1;
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
    late final HttpClientResponse responseFromSite;
    try {
      responseFromSite = await (await userClient.getUrl(url)).close();
    } catch (e) {
      throw CouldntConnectException('No vpn');
    }
    final RegExp imgPattern = RegExp(r'https.*((png)|(jpg)|(jpeg))');

    switch (responseFromSite.statusCode) {
      case 503:
        throw CouldntConnectException('Server wants to ban this IP');
      case 403:
        throw CouldntConnectException('IP got banned');
      case 200:
        break;
    }
    final sourceCode = await responseFromSite.transform(utf8.decoder).join();

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

    var imageUrl = Uri.parse(imageStringUrl);
    final responseFromImg = await http.get(imageUrl);

    if (responseFromImg.statusCode != 200) {
      throw NoPhotoException(
          "The photo is missing with ${responseFromImg.statusCode}");
    }

    //We filter out the imgur stubs that have 503 bites size
    if (responseFromImg.bodyBytes.length == 503) {
      throw NoPhotoException("The photo $imageStringUrl is imgur stub");
    }

    //Download the photo
    File downloadedFile = await File("${photosDirectory.path}/"
            '${url.pathSegments[url.pathSegments.length - 1]}'
            '${imageStringUrl.substring(imageStringUrl.lastIndexOf('.'))}')
        .writeAsBytes(responseFromImg.bodyBytes);

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
