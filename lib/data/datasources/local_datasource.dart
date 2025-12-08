import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatasource {
  static const _dbName = 'weather_cache.db';
  static const _table = 'city_cache';
  Database? _db;

  Future<Database> _openDb() async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
      CREATE TABLE $_table(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        city TEXT UNIQUE,
        lat REAL,
        lon REAL,
        json TEXT,
        updated_at INTEGER
      )
      ''');
      },
    );
    return _db!;
  }

  Future<void> cacheCity(
    String city,
    double lat,
    double lon,
    String json,
  ) async {
    final db = await _openDb();
    await db.insert(_table, {
      'city': city,
      'lat': lat,
      'lon': lon,
      'json': json,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getCachedCity(String city) async {
    final db = await _openDb();
    final rows = await db.query(_table, where: 'city = ?', whereArgs: [city]);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<List<Map<String, dynamic>>> getAllFavorites() async {
    final db = await _openDb();
    return db.query(_table);
  }

  Future<void> deleteCity(String city) async {
    final db = await _openDb();
    await db.delete(_table, where: 'city = ?', whereArgs: [city]);
  }
}
