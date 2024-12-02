import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    return _db ??= await initializeDatabase('choice_board');
  }

  Future<Database> initializeDatabase(String dbname) async {
    String path = join(await getDatabasesPath(), dbname);
    print("Opening database at $path");
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        print("Creating database...");
        await db.execute('PRAGMA foreign_keys = ON');
        await _createTables(db);
      },
      onOpen: (db) async {
        print("Database opened");
        await db.execute('PRAGMA foreign_keys = ON'); // Ensure foreign keys are enabled on open
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // Table to store saved choices
    await db.execute(
        '''CREATE TABLE IF NOT EXISTS saved_choices (
           id INTEGER PRIMARY KEY AUTOINCREMENT,
           image TEXT,         -- Path to the image (nullable)
           sound TEXT,         -- Path to the sound file (nullable)
           text TEXT NOT NULL  -- Text for the choice (non-nullable)
         )'''
    );

    // Table to store choice boards and their metadata
    await db.execute(
        '''CREATE TABLE IF NOT EXISTS choice_boards (
           id INTEGER PRIMARY KEY AUTOINCREMENT,
           name TEXT NOT NULL, -- Name of the choice board
           createdAt DATETIME DEFAULT CURRENT_TIMESTAMP -- Timestamp of creation
         )'''
    );

    // Table to associate choices with choice boards
    await db.execute(
        '''CREATE TABLE IF NOT EXISTS choice_board_choices (
           id INTEGER PRIMARY KEY AUTOINCREMENT,
           choiceBoardId INTEGER NOT NULL, -- Foreign key to choice_boards
           choiceId INTEGER NOT NULL,     -- Foreign key to saved_choices
           FOREIGN KEY(choiceBoardId) REFERENCES choice_boards(id) ON DELETE CASCADE,
           FOREIGN KEY(choiceId) REFERENCES saved_choices(id) ON DELETE CASCADE
         )'''
    );
  }

  // CRUD operations for Saved Choices
  Future<int> insertSavedChoice(Map<String, dynamic> choice) async {
    final db = await database;
    try {
      return await db.insert('saved_choices', choice, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('Error inserting saved choice: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getSavedChoices() async {
    final db = await database;
    return await db.query('saved_choices');
  }

  Future<int> deleteSavedChoice(int id) async {
    final db = await database;
    return await db.delete('saved_choices', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD operations for Choice Boards
  Future<int> insertChoiceBoard(Map<String, dynamic> choiceBoard) async {
    final db = await database;
    try {
      return await db.insert('choice_boards', choiceBoard, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('Error inserting choice board: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getChoiceBoards() async {
    final db = await database;
    return await db.query('choice_boards');
  }

  Future<int> deleteChoiceBoard(int id) async {
    final db = await database;
    return await db.delete('choice_boards', where: 'id = ?', whereArgs: [id]);
  }

  // Linking choices with boards
  Future<void> addChoiceToBoard(int choiceBoardId, int choiceId) async {
    final db = await database;
    try {
      await db.insert('choice_board_choices', {
        'choiceBoardId': choiceBoardId,
        'choiceId': choiceId,
      });
    } catch (e) {
      print('Error adding choice to board: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getChoicesForBoard(int choiceBoardId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT sc.*
      FROM saved_choices AS sc
      JOIN choice_board_choices AS cbc
      ON sc.id = cbc.choiceId
      WHERE cbc.choiceBoardId = ?
    ''', [choiceBoardId]);
  }

  Future<void> deleteChoiceFromBoard(int choiceBoardId, int choiceId) async {
    final db = await database;
    try {
      await db.delete(
        'choice_board_choices',
        where: 'choiceBoardId = ? AND choiceId = ?',
        whereArgs: [choiceBoardId, choiceId],
      );
    } catch (e) {
      print('Error deleting choice from board: $e');
    }
  }

  Future<int> updateSavedChoice(int id, Map<String, dynamic> updatedFields) async {
    final db = await database;

    try {
      return await db.update(
        'saved_choices',
        updatedFields,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error updating saved choice: $e');
      return -1; // Return an error indicator
    }
  }

  // Utility methods
  Future<void> clearTable(String tableName) async {
    final db = await database;
    try {
      await db.delete(tableName);
    } catch (e) {
      print('Error clearing table $tableName: $e');
    }
  }

  Future<void> logDatabaseContents(Database db) async {
    final tables = await db.rawQuery('SELECT name FROM sqlite_master WHERE type="table"');
    print('Tables: $tables');

    for (var table in tables) {
      final tableName = table['name'] as String?;  // Cast to String? for safety
      if (tableName != null && tableName != 'android_metadata' && tableName != 'sqlite_sequence') {
        final rows = await db.query(tableName);  // Now tableName is of type String
        print('Contents of $tableName: $rows');
      }
    }
  }


  Future<void> closeDatabase() async {
    final db = await _db;
    if (db != null) {
      await db.close();
      print('Database closed');
    }
  }
}
