import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../domain/product.dart';
import 'product_form_sheet.dart';
import 'product_providers.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Produtos')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 3,
        onPressed: () => ProductFormSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: Text('Novo produto',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (products) {
          if (products.isEmpty) {
            return _EmptyState(onAdd: () => ProductFormSheet.show(context));
          }
          final grouped = _groupByCategory(products);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              for (final entry in grouped.entries) ...[
                _CategoryHeader(label: entry.key, count: entry.value.length),
                const SizedBox(height: 8),
                for (final p in entry.value) _ProductTile(product: p),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }

  Map<String, List<Product>> _groupByCategory(List<Product> products) {
    final map = <String, List<Product>>{};
    for (final p in products) {
      map.putIfAbsent(p.category, () => []).add(p);
    }
    return map;
  }
}

class _CategoryHeader extends StatelessWidget {
  final String label;
  final int count;
  const _CategoryHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            fontSize: 11,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _ProductTile extends ConsumerWidget {
  final Product product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(productListProvider.notifier);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: product.active ? AppColors.divider : AppColors.divider,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => ProductFormSheet.show(context, product: product),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Ícone de status
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: product.active
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.fastfood_rounded,
                    size: 20,
                    color: product.active
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                // Nome e preço
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: product.active
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          decoration: product.active
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Money.format(product.price),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: product.active
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Switch
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: product.active,
                    activeThumbColor: AppColors.success,
                    onChanged: (_) => notifier.toggleActive(product),
                  ),
                ),
                // Delete
                GestureDetector(
                  onTap: () => _confirmDelete(context, ref),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.danger, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir produto'),
        content: Text(
          'Excluir "${product.name}"? Vendas já registradas não são afetadas.',
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
    if (ok == true && product.id != null) {
      await ref.read(productListProvider.notifier).removeProduct(product.id!);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  size: 52, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhum produto cadastrado',
              style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Adicione os produtos que serão vendidos na festa.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Cadastrar primeiro produto'),
            ),
          ],
        ),
      ),
    );
  }
}
