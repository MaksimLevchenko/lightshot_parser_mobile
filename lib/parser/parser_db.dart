import 'dart:io';

class DataBase {
  late final Directory fileDirectory;
  late final Directory photosDirectory;
  late final File _dbFile;
  final Set<String> _db = {};

  DataBase({required this.fileDirectory, required this.photosDirectory}) {
    _dbFile = File(fileDirectory.path + r'db.txt');
    if (!_dbFile.existsSync()) {
      _dbFile.createSync(recursive: true);
      parseFolder(photosDirectory);
    }

    var dbLines = _dbFile.readAsLinesSync();
    for (int i = 0; i < dbLines.length; i++) {
      _db.add(dbLines[i].toString());
    }
  }

  parseFolder(Directory photosDirectory) {
    _db.clear();
    _dbFile.writeAsStringSync('', mode: FileMode.write);

    var dbLines = photosDirectory.listSync();
    for (int i = 0; i < dbLines.length; i++) {
      var filePath = dbLines[i].toString();
      addRecord(filePath.substring(16, filePath.lastIndexOf('.')));
    }
  }

  int numOfDownloadedPhotos(Directory photosDirectory) {
    return photosDirectory.listSync().length;
  }

  bool inDb(String fileName) {
    return _db.contains(fileName);
  }

  addRecord(String fileName) {
    _dbFile.writeAsStringSync('$fileName\n', mode: FileMode.append);
    _db.add(fileName);
  }

  addUrlRecord(Uri url) {
    addRecord(url.pathSegments[0]);
  }

  bool urlInDb(Uri url) {
    return inDb(url.pathSegments[0]);
  }
}
