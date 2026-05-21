import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../products/domain/product.dart';
import '../../products/presentation/product_providers.dart';
import '../domain/payment_method.dart';
import '../domain/sale.dart';
import 'sale_providers.dart';

class SaleScreen extends ConsumerWidget {
  const SaleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(activeProductsProvider);
    final selectedPayment = ref.watch(selectedPaymentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Vender')),
      body: Column(
        children: [
          _PaymentSelector(selected: selectedPayment),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (products) => products.isEmpty
                  ? const _NoProducts()
                  : _ProductGrid(products: products, payment: selectedPayment),
            ),
          ),
          const _BottomBar(),
        ],
      ),
    );
  }
}

// ── Seletor de pagamento ──────────────────────────────────────────────────────

class _PaymentSelector extends ConsumerWidget {
  final PaymentMethod selected;
  const _PaymentSelector({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          for (final m in PaymentMethod.values) ...[
            Expanded(
              child: _PaymentChip(
                method: m,
                selected: m == selected,
                onTap: () =>
                    ref.read(selectedPaymentProvider.notifier).select(m),
              ),
            ),
            if (m != PaymentMethod.values.last) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentChip(
      {required this.method, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? method.color : AppColors.bg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: method.color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
          border: Border.all(
            color: selected ? method.color : AppColors.divider,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(method.icon,
                color: selected ? Colors.white : AppColors.textSecondary,
                size: 22),
            const SizedBox(height: 5),
            Text(
              method.label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grid de produtos ──────────────────────────────────────────────────────────

class _ProductGrid extends ConsumerWidget {
  final List<Product> products;
  final PaymentMethod payment;
  const _ProductGrid({required this.products, required this.payment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => _ProductButton(
        product: products[i],
        onTap: () => _sell(context, ref, products[i]),
      ),
    );
  }

  Future<void> _sell(
      BuildContext context, WidgetRef ref, Product product) async {
    HapticFeedback.lightImpact();
    final quantity = await showDialog<int>(
      context: context,
      builder: (_) => _SellConfirmDialog(product: product, payment: payment),
    );
    if (quantity == null || !context.mounted) return;
    await ref
        .read(todaySalesProvider.notifier)
        .quickSell(product, payment, quantity: quantity);
    if (!context.mounted) return;
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        duration: const Duration(milliseconds: 1400),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${quantity}x ${product.name} — '
                '${Money.format(product.price * quantity)}',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
          ],
        ),
      ));
  }
}

class _ProductButton extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _ProductButton({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.fastfood_rounded,
                    size: 18, color: AppColors.primary),
              ),
              const Spacer(),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                Money.format(product.price),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dialog de confirmação com quantidade ──────────────────────────────────────

class _SellConfirmDialog extends StatefulWidget {
  final Product product;
  final PaymentMethod payment;
  const _SellConfirmDialog({required this.product, required this.payment});

  @override
  State<_SellConfirmDialog> createState() => _SellConfirmDialogState();
}

class _SellConfirmDialogState extends State<_SellConfirmDialog> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final total = widget.product.price * _qty;
    final m = widget.payment;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: m.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(m.icon, color: m.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, fontSize: 16,
                              color: AppColors.textPrimary)),
                      Text(m.label,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: m.color,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Seletor de quantidade
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QtyButton(
                    icon: Icons.remove_rounded,
                    onTap: _qty > 1 ? () => setState(() => _qty--) : null,
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Text(
                      '$_qty',
                      key: ValueKey(_qty),
                      style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  _QtyButton(
                    icon: Icons.add_rounded,
                    onTap: () => setState(() => _qty++),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Total
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text('Total',
                      style: GoogleFonts.inter(
                          color: Colors.white60, fontSize: 12)),
                  Text(Money.format(total),
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Ações
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, _qty),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? AppColors.primary : AppColors.divider,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Icon(icon,
            color: enabled ? Colors.white : AppColors.textSecondary, size: 22),
      ),
    );
  }
}

// ── Barra inferior ────────────────────────────────────────────────────────────

class _BottomBar extends ConsumerWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(todaySalesProvider);
    final sales = salesAsync.value ?? const <Sale>[];
    final total = sales.fold<int>(0, (sum, s) => sum + s.totalAmount);
    final lastSale = sales.isNotEmpty ? sales.first : null;

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total hoje • ${sales.length} venda(s)',
                    style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Money.format(total),
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            if (lastSale != null)
              TextButton.icon(
                onPressed: () => _undo(context, ref, lastSale),
                icon: const Icon(Icons.undo_rounded,
                    color: Colors.white70, size: 18),
                label: Text('Desfazer',
                    style: GoogleFonts.inter(
                        color: Colors.white70, fontWeight: FontWeight.w500)),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _undo(
      BuildContext context, WidgetRef ref, Sale sale) async {
    await ref.read(todaySalesProvider.notifier).undo(sale.id!);
    if (!context.mounted) return;
    final name =
        sale.items.isNotEmpty ? sale.items.first.productName : 'Venda';
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text('$name removida',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
      ));
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _NoProducts extends StatelessWidget {
  const _NoProducts();

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
              child: const Icon(Icons.storefront_outlined,
                  size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhum produto ativo',
              style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Cadastre produtos para começar a vender.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
