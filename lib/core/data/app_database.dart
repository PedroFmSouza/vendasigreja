import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Banco SQLite único do app. Singleton.
///
/// Valores monetários (price, total_amount, unit_price, subtotal) são
/// armazenados em centavos (INTEGER). Datas em ISO-8601 (TEXT).
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const String dbName = 'vendasigreja.db';
  static const int dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<String> path() async => join(await getDatabasesPath(), dbName);

  Future<Database> _open() async {
    return openDatabase(
      await path(),
      version: dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        price       INTEGER NOT NULL,
        category    TEXT    NOT NULL DEFAULT 'Geral',
        active      INTEGER NOT NULL DEFAULT 1,
        created_at  TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cash_days (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        date        TEXT    NOT NULL UNIQUE,
        opened_at   TEXT    NOT NULL,
        closed_at   TEXT,
        status      TEXT    NOT NULL DEFAULT 'open'
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        total_amount    INTEGER NOT NULL,
        payment_method  TEXT    NOT NULL,
        sold_at         TEXT    NOT NULL,
        day_id          INTEGER NOT NULL,
        FOREIGN KEY (day_id) REFERENCES cash_days (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id       INTEGER NOT NULL,
        product_id    INTEGER,
        product_name  TEXT    NOT NULL,
        unit_price    INTEGER NOT NULL,
        quantity      INTEGER NOT NULL,
        subtotal      INTEGER NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE SET NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_sales_day ON sales (day_id)',
    );
    await db.execute(
      'CREATE INDEX idx_sale_items_sale ON sale_items (sale_id)',
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
