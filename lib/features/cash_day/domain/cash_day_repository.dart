import 'cash_day.dart';

abstract class CashDayRepository {
  /// Retorna o caixa do dia informado, criando-o se não existir.
  Future<CashDay> getOrCreate(String date);
  Future<List<CashDay>> getAll();
  Future<CashDay?> byDate(String date);
}
