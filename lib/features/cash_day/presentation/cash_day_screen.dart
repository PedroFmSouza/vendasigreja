import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../sales/domain/sale.dart';
import '../../sales/presentation/sale_providers.dart';
import 'cash_day_providers.dart';
import 'summary_view.dart';

class CashDayScreen extends ConsumerWidget {
  const CashDayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Caixa do dia'),
          bottom: const TabBar(
            indicatorColor: AppColors.accent,
            tabs: [
              Tab(text: 'Resumo'),
              Tab(text: 'Vendas'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SummaryTab(),
            _SalesTab(),
          ],
        ),
      ),
    );
  }
}

class _SummaryTab extends ConsumerWidget {
  const _SummaryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(todaySummaryProvider);
    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (summary) => SummaryView(
        summary: summary,
        title: 'Caixa de ${Dates.day(DateTime.now())}',
      ),
    );
  }
}

class _SalesTab extends ConsumerWidget {
  const _SalesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(todaySalesProvider);
    return salesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (sales) {
        if (sales.isEmpty) {
          return const Center(
            child: Text(
              'Nenhuma venda hoje',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: sales.length,
          itemBuilder: (_, i) => _SaleTile(sale: sales[i]),
        );
      },
    );
  }
}

class _SaleTile extends ConsumerWidget {
  final Sale sale;
  const _SaleTile({required this.sale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name =
        sale.items.isNotEmpty ? sale.items.first.productName : 'Venda';
    final method = sale.paymentMethod;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: method.color.withValues(alpha: 0.15),
          child: Icon(method.icon, color: method.color, size: 20),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${Dates.time(sale.soldAt)} • ${method.label}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Money.format(sale.totalAmount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.danger),
              onPressed: () => _confirmDelete(context, ref, name),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir venda'),
        content: Text(
          'Excluir a venda de "$name" (${Money.format(sale.totalAmount)})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true && sale.id != null) {
      await ref.read(todaySalesProvider.notifier).undo(sale.id!);
    }
  }
}
