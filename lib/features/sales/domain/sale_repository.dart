import 'day_summary.dart';
import 'sale.dart';

abstract class SaleRepository {
  /// Registra uma venda (com seus itens) e retorna com id preenchido.
  Future<Sale> create(Sale sale);

  /// Remove uma venda (cascata apaga os itens).
  Future<void> delete(int saleId);

  /// Vendas de um dia de caixa específico, mais recentes primeiro.
  Future<List<Sale>> byDay(int dayId);

  /// Resumo agregado de um dia de caixa.
  Future<DaySummary> summaryByDay(int dayId);

  /// Resumo agregado de um intervalo de datas (yyyy-MM-dd, inclusivo).
  Future<DaySummary> summaryByRange(String fromDate, String toDate);

  /// Total vendido por dia em um intervalo — para gráfico de evolução.
  Future<Map<String, int>> totalsPerDay(String fromDate, String toDate);

  /// Todas as vendas (com itens) em um intervalo de datas, mais recentes primeiro.
  Future<List<Sale>> salesByRange(String fromDate, String toDate);
}
