import '../../../core/data/app_database.dart';
import '../domain/cash_day.dart';
import '../domain/cash_day_repository.dart';

class SqliteCashDayRepository implements CashDayRepository {
  final AppDatabase _appDb;
  SqliteCashDayRepository(this._appDb);

  @override
  Future<CashDay> getOrCreate(String date) async {
    final existing = await byDate(date);
    if (existing != null) return existing;

    final db = await _appDb.database;
    final now = DateTime.now();
    final id = await db.insert('cash_days', {
      'date': date,
      'opened_at': now.toIso8601String(),
      'status': 'open',
    });
    return CashDay(id: id, date: date, openedAt: now);
  }

  @override
  Future<CashDay?> byDate(String date) async {
    final db = await _appDb.database;
    final rows = await db.query(
      'cash_days',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CashDay.fromMap(rows.first);
  }

  @override
  Future<List<CashDay>> getAll() async {
    final db = await _appDb.database;
    final rows = await db.query('cash_days', orderBy: 'date DESC');
    return rows.map(CashDay.fromMap).toList();
  }
}
