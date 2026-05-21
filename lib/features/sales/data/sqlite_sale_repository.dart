import '../../../core/data/app_database.dart';
import '../domain/day_summary.dart';
import '../domain/payment_method.dart';
import '../domain/sale.dart';
import '../domain/sale_repository.dart';

class SqliteSaleRepository implements SaleRepository {
  final AppDatabase _appDb;
  SqliteSaleRepository(this._appDb);

  @override
  Future<Sale> create(Sale sale) async {
    final db = await _appDb.database;
    late int saleId;
    await db.transaction((txn) async {
      saleId = await txn.insert('sales', sale.toMap()..remove('id'));
      for (final item in sale.items) {
        await txn.insert('sale_items', {
          ...item.toMap()..remove('id'),
          'sale_id': saleId,
        });
      }
    });
    return Sale(
      id: saleId,
      totalAmount: sale.totalAmount,
      paymentMethod: sale.paymentMethod,
      soldAt: sale.soldAt,
      dayId: sale.dayId,
      items: sale.items,
    );
  }

  @override
  Future<void> delete(int saleId) async {
    final db = await _appDb.database;
    await db.delete('sales', where: 'id = ?', whereArgs: [saleId]);
  }

  @override
  Future<List<Sale>> byDay(int dayId) async {
    final db = await _appDb.database;
    final saleRows = await db.query(
      'sales',
      where: 'day_id = ?',
      whereArgs: [dayId],
      orderBy: 'sold_at DESC',
    );
    final sales = <Sale>[];
    for (final row in saleRows) {
      final itemRows = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [row['id']],
      );
      sales.add(Sale.fromMap(
        row,
        items: itemRows.map(SaleItem.fromMap).toList(),
      ));
    }
    return sales;
  }

  @override
  Future<DaySummary> summaryByDay(int dayId) {
    return _summary(
      saleWhere: 'sales.day_id = ?',
      saleArgs: [dayId],
    );
  }

  @override
  Future<DaySummary> summaryByRange(String fromDate, String toDate) {
    return _summary(
      saleWhere: 'cash_days.date BETWEEN ? AND ?',
      saleArgs: [fromDate, toDate],
      joinCashDays: true,
    );
  }

  Future<DaySummary> _summary({
    required String saleWhere,
    required List<Object?> saleArgs,
    bool joinCashDays = false,
  }) async {
    final db = await _appDb.database;
    final join = joinCashDays
        ? 'JOIN cash_days ON cash_days.id = sales.day_id'
        : '';

    final totalRow = await db.rawQuery('''
      SELECT COALESCE(SUM(total_amount),0) AS total, COUNT(*) AS cnt
      FROM sales $join
      WHERE $saleWhere
    ''', saleArgs);
    final grandTotal = (totalRow.first['total'] as int?) ?? 0;
    final saleCount = (totalRow.first['cnt'] as int?) ?? 0;

    final payRows = await db.rawQuery('''
      SELECT payment_method, COALESCE(SUM(total_amount),0) AS total
      FROM sales $join
      WHERE $saleWhere
      GROUP BY payment_method
    ''', saleArgs);
    final byPayment = <PaymentMethod, int>{};
    for (final r in payRows) {
      byPayment[PaymentMethod.fromId(r['payment_method'] as String)] =
          r['total'] as int;
    }

    final itemJoin =
        'JOIN sales ON sales.id = sale_items.sale_id ${joinCashDays ? 'JOIN cash_days ON cash_days.id = sales.day_id' : ''}';

    final catRows = await db.rawQuery('''
      SELECT COALESCE(products.category, 'Geral') AS category,
             COALESCE(SUM(sale_items.subtotal),0) AS total
      FROM sale_items
      $itemJoin
      LEFT JOIN products ON products.id = sale_items.product_id
      WHERE $saleWhere
      GROUP BY category
    ''', saleArgs);
    final byCategory = <String, int>{};
    for (final r in catRows) {
      byCategory[r['category'] as String] = r['total'] as int;
    }

    final prodRows = await db.rawQuery('''
      SELECT sale_items.product_name AS name,
             COALESCE(SUM(sale_items.quantity),0) AS qty,
             COALESCE(SUM(sale_items.subtotal),0) AS total
      FROM sale_items
      $itemJoin
      WHERE $saleWhere
      GROUP BY sale_items.product_name
      ORDER BY total DESC
    ''', saleArgs);
    final byProduct = prodRows
        .map((r) => ProductTotal(
              r['name'] as String,
              r['qty'] as int,
              r['total'] as int,
            ))
        .toList();

    return DaySummary(
      grandTotal: grandTotal,
      saleCount: saleCount,
      byPayment: byPayment,
      byCategory: byCategory,
      byProduct: byProduct,
    );
  }

  @override
  Future<List<Sale>> salesByRange(String fromDate, String toDate) async {
    final db = await _appDb.database;
    final saleRows = await db.rawQuery('''
      SELECT sales.*
      FROM sales
      JOIN cash_days ON cash_days.id = sales.day_id
      WHERE cash_days.date BETWEEN ? AND ?
      ORDER BY sales.sold_at DESC
    ''', [fromDate, toDate]);
    final sales = <Sale>[];
    for (final row in saleRows) {
      final itemRows = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [row['id']],
      );
      sales.add(Sale.fromMap(
        row,
        items: itemRows.map(SaleItem.fromMap).toList(),
      ));
    }
    return sales;
  }

  @override
  Future<Map<String, int>> totalsPerDay(
      String fromDate, String toDate) async {
    final db = await _appDb.database;
    final rows = await db.rawQuery('''
      SELECT cash_days.date AS date,
             COALESCE(SUM(sales.total_amount),0) AS total
      FROM sales
      JOIN cash_days ON cash_days.id = sales.day_id
      WHERE cash_days.date BETWEEN ? AND ?
      GROUP BY cash_days.date
      ORDER BY cash_days.date ASC
    ''', [fromDate, toDate]);
    return {
      for (final r in rows) r['date'] as String: r['total'] as int,
    };
  }
}
