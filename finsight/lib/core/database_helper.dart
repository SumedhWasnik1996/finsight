import 'dart:math';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'secure_storage_service.dart';
import 'constants.dart';

class DatabaseHelper{

  static Database? _db;

  static Future<Database> get database async{
    _db ??= await _open();
    return _db!;
  }

  static Future<String> _getOrCreateKey() async {
      String? key = await SecureStorageService.read(AppConstants.keyDbEncryption);
      if (key == null) {
        final rand = Random.secure();
        key = List.generate(32, (_) => rand.nextInt(256))
            .map((b) => b.toRadixString(16).padLeft(2,'0'))
            .join();
        await SecureStorageService.write(AppConstants.keyDbEncryption, key);
      }
      return key;
    }

  static Future<Database> _open() async {
      final key  = await _getOrCreateKey();
      final path = join(await getDatabasesPath(), AppConstants.dbName);
      return openDatabase(path, password: key,
          version: 1, onCreate: _create);
    }
static Future<void> _create(Database db, int _) async {
      // Main transaction table
      await db.execute('''
        CREATE TABLE transactions (
          id              TEXT PRIMARY KEY,
          account_id      TEXT NOT NULL,
          transaction_id  TEXT UNIQUE NOT NULL,
          merchant        TEXT NOT NULL,
          amount          REAL NOT NULL,
          currency        TEXT DEFAULT 'GBP',
          category        TEXT DEFAULT 'other',
          date            TEXT NOT NULL,
          is_subscription INTEGER DEFAULT 0,
          created_at      TEXT NOT NULL
        )''');
      await db.execute(
        'CREATE INDEX idx_date     ON transactions(date)');
      await db.execute(
        'CREATE INDEX idx_merchant ON transactions(merchant)');

      // Budget table
      await db.execute('''
        CREATE TABLE budgets (
          id                  TEXT PRIMARY KEY,
          monthly_limit       REAL NOT NULL,
          excluded_categories TEXT DEFAULT '[]',
          updated_at          TEXT NOT NULL
        )''');

      // Monthly snapshots kept after auto-purge
      await db.execute('''
        CREATE TABLE monthly_snapshots (
          id          TEXT PRIMARY KEY,
          year_month  TEXT NOT NULL,
          category    TEXT NOT NULL,
          total_spent REAL NOT NULL,
          tx_count    INTEGER NOT NULL
        )''');
    }
  }
