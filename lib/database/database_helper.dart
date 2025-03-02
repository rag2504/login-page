import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'matrimony.db');

    return await openDatabase(
      path,
      version: 2, // Increment when modifying schema
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            mobile TEXT NOT NULL,
            age INTEGER NOT NULL CHECK (age >= 18),
            city TEXT NOT NULL,
            gender TEXT NOT NULL,
            password TEXT NOT NULL,
            isFavorite INTEGER DEFAULT 0,
            otp TEXT,
            otpExpiration INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE users ADD COLUMN otp TEXT');
          await db.execute('ALTER TABLE users ADD COLUMN otpExpiration INTEGER');
        }
      },
    );
  }

  Future<int> insertUser(User user) async {
    try {
      final db = await database;
      return await db.insert('users', user.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print("Error inserting user: $e");
      return -1; // Error indication
    }
  }

  Future<int> updateUser(User user) async {
    try {
      final db = await database;
      return await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
    } catch (e) {
      print("Error updating user: $e");
      return -1;
    }
  }

  Future<int> deleteUser(int id) async {
    try {
      final db = await database;
      return await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print("Error deleting user: $e");
      return -1;
    }
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final results = await db.query('users');
    return results.map((map) => User.fromMap(map)).toList();
  }

  Future<bool> validateUser(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return result.isNotEmpty;
  }

  Future<List<User>> getFavoriteUsers() async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'isFavorite = ?',
      whereArgs: [1],
    );
    return results.map((map) => User.fromMap(map)).toList();
  }

  Future<void> toggleFavorite(int id) async {
    final db = await database;
    final result = await db.query(
      'users',
      columns: ['isFavorite'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      int newFavoriteStatus = (result.first['isFavorite'] as int) == 1 ? 0 : 1;
      await db.update(
        'users',
        {'isFavorite': newFavoriteStatus},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<void> updateOtp(String email, String otp, int expiration) async {
    final db = await database;
    await db.update(
      'users',
      {'otp': otp, 'otpExpiration': expiration},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<void> resetPassword(String email, String newPassword) async {
    final db = await database;
    await db.update(
      'users',
      {'password': newPassword, 'otp': null, 'otpExpiration': null},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<User?> validateOtp(String email, String otp) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND otp = ? AND otpExpiration > ?',
      whereArgs: [email, otp, DateTime.now().millisecondsSinceEpoch],
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<void> close() async {
    final db = await _database;
    if (db != null) {
      await db.close();
    }
  }
}