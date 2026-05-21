import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../domain/sale.dart';
import 'sale_providers.dart';

class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Histórico de vendas'),
      ),
      body: salesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erro: $e',
              style: GoogleFonts.inter(color: AppColors.danger)),
        ),
        data: (sales) {
          if (sales.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        size: 40, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Text('Nenhuma venda registrada',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ],
              ),
            );
          }

          // Group by date label (dd/MM/yyyy)
          final grouped = <String, List<Sale>>{};
          for (final s in sales) {
            final key = Dates.day(s.soldAt.toLocal());
            grouped.putIfAbsent(key, () => []).add(s);
          }
          final dateKeys = grouped.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: dateKeys.length,
            itemBuilder: (context, idx) {
              final dateLabel = dateKeys[idx];
              final daySales = grouped[dateLabel]!;
              final dayTotal =
                  daySales.fold<int>(0, (s, v) => s + v.totalAmount);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (idx != 0) const SizedBox(height: 20),
                  // Date header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 12, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(dateLabel,
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${daySales.length} venda(s) · ${Money.format(dayTotal)}',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...daySales.map((sale) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SaleCard(sale: sale),
                      )),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SaleCard extends ConsumerWidget {
  final Sale sale;
  const _SaleCard({required this.sale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final method = sale.paymentMethod;
    final time = Dates.time(sale.soldAt.toLocal());

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: method.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(method.icon, size: 18, color: method.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(method.label,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      Text(time,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Text(
                  Money.format(sale.totalAmount),
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 20, color: AppColors.danger),
                  tooltip: 'Cancelar venda',
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ),
          // Items list
          if (sale.items.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Column(
                children: sale.items
                    .map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${item.quantity}× ${item.productName}',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                              Text(
                                Money.format(item.subtotal),
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.danger, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Cancelar venda'),
          ],
        ),
        content: const Text(
            'Esta venda será removida permanentemente. Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar venda',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(salesHistoryProvider.notifier)
          .deleteSale(sale.id!);
    }
  }
}
