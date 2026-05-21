import 'payment_method.dart';

/// Linha de resumo de um produto: nome, qtd total e valor total.
class ProductTotal {
  final String productName;
  final int quantity;
  final int total;
  const ProductTotal(this.productName, this.quantity, this.total);
}

/// Resumo agregado de um período (um dia ou intervalo).
class DaySummary {
  final int grandTotal;
  final int saleCount;
  final Map<PaymentMethod, int> byPayment;
  final Map<String, int> byCategory;
  final List<ProductTotal> byProduct;

  const DaySummary({
    required this.grandTotal,
    required this.saleCount,
    required this.byPayment,
    required this.byCategory,
    required this.byProduct,
  });

  static const empty = DaySummary(
    grandTotal: 0,
    saleCount: 0,
    byPayment: {},
    byCategory: {},
    byProduct: [],
  );

  bool get isEmpty => saleCount == 0;
}
