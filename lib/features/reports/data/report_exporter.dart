import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../sales/domain/day_summary.dart';
import '../../sales/domain/payment_method.dart';

/// Mostra um sheet para escolher PDF ou Excel e compartilha o arquivo gerado.
Future<void> showExportSheet(
  BuildContext context, {
  required DaySummary summary,
  required String rangeLabel,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const Text(
            'Exportar relatório',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf,
                color: AppColors.danger),
            title: const Text('PDF'),
            subtitle: const Text('Para imprimir ou enviar no WhatsApp'),
            onTap: () async {
              Navigator.pop(sheetCtx);
              final file = await _buildPdf(summary, rangeLabel);
              await _share(file, 'Relatório de vendas — $rangeLabel');
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.table_chart, color: AppColors.success),
            title: const Text('Excel'),
            subtitle: const Text('Planilha editável (.xlsx)'),
            onTap: () async {
              Navigator.pop(sheetCtx);
              final file = await _buildExcel(summary, rangeLabel);
              await _share(file, 'Relatório de vendas — $rangeLabel');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<void> _share(File file, String text) async {
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], text: text),
  );
}

String _safeName(String label) =>
    label.replaceAll(RegExp(r'[^0-9A-Za-z]+'), '_');

Future<File> _buildPdf(DaySummary summary, String rangeLabel) async {
  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Header(
          level: 0,
          child: pw.Text(
            'Relatório de Vendas — VendasIgreja',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Text('Período: $rangeLabel'),
        pw.SizedBox(height: 4),
        pw.Text('Total geral: ${Money.format(summary.grandTotal)}'),
        pw.Text('Vendas: ${summary.saleCount}'),
        pw.SizedBox(height: 16),
        pw.Text('Por forma de pagamento',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Forma', 'Total'],
          data: [
            for (final m in PaymentMethod.values)
              [m.label, Money.format(summary.byPayment[m] ?? 0)],
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Text('Por produto',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Produto', 'Qtd', 'Total'],
          data: [
            for (final p in summary.byProduct)
              [p.productName, '${p.quantity}', Money.format(p.total)],
          ],
        ),
      ],
    ),
  );

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/relatorio_${_safeName(rangeLabel)}.pdf');
  await file.writeAsBytes(await doc.save());
  return file;
}

Future<File> _buildExcel(DaySummary summary, String rangeLabel) async {
  final book = Excel.createExcel();
  final sheet = book['Vendas'];
  book.setDefaultSheet('Vendas');

  void row(List<Object?> cells) {
    sheet.appendRow(
      cells.map((c) => TextCellValue(c?.toString() ?? '')).toList(),
    );
  }

  row(['Relatório de Vendas — VendasIgreja']);
  row(['Período', rangeLabel]);
  row(['Total geral', Money.format(summary.grandTotal)]);
  row(['Vendas', summary.saleCount]);
  row([]);
  row(['Forma de pagamento', 'Total']);
  for (final m in PaymentMethod.values) {
    row([m.label, Money.format(summary.byPayment[m] ?? 0)]);
  }
  row([]);
  row(['Produto', 'Quantidade', 'Total']);
  for (final p in summary.byProduct) {
    row([p.productName, p.quantity, Money.format(p.total)]);
  }

  final dir = await getTemporaryDirectory();
  final file =
      File('${dir.path}/relatorio_${_safeName(rangeLabel)}.xlsx');
  await file.writeAsBytes(book.encode()!);
  return file;
}
