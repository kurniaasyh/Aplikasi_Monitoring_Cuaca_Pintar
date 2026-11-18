import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  // Singleton: satu instance database untuk seluruh aplikasi.
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static Database? _database;

  // Membuka database jika belum tersedia.
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  // Inisialisasi file database SQLite.
  Future<Database> _initDatabase() async {
    final databaseDirectory = await getDatabasesPath();

    final databasePath = p.join(
      databaseDirectory,
      'smart_weather.db',
    );

    return openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        // Tabel riwayat pencarian.
        await db.execute('''
          CREATE TABLE search_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            city TEXT NOT NULL,
            city_key TEXT NOT NULL,
            searched_at INTEGER NOT NULL,
            UNIQUE(user_id, city_key)
          )
        ''');

        // Tabel kota favorit.
        await db.execute('''
          CREATE TABLE favorite_cities (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            city TEXT NOT NULL,
            city_key TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            UNIQUE(user_id, city_key)
          )
        ''');
      },
    );
  }

  // Normalisasi nama kota agar tidak tersimpan ganda.
  String _normalizeCity(String city) {
    return city.trim().toLowerCase();
  }

  // ================= RIWAYAT PENCARIAN =================

  Future<void> addSearchHistory({
    required String userId,
    required String city,
  }) async {
    final cleanCity = city.trim();

    if (cleanCity.isEmpty) return;

    final db = await database;

    await db.insert(
      'search_history',
      {
        'user_id': userId,
        'city': cleanCity,
        'city_key': _normalizeCity(cleanCity),
        'searched_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> getSearchHistory(String userId) async {
    final db = await database;

    final result = await db.query(
      'search_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'searched_at DESC',
      limit: 10,
    );

    return result.map((row) => row['city'] as String).toList();
  }

  Future<void> removeSearchHistory({
    required String userId,
    required String city,
  }) async {
    final db = await database;

    await db.delete(
      'search_history',
      where: 'user_id = ? AND city_key = ?',
      whereArgs: [userId, _normalizeCity(city)],
    );
  }

  Future<void> clearSearchHistory(String userId) async {
    final db = await database;

    await db.delete(
      'search_history',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ================= KOTA FAVORIT =================

  Future<void> addFavoriteCity({
    required String userId,
    required String city,
  }) async {
    final cleanCity = city.trim();

    if (cleanCity.isEmpty) return;

    final db = await database;

    await db.insert(
      'favorite_cities',
      {
        'user_id': userId,
        'city': cleanCity,
        'city_key': _normalizeCity(cleanCity),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<String>> getFavoriteCities(String userId) async {
    final db = await database;

    final result = await db.query(
      'favorite_cities',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return result.map((row) => row['city'] as String).toList();
  }

  Future<void> removeFavoriteCity({
    required String userId,
    required String city,
  }) async {
    final db = await database;

    await db.delete(
      'favorite_cities',
      where: 'user_id = ? AND city_key = ?',
      whereArgs: [userId, _normalizeCity(city)],
    );
  }

  Future<bool> isFavoriteCity({
    required String userId,
    required String city,
  }) async {
    final db = await database;

    final result = await db.query(
      'favorite_cities',
      columns: ['id'],
      where: 'user_id = ? AND city_key = ?',
      whereArgs: [userId, _normalizeCity(city)],
      limit: 1,
    );

    return result.isNotEmpty;
  }
}
