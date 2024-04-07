import 'dart:developer';
import 'dart:io';

class DataBase {
  late final Directory fileDirectory;
  late final Directory photosDirectory;
  late final File _dbFile;
  final Set<String> _db = {};
  static final DataBase _instance = DataBase._();
  bool alreadyExists = false;

  DataBase._();

  factory DataBase(
      {required Directory fileDirectory, required Directory photosDirectory}) {
    if (_instance.alreadyExists == true) {
      log("The instance of Database already exists");
    } else {
      _instance.fileDirectory = fileDirectory;
      _instance.photosDirectory = photosDirectory;
      _instance._dbFile = File(fileDirectory.path + r'db.txt');
      _instance._dbFile.createSync(recursive: true);
      photosDirectory.createSync(recursive: true);
      if (!_instance._dbFile.existsSync()) {
        _instance.parseFolder();
      }

      var dbLines = _instance._dbFile.readAsLinesSync();
      for (int i = 0; i < dbLines.length; i++) {
        _instance._db.add(dbLines[i].toString());
      }
      _instance.alreadyExists = true;
      log('The instance of database created successfuly');
    }
    return _instance;
  }

  parseFolder() {
    _db.clear();
    _dbFile.writeAsStringSync('', mode: FileMode.write);

    var dbLines = photosDirectory.listSync();
    for (int i = 0; i < dbLines.length; i++) {
      var filePath = dbLines[i].toString();
      addRecord(filePath.substring(16, filePath.lastIndexOf('.')));
    }
  }

  int numOfDownloadedPhotos() {
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
