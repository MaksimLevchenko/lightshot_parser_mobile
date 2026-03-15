import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lightshot_parser_mobile/core/models/storage_paths.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_source.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_category.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_result.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_scores.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_status.dart';

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
            'file_path': null,
            'classification_status': null,
            'classification_category': null,
            'classification_confidence': null,
            'classification_raw_scores_json': null,
            'classification_backend': null,
            'classification_updated_at': null,
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
        'file_path': null,
        'classification_status': null,
        'classification_category': null,
        'classification_confidence': null,
        'classification_raw_scores_json': null,
        'classification_backend': null,
        'classification_updated_at': null,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<Map<String, GalleryItem>> loadStoredGalleryItems(
    StoragePaths paths,
  ) async {
    final database = await _open(paths);
    await _migrateLegacyTextFile(database, paths);

    final rows = await database.query(
      _tableName,
      where: 'file_path IS NOT NULL',
      orderBy: 'created_at DESC',
    );

    return <String, GalleryItem>{
      for (final row in rows) _readTrackingKey(row): _galleryItemFromRow(row),
    };
  }

  Future<void> replaceTrackedItems(
    StoragePaths paths,
    Iterable<GalleryItem> items,
  ) async {
    final database = await _open(paths);
    await database.transaction((transaction) async {
      await transaction.delete(_tableName);
      final batch = transaction.batch();
      for (final item in items) {
        _insertGalleryItem(batch, item);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> upsertGalleryItem(
    StoragePaths paths,
    GalleryItem item,
  ) async {
    final database = await _open(paths);
    await database.insert(
      _tableName,
      _galleryItemToRow(item),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateClassification(
    StoragePaths paths, {
    required String trackingKey,
    required ClassificationResult classificationResult,
  }) async {
    final database = await _open(paths);
    await database.update(
      _tableName,
      <String, Object?>{
        'classification_status': classificationResult.status.name,
        'classification_category': classificationResult.category.name,
        'classification_confidence': classificationResult.confidence,
        'classification_raw_scores_json': jsonEncode(
          classificationResult.rawScores.toJson(),
        ),
        'classification_backend': classificationResult.backend,
        'classification_updated_at':
            classificationResult.classifiedAt?.millisecondsSinceEpoch,
      },
      where: 'tracking_key = ?',
      whereArgs: <Object>[canonicalizeTrackingKey(trackingKey)],
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
        version: 2,
        onCreate: (db, version) async {
          await _createTable(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
              'ALTER TABLE $_tableName ADD COLUMN file_path TEXT',
            );
            await db.execute(
              'ALTER TABLE $_tableName ADD COLUMN classification_status TEXT',
            );
            await db.execute(
              'ALTER TABLE $_tableName ADD COLUMN classification_category TEXT',
            );
            await db.execute(
              'ALTER TABLE $_tableName ADD COLUMN classification_confidence REAL',
            );
            await db.execute(
              'ALTER TABLE $_tableName ADD COLUMN classification_raw_scores_json TEXT',
            );
            await db.execute(
              'ALTER TABLE $_tableName ADD COLUMN classification_backend TEXT',
            );
            await db.execute(
              'ALTER TABLE $_tableName ADD COLUMN classification_updated_at INTEGER',
            );
          }
        },
      ),
    );

    _database = database;
    return database;
  }

  Future<void> _createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_tableName(
        tracking_key TEXT PRIMARY KEY,
        source TEXT NOT NULL,
        source_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        file_path TEXT,
        classification_status TEXT,
        classification_category TEXT,
        classification_confidence REAL,
        classification_raw_scores_json TEXT,
        classification_backend TEXT,
        classification_updated_at INTEGER
      )
    ''');
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
            'file_path': null,
            'classification_status': null,
            'classification_category': null,
            'classification_confidence': null,
            'classification_raw_scores_json': null,
            'classification_backend': null,
            'classification_updated_at': null,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    }

    await legacyFile.delete();
  }

  void _insertGalleryItem(Batch batch, GalleryItem item) {
    batch.insert(
      _tableName,
      _galleryItemToRow(item),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Map<String, Object?> _galleryItemToRow(GalleryItem item) {
    final classifiedAt = item.classificationResult.classifiedAt;
    return <String, Object?>{
      'tracking_key': item.trackingKey,
      'source': item.source.name,
      'source_id': item.sourceId,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'file_path': item.path,
      'classification_status': item.classificationResult.status.name,
      'classification_category': item.classificationResult.category.name,
      'classification_confidence': item.classificationResult.confidence,
      'classification_raw_scores_json':
          jsonEncode(item.classificationResult.rawScores.toJson()),
      'classification_backend': item.classificationResult.backend,
      'classification_updated_at': classifiedAt?.millisecondsSinceEpoch,
    };
  }

  GalleryItem _galleryItemFromRow(Map<String, Object?> row) {
    final sourceName = row['source'] as String?;
    final source = DownloadSource.values.firstWhere(
      (item) => item.name == sourceName,
      orElse: () => parseTrackingKey(_readTrackingKey(row)).source,
    );
    final sourceId = row['source_id'] as String? ??
        parseTrackingKey(_readTrackingKey(row)).sourceId;
    final classificationRawJson =
        row['classification_raw_scores_json'] as String?;
    final rawScores =
        classificationRawJson == null || classificationRawJson.isEmpty
            ? const ClassificationScores.zero()
            : ClassificationScores.fromJson(
                jsonDecode(classificationRawJson) as Map<String, dynamic>,
              );

    final backend = row['classification_backend'] as String? ?? 'legacy';
    final storedCategory = ClassificationCategory.fromStorage(
      row['classification_category'] as String?,
    );
    final resolvedCategory =
        backend == 'disabled' &&
                storedCategory == ClassificationCategory.unrecognized
            ? ClassificationCategory.notClassified
            : storedCategory;

    return GalleryItem(
      path: row['file_path'] as String,
      source: source,
      sourceId: sourceId,
      classificationResult: ClassificationResult(
        status: ClassificationStatus.fromStorage(
          row['classification_status'] as String?,
        ),
        category: resolvedCategory,
        confidence: _readDouble(row['classification_confidence']),
        rawScores: rawScores,
        backend: backend,
        classifiedAt: _readDateTime(row['classification_updated_at']),
      ),
    );
  }

  String _readTrackingKey(Map<String, Object?> row) {
    return canonicalizeTrackingKey(row['tracking_key'] as String);
  }

  double _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }

  DateTime? _readDateTime(Object? value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}
