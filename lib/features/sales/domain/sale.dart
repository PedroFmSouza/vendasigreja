import 'payment_method.dart';

/// Item de uma venda. Guarda snapshot do nome/preço do produto no momento
/// da venda — alterações futuras no produto não afetam o histórico.
class SaleItem {
  final int? id;
  final int? saleId;
  final int? productId;
  final String productName;
  final int unitPrice;
  final int quantity;
  final int subtotal;

  const SaleItem({
    this.id,
    this.saleId,
    this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'sale_id': saleId,
        'product_id': productId,
        'product_name': productName,
        'unit_price': unitPrice,
        'quantity': quantity,
        'subtotal': subtotal,
      };

  factory SaleItem.fromMap(Map<String, Object?> map) => SaleItem(
        id: map['id'] as int?,
        saleId: map['sale_id'] as int?,
        productId: map['product_id'] as int?,
        productName: map['product_name'] as String,
        unitPrice: map['unit_price'] as int,
        quantity: map['quantity'] as int,
        subtotal: map['subtotal'] as int,
      );
}

/// Uma venda. No modo lançamento rápido tem exatamente 1 item; a estrutura
/// suporta múltiplos itens (carrinho) sem alterar o schema.
class Sale {
  final int? id;
  final int totalAmount;
  final PaymentMethod paymentMethod;
  final DateTime soldAt;
  final int dayId;
  final List<SaleItem> items;

  const Sale({
    this.id,
    required this.totalAmount,
    required this.paymentMethod,
    required this.soldAt,
    required this.dayId,
    this.items = const [],
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'total_amount': totalAmount,
        'payment_method': paymentMethod.id,
        'sold_at': soldAt.toIso8601String(),
        'day_id': dayId,
      };

  factory Sale.fromMap(Map<String, Object?> map,
          {List<SaleItem> items = const []}) =>
      Sale(
        id: map['id'] as int?,
        totalAmount: map['total_amount'] as int,
        paymentMethod:
            PaymentMethod.fromId(map['payment_method'] as String),
        soldAt: DateTime.parse(map['sold_at'] as String),
        dayId: map['day_id'] as int,
        items: items,
      );
}
