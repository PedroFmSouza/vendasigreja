import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vendasigreja/core/utils/formatters.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  // intl usa espaço não-quebrável (NBSP) após o símbolo da moeda.
  String norm(String s) => s.replaceAll(' ', ' ');

  group('Money', () {
    test('format converte centavos em BRL', () {
      expect(norm(Money.format(1234)), 'R\$ 12,34');
      expect(norm(Money.format(0)), 'R\$ 0,00');
      expect(norm(Money.format(100000)), 'R\$ 1.000,00');
    });

    test('parse aceita vírgula e ponto', () {
      expect(Money.parse('12,50'), 1250);
      expect(Money.parse('1.000,00'), 100000);
      expect(Money.parse('5'), 500);
    });

    test('parse rejeita entrada inválida', () {
      expect(Money.parse('abc'), isNull);
      expect(Money.parse('-3'), isNull);
    });

    test('toCents e toReais são inversos', () {
      expect(Money.toCents(12.34), 1234);
      expect(Money.toReais(1234), 12.34);
    });
  });

  group('Dates', () {
    test('dayKey gera chave ISO', () {
      expect(Dates.dayKey(DateTime(2026, 5, 20)), '2026-05-20');
    });

    test('day formata dd/MM/yyyy', () {
      expect(Dates.day(DateTime(2026, 5, 20)), '20/05/2026');
    });
  });
}
