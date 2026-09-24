import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();
  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'fisheries_offline.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        // Pending SOS reports
        await db.execute('''
          CREATE TABLE pending_sos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            payload TEXT NOT NULL,     -- JSON string
            latitude REAL,
            longitude REAL,
            created_at TEXT NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            retry_count INTEGER NOT NULL DEFAULT 0,
            last_error TEXT
          )
        ''');

        // Pending citings
        await db.execute('''
          CREATE TABLE pending_citings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            payload TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            citing_type TEXT,
            created_at TEXT NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            retry_count INTEGER NOT NULL DEFAULT 0,
            last_error TEXT
          )
        ''');
      },
    );
    return _db!;
  }
}
