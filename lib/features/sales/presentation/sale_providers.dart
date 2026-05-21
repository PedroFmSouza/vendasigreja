import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../cash_day/data/sqlite_cash_day_repository.dart';
import '../../cash_day/domain/cash_day_repository.dart';
import '../../products/domain/product.dart';
import '../../products/presentation/product_providers.dart';
import '../data/sqlite_sale_repository.dart';
import '../domain/payment_method.dart';
import '../domain/sale.dart';
import '../domain/sale_repository.dart';

/// Revisão global das vendas. Incrementa a cada mutação (venda, undo, exclusão).
/// Qualquer provider de leitura que observe isto recarrega em tempo real.
final salesRevisionProvider =
    NotifierProvider<SalesRevisionNotifier, int>(SalesRevisionNotifier.new);

class SalesRevisionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

final salesHistoryProvider =
    AsyncNotifierProvider<SalesHistoryNotifier, List<Sale>>(
  SalesHistoryNotifier.new,
);

final cashDayRepositoryProvider = Provider<CashDayRepository>((ref) {
  return SqliteCashDayRepository(ref.watch(appDatabaseProvider));
});

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SqliteSaleRepository(ref.watch(appDatabaseProvider));
});

/// Forma de pagamento atualmente selecionada na tela de venda.
final selectedPaymentProvider =
    NotifierProvider<SelectedPaymentNotifier, PaymentMethod>(
  SelectedPaymentNotifier.new,
);

class SelectedPaymentNotifier extends Notifier<PaymentMethod> {
  @override
  PaymentMethod build() => PaymentMethod.cash;

  void select(PaymentMethod method) => state = method;
}

/// Vendas do caixa de hoje, mais recentes primeiro.
final todaySalesProvider =
    AsyncNotifierProvider<TodaySalesNotifier, List<Sale>>(
  TodaySalesNotifier.new,
);

class TodaySalesNotifier extends AsyncNotifier<List<Sale>> {
  SaleRepository get _sales => ref.read(saleRepositoryProvider);
  CashDayRepository get _days => ref.read(cashDayRepositoryProvider);

  @override
  Future<List<Sale>> build() async {
    // Recarrega sempre que houver qualquer mutação de venda no app.
    ref.watch(salesRevisionProvider);
    final day = await _days.getOrCreate(Dates.todayKey());
    return _sales.byDay(day.id!);
  }

  Future<void> quickSell(Product product, PaymentMethod method,
      {int quantity = 1}) async {
    assert(quantity >= 1);
    final day = await _days.getOrCreate(Dates.todayKey());
    final now = DateTime.now();
    final subtotal = product.price * quantity;
    final item = SaleItem(
      productId: product.id,
      productName: product.name,
      unitPrice: product.price,
      quantity: quantity,
      subtotal: subtotal,
    );
    await _sales.create(Sale(
      totalAmount: subtotal,
      paymentMethod: method,
      soldAt: now,
      dayId: day.id!,
      items: [item],
    ));
    ref.read(salesRevisionProvider.notifier).bump();
  }

  Future<void> undo(int saleId) async {
    await _sales.delete(saleId);
    ref.read(salesRevisionProvider.notifier).bump();
  }
}

/// Histórico de vendas — carrega todo o período disponível, mais recentes primeiro.
class SalesHistoryNotifier extends AsyncNotifier<List<Sale>> {
  SaleRepository get _sales => ref.read(saleRepositoryProvider);

  @override
  Future<List<Sale>> build() {
    // Recarrega sempre que houver qualquer mutação de venda no app.
    ref.watch(salesRevisionProvider);
    return _sales.salesByRange('2024-01-01', Dates.todayKey());
  }

  Future<void> deleteSale(int saleId) async {
    await _sales.delete(saleId);
    ref.read(salesRevisionProvider.notifier).bump();
  }
}
