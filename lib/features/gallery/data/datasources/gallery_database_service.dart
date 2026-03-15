import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lightshot_parser_mobile/core/models/storage_paths.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_source.dart';

class GalleryDatabaseService {
  static const String _databaseName = 'gallery.db';
  static const String _legacyDatabaseName = 'db.txt';
  static const String _tableName = 'processed_gallery_items';

  Database? _database;

  Future<Set<String>> loadTrackedIds(StoragePaths paths) async {
    final database = await _open(paths);
    await _migrateLegacyTextFile(database, paths);

    final rows = await database.query(
      _tableName,
      columns: ['tracking_key'],
      orderBy: 'tracking_key ASC',
    );

    return rows
        .map((row) => row['tracking_key'])
        .whereType<String>()
        .map(canonicalizeTrackingKey)
        .toSet();
  }

  Future<void> replaceTrackedIds(
    StoragePaths paths,
    Iterable<String> trackingKeys,
  ) async {
    final database = await _open(paths);
    final normalizedKeys = trackingKeys.map(canonicalizeTrackingKey).toList()
      ..sort();

    await database.transaction((transaction) async {
      await transaction.delete(_tableName);
      final batch = transaction.batch();
      final createdAt = DateTime.now().millisecondsSinceEpoch;
      for (final trackingKey in normalizedKeys) {
        final parsed = parseTrackingKey(trackingKey);
        batch.insert(
          _tableName,
          {
            'tracking_key': trackingKey,
            'source': parsed.source.name,
            'source_id': parsed.sourceId,
            'created_at': createdAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> insertTrackedId(StoragePaths paths, String trackingKey) async {
    final database = await _open(paths);
    final normalizedKey = canonicalizeTrackingKey(trackingKey);
    final parsed = parseTrackingKey(normalizedKey);

    await database.insert(
      _tableName,
      {
        'tracking_key': normalizedKey,
        'source': parsed.source.name,
        'source_id': parsed.sourceId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> close() async {
    final database = _database;
    _database = null;
    await database?.close();
  }

  Future<Database> _open(StoragePaths paths) async {
    final existing = _database;
    if (existing != null && existing.isOpen) {
      return existing;
    }

    final factory = _databaseFactory;
    final databasePath = path.join(paths.databaseDirectory.path, _databaseName);
    final database = await factory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_tableName(
              tracking_key TEXT PRIMARY KEY,
              source TEXT NOT NULL,
              source_id TEXT NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
        },
      ),
    );

    _database = database;
    return database;
  }

  DatabaseFactory get _databaseFactory {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      return databaseFactoryFfi;
    }
    return databaseFactory;
  }

  Future<void> _migrateLegacyTextFile(
    Database database,
    StoragePaths paths,
  ) async {
    final legacyFile = File(
      path.join(paths.databaseDirectory.path, _legacyDatabaseName),
    );
    if (!await legacyFile.exists()) {
      return;
    }

    final lines = await legacyFile.readAsLines();
    final trackingKeys = lines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map(canonicalizeTrackingKey)
        .toList(growable: false);

    if (trackingKeys.isNotEmpty) {
      final batch = database.batch();
      final createdAt = DateTime.now().millisecondsSinceEpoch;
      for (final trackingKey in trackingKeys) {
        final parsed = parseTrackingKey(trackingKey);
        batch.insert(
          _tableName,
          {
            'tracking_key': trackingKey,
            'source': parsed.source.name,
            'source_id': parsed.sourceId,
            'created_at': createdAt,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    }

    await legacyFile.delete();
  }
}
