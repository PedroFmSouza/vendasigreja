import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Formas de pagamento aceitas no caixa.
enum PaymentMethod {
  cash('cash', 'Dinheiro', Icons.payments, AppColors.cash),
  pix('pix', 'Pix', Icons.qr_code, AppColors.pix),
  card('card', 'Cartão', Icons.credit_card, AppColors.card);

  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const PaymentMethod(this.id, this.label, this.icon, this.color);

  static PaymentMethod fromId(String id) =>
      values.firstWhere((m) => m.id == id, orElse: () => PaymentMethod.cash);
}
