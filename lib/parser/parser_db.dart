import 'dart:io';

class DataBase{
  late final String _filePath;
  late final File _dbFile;
  final Set<String> _db = {};

  DataBase([this._filePath = r'.\database.txt']){
    _dbFile = File(_filePath);
    if (!_dbFile.existsSync()){
      _dbFile.createSync();
      parseFolder();
    }

    var dbLines = _dbFile.readAsLinesSync();
    for (int i = 0;i < dbLines.length; i++){
      _db.add(dbLines[i].toString());
    }
  }

  parseFolder([folderPath = r'.\Photos']){
    _db.clear();
    _dbFile.writeAsStringSync('', mode: FileMode.write);
    Directory directory = Directory(folderPath);

    var dbLines = directory.listSync();
    for (int i = 0; i < dbLines.length; i++){
      var filePath = dbLines[i].toString();
      addRecord(filePath.substring(16, filePath.lastIndexOf('.')));
    }
  }

  bool inDb(String fileName){
    return _db.contains(fileName);
  }

  addRecord(String fileName){
    _dbFile.writeAsStringSync('$fileName\n', mode: FileMode.append);
    _db.add(fileName);
  }

  addUrlRecord(Uri url){
    addRecord(url.pathSegments[0]);
  }

  bool urlInDb(Uri url){
    return inDb(url.pathSegments[0]);
  }
}


