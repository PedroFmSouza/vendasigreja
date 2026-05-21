import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/data/app_database.dart';
import '../../core/utils/formatters.dart';
import '../sales/domain/payment_method.dart';

/// Exporta as vendas completas em dois arquivos CSV (vendas + itens)
/// compactados num único .zip — ou dois arquivos compartilhados separados.
/// Opção simples: dois CSVs separados, compartilhados juntos.
class CsvExportService {
  final AppDatabase _appDb;
  CsvExportService(this._appDb);

  Future<void> export() async {
    final db = await _appDb.database;

    // -- vendas --
    final sales = await db.rawQuery('''
      SELECT
        s.id          AS venda_id,
        cd.date       AS data,
        s.sold_at     AS horario,
        s.payment_method AS pagamento,
        s.total_amount   AS total_centavos
      FROM sales s
      JOIN cash_days cd ON cd.id = s.day_id
      ORDER BY cd.date ASC, s.sold_at ASC
    ''');

    // -- itens --
    final items = await db.rawQuery('''
      SELECT
        si.sale_id       AS venda_id,
        si.product_name  AS produto,
        si.unit_price    AS preco_unitario_centavos,
        si.quantity      AS quantidade,
        si.subtotal      AS subtotal_centavos
      FROM sale_items si
      JOIN sales s ON s.id = si.sale_id
      JOIN cash_days cd ON cd.id = s.day_id
      ORDER BY cd.date ASC, s.sold_at ASC
    ''');

    final stamp = Dates.dayKey(DateTime.now());
    final tmp = await getTemporaryDirectory();

    final salesFile = File('${tmp.path}/vendas_$stamp.csv');
    await salesFile.writeAsString(_buildCsv(
      headers: [
        'venda_id',
        'data',
        'horario',
        'pagamento',
        'total',
      ],
      rows: sales.map((r) => [
            r['venda_id'],
            r['data'],
            _fmtTime(r['horario'] as String),
            PaymentMethod.fromId(r['pagamento'] as String).label,
            Money.format(r['total_centavos'] as int),
          ]),
    ));

    final itemsFile = File('${tmp.path}/itens_vendas_$stamp.csv');
    await itemsFile.writeAsString(_buildCsv(
      headers: [
        'venda_id',
        'produto',
        'preco_unitario',
        'quantidade',
        'subtotal',
      ],
      rows: items.map((r) => [
            r['venda_id'],
            r['produto'],
            Money.format(r['preco_unitario_centavos'] as int),
            r['quantidade'],
            Money.format(r['subtotal_centavos'] as int),
          ]),
    ));

    await SharePlus.instance.share(ShareParams(
      files: [XFile(salesFile.path), XFile(itemsFile.path)],
      text: 'Exportação CSV — VendasIgreja ($stamp)',
    ));
  }

  String _buildCsv({
    required List<String> headers,
    required Iterable<Iterable<Object?>> rows,
  }) {
    final buf = StringBuffer();
    buf.writeln(headers.map(_escape).join(';'));
    for (final row in rows) {
      buf.writeln(row.map(_escape).join(';'));
    }
    return buf.toString();
  }

  /// Usa ponto-e-vírgula como separador (padrão BR no Excel).
  /// Envolve em aspas duplas e escapa aspas internas.
  String _escape(Object? value) {
    if (value == null) return '';
    final s = value.toString().replaceAll('"', '""');
    return '"$s"';
  }

  String _fmtTime(String iso) {
    try {
      return Dates.full(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }
}
