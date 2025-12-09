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
      version: 3, // Increment version for schema change
      onCreate: (db, v) async {
        await _createTable(db);
      },
      onUpgrade: (db, oldV, newV) async {
        // Simple migration: Drop and recreate if version changes
        await db.execute('DROP TABLE IF EXISTS $_table');
        await _createTable(db);
      },
    );
    return _db!;
  }

  Future<void> _createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_table(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        city TEXT UNIQUE,
        lat REAL,
        lon REAL,
        country TEXT, -- New Column for Region Filtering
        json TEXT,
        updated_at INTEGER,
        is_favorite INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> cacheCity(
    String city,
    double lat,
    double lon,
    String country, // New Parameter
    String json,
  ) async {
    final db = await _openDb();

    // Preserve favorite status
    int isFav = 0;
    final existing = await db.query(
      _table,
      columns: ['is_favorite'],
      where: 'city = ?',
      whereArgs: [city],
    );

    if (existing.isNotEmpty) {
      isFav = existing.first['is_favorite'] as int? ?? 0;
    }

    await db.insert(_table, {
      'city': city,
      'lat': lat,
      'lon': lon,
      'country': country, // Save country
      'json': json,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'is_favorite': isFav,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> setFavorite(String city, bool isFavorite) async {
    final db = await _openDb();
    await db.update(
      _table,
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'city = ?',
      whereArgs: [city],
    );
  }

  Future<Map<String, dynamic>?> getCachedCity(String city) async {
    final db = await _openDb();
    final rows = await db.query(_table, where: 'city = ?', whereArgs: [city]);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final db = await _openDb();
    return db.query(_table, where: 'is_favorite = 1', orderBy: 'city ASC');
  }
}

// import 'package:path/path.dart';
// import 'package:sqflite/sqflite.dart';

// class LocalDatasource {
//   static const _dbName = 'weather_cache.db';
//   static const _table = 'city_cache';
//   Database? _db;

//   Future<Database> _openDb() async {
//     if (_db != null) return _db!;
//     final dbPath = await getDatabasesPath();
//     final path = join(dbPath, _dbName);

//     _db = await openDatabase(
//       path,
//       version: 2, // Increment version for schema change
//       onCreate: (db, v) async {
//         await _createTable(db);
//       },
//       onUpgrade: (db, oldV, newV) async {
//         // Simple migration: Drop and recreate if version changes
//         await db.execute('DROP TABLE IF EXISTS $_table');
//         await _createTable(db);
//       },
//     );
//     return _db!;
//   }

//   Future<void> _createTable(Database db) async {
//     await db.execute('''
//       CREATE TABLE $_table(
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         city TEXT UNIQUE,
//         lat REAL,
//         lon REAL,
//         json TEXT,
//         updated_at INTEGER,
//         is_favorite INTEGER DEFAULT 0  -- 0 = false, 1 = true
//       )
//     ''');
//   }

//   // UPDATED: Preserves 'is_favorite' status when updating weather data
//   Future<void> cacheCity(
//     String city,
//     double lat,
//     double lon,
//     String json,
//   ) async {
//     final db = await _openDb();

//     // 1. Check if city exists to preserve its favorite status
//     int isFav = 0;
//     final existing = await db.query(
//       _table,
//       columns: ['is_favorite'],
//       where: 'city = ?',
//       whereArgs: [city],
//     );

//     if (existing.isNotEmpty) {
//       isFav = existing.first['is_favorite'] as int? ?? 0;
//     }

//     // 2. Insert or Replace (Upsert)
//     await db.insert(_table, {
//       'city': city,
//       'lat': lat,
//       'lon': lon,
//       'json': json,
//       'updated_at': DateTime.now().millisecondsSinceEpoch,
//       'is_favorite': isFav, // Keep the old status
//     }, conflictAlgorithm: ConflictAlgorithm.replace);
//   }

//   // NEW: Toggle Favorite Status
//   Future<void> setFavorite(String city, bool isFavorite) async {
//     final db = await _openDb();
//     await db.update(
//       _table,
//       {'is_favorite': isFavorite ? 1 : 0},
//       where: 'city = ?',
//       whereArgs: [city],
//     );
//   }

//   Future<Map<String, dynamic>?> getCachedCity(String city) async {
//     final db = await _openDb();
//     final rows = await db.query(_table, where: 'city = ?', whereArgs: [city]);
//     if (rows.isEmpty) return null;
//     return rows.first;
//   }

//   // UPDATED: Only return cities marked as favorites
//   Future<List<Map<String, dynamic>>> getFavorites() async {
//     final db = await _openDb();
//     return db.query(_table, where: 'is_favorite = 1', orderBy: 'city ASC');
//   }

//   Future<void> deleteCity(String city) async {
//     final db = await _openDb();
//     await db.delete(_table, where: 'city = ?', whereArgs: [city]);
//   }
// }
