import 'package:intl/intl.dart';

/// Valores monetários são armazenados em centavos (int) para evitar erro de
/// ponto flutuante. Estes helpers convertem entre centavos e exibição BRL.
class Money {
  static final NumberFormat _brl =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  /// Centavos (int) -> "R\$ 12,34"
  static String format(int cents) => _brl.format(cents / 100);

  /// Reais (double) -> centavos (int)
  static int toCents(double reais) => (reais * 100).round();

  /// Centavos (int) -> reais (double)
  static double toReais(int cents) => cents / 100;

  /// Texto digitado ("12,50" ou "12.50") -> centavos. Retorna null se inválido.
  static int? parse(String input) {
    final cleaned = input.trim().replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(cleaned);
    if (value == null || value < 0) return null;
    return toCents(value);
  }
}

class Dates {
  static final DateFormat _day = DateFormat('dd/MM/yyyy');
  static final DateFormat _time = DateFormat('HH:mm');
  static final DateFormat _full = DateFormat("dd/MM/yyyy 'às' HH:mm");
  static final DateFormat _iso = DateFormat('yyyy-MM-dd');

  static String day(DateTime d) => _day.format(d);
  static String time(DateTime d) => _time.format(d);
  static String full(DateTime d) => _full.format(d);

  /// Chave de dia (yyyy-MM-dd) usada para agrupar caixa.
  static String dayKey(DateTime d) => _iso.format(d);
  static String todayKey() => dayKey(DateTime.now());
}
