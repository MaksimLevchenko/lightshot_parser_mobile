import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import "dart:core";
import 'url_generator.dart' as gen;
import 'parser_db.dart' as db;

class LightshotParser {
  bool downloading = true;
  bool alreadyExists = false;
  late final db.DataBase database;
  late final Directory photosDirectory;
  late final Directory databaseDirectory;
  static final LightshotParser _instance = LightshotParser._();

  LightshotParser._();

  factory LightshotParser(
      {required photosDirectory,
      required databaseDirectory,
      bool downloading = true}) {
    if (_instance.alreadyExists == true) {
      _instance.downloading = downloading;
      log("The instance of LightshotParser already exists");
    } else {
      // It is necessary in order not to be banned immediately
      HttpClient client = HttpClient();
      client.userAgent =
          'Mozilla/5.0 (X11; Linux x86_64; rv:78.0) Gecko/20100101 Firefox/78.0';
      if (!photosDirectory.existsSync()) {
        photosDirectory.createSync(recursive: true);
      }
      _instance.photosDirectory = photosDirectory;
      print(_instance.photosDirectory);
      _instance.databaseDirectory = databaseDirectory;
      _instance.database = db.DataBase(
          fileDirectory: databaseDirectory, photosDirectory: photosDirectory);
      _instance.alreadyExists = true;
      log('The instance of LightshotParser created successfuly');
    }
    return _instance;
  }

  ///downloading image from {prnt.sc} url
  getImage(Uri url) async {
    try {
      final responseFromSite = await http.get(url);
      final RegExp imgPattern = RegExp(r'https.*((png)|(jpg)|(jpeg))');

      switch (responseFromSite.statusCode) {
        case 503:
          await Future.delayed(const Duration(seconds: 10));
          throw Exception('Server wants to ban this IP. Waiting');
        case 403:
          throw Exception('IP got banned');
        case 200:
          break;
        default:
          throw Exception(
              'Can\'t reach server : ${responseFromSite.statusCode}');
      }
      final sourceCode = responseFromSite.body;

      //looking for a direct address to the file
      var imageStringUrl = imgPattern.stringMatch(sourceCode);

      if (imageStringUrl == null) {
        throw Exception("The photo is missing");
      }

      //Cutting the image url after .jpg or .png
      imageStringUrl = imageStringUrl.substring(0, imageStringUrl.indexOf('"'));

      if (!imageStringUrl.contains(imgPattern)) {
        throw Exception("The photo is missing");
      }

      var imageUrl = Uri.parse(imageStringUrl);
      final responseFromImg = await http.get(imageUrl);

      if (responseFromImg.statusCode != 200) {
        throw Exception(
            "The photo is missing with ${responseFromImg.statusCode}");
      }

      //We filter out the imgur stubs that have 503 bites size
      if (responseFromImg.bodyBytes.length == 503) {
        throw Exception("The photo $imageStringUrl is imgur stub");
      }

      //Download the photo
      await File("${photosDirectory.path}/"
              '${url.pathSegments[url.pathSegments.length - 1]}'
              '${imageStringUrl.substring(imageStringUrl.lastIndexOf('.'))}')
          .writeAsBytes(responseFromImg.bodyBytes);

      log('file $imageStringUrl from $url downloaded successful');
      return 1;
    } catch (e) {
      log("There is an exception. $e with $url");
      return 0;
    }
  }

  /// Start parsing
  ///
  /// Downloads numOfImages in new if newAddresses urls
  /// starting from startingUrl. If startingUrl == '' uses random Url
  /// iterator, otherwise - contractor Url iterator
  void parse(int numOfImages, bool newAddresses, String startingUrl) async {
    var getUrl = startingUrl == ''
        ? gen.GetRandomUrl(newAddresses)
        : gen.GetNextUrl(newAddresses, startingUrl);

    // delay is necessary in order not to be banned
    for (num i = 0; i < numOfImages;) {
      if (database.urlInDb(getUrl.current)) {
        log('The page ${getUrl.current} is already checked');
        getUrl.moveNext();
        continue;
      }
      i += await getImage(getUrl.current);
      database.addUrlRecord(getUrl.current);
      getUrl.moveNext();
      if (!downloading) {
        log('Parsing is canceled');
        numOfImages = i.toInt();
        break;
      }
    }
    log("Successfully downloaded $numOfImages photos");
  }
}
