import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'detected_object.dart';
import 'package:intl/intl.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'detected_objects.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE objects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            label TEXT,
            confidence REAL,
            boundingBox TEXT,
            category TEXT,
            date TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertObject(DetectedObject object) async {
    final db = await database;
    await db.insert(
      'objects',
      object.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DetectedObject>> getAllObjects() async {
    final db = await database;
    final results = await db.query('objects', orderBy: 'date DESC');
    return results.map((map) => DetectedObject.fromMap(map)).toList();
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}

