import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatasource {
  static const _dbName = 'weather_cache.db';
  static const _table = 'city_cache';
  static const _historyTable = 'search_history';

  Database? _db;

  Future<Database> _openDb() async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _db = await openDatabase(
      path,
      version: 5,
      onCreate: (db, v) async {
        await _createTable(db);
        await _createHistoryTable(db);
      },
      onUpgrade: (db, oldV, newV) async {
        await db.execute('DROP TABLE IF EXISTS $_table');
        await db.execute('DROP TABLE IF EXISTS $_historyTable');
        await _createTable(db);
        await _createHistoryTable(db);
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
        country TEXT,
        state TEXT,
        json TEXT,
        updated_at INTEGER,
        is_favorite INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_historyTable(
        query TEXT PRIMARY KEY,
        timestamp INTEGER
      )
    ''');
  }

  Future<void> saveSearchHistory(String query) async {
    final db = await _openDb();

    // 1. Insert or Update
    await db.insert(_historyTable, {
      'query': query,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // 2. Keep only last 7 items (Updated from 5)
    await db.execute('''
      DELETE FROM $_historyTable 
      WHERE query NOT IN (
        SELECT query FROM $_historyTable 
        ORDER BY timestamp DESC 
        LIMIT 7
      )
    ''');
  }

  Future<List<String>> getSearchHistory() async {
    final db = await _openDb();
    final result = await db.query(
      _historyTable,
      orderBy: 'timestamp DESC',
      limit: 7, // Updated from 5
    );
    return result.map((row) => row['query'] as String).toList();
  }

  // --- NEW: Clear All History ---
  Future<void> clearSearchHistory() async {
    final db = await _openDb();
    await db.delete(_historyTable);
  }

  Future<void> deleteSearchItem(String query) async {
    final db = await _openDb();
    await db.delete(_historyTable, where: 'query = ?', whereArgs: [query]);
  }

  // --- Existing Weather Methods ---
  Future<void> cacheCity(
    String city,
    double lat,
    double lon,
    String country,
    String state,
    String json,
  ) async {
    final db = await _openDb();
    int isFav = 0;
    final existing = await db.query(
      _table,
      columns: ['is_favorite'],
      where: 'city = ?',
      whereArgs: [city],
    );
    if (existing.isNotEmpty) isFav = existing.first['is_favorite'] as int? ?? 0;

    await db.insert(_table, {
      'city': city,
      'lat': lat,
      'lon': lon,
      'country': country,
      'state': state,
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
