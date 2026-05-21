import '../../../core/data/app_database.dart';
import '../domain/product.dart';
import '../domain/product_repository.dart';

class SqliteProductRepository implements ProductRepository {
  final AppDatabase _appDb;
  SqliteProductRepository(this._appDb);

  @override
  Future<List<Product>> getAll({bool onlyActive = false}) async {
    final db = await _appDb.database;
    final rows = await db.query(
      'products',
      where: onlyActive ? 'active = 1' : null,
      orderBy: 'category ASC, name ASC',
    );
    return rows.map(Product.fromMap).toList();
  }

  @override
  Future<Product> create(Product product) async {
    final db = await _appDb.database;
    final map = product.toMap()..remove('id');
    final id = await db.insert('products', map);
    return product.copyWith(id: id);
  }

  @override
  Future<void> update(Product product) async {
    final db = await _appDb.database;
    await db.update(
      'products',
      product.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  @override
  Future<void> delete(int id) async {
    final db = await _appDb.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<String>> categories() async {
    final db = await _appDb.database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT category FROM products ORDER BY category ASC',
    );
    return rows.map((r) => r['category'] as String).toList();
  }
}
