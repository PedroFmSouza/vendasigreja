import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../sales/domain/day_summary.dart';
import '../../sales/domain/payment_method.dart';

class SummaryView extends StatelessWidget {
  final DaySummary summary;
  final String title;
  const SummaryView({super.key, required this.summary, required this.title});

  @override
  Widget build(BuildContext context) {
    if (summary.isEmpty) return const _SummaryEmpty();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _GrandTotalCard(summary: summary, title: title),
        const SizedBox(height: 24),
        _SectionTitle('Formas de pagamento'),
        const SizedBox(height: 10),
        _PaymentBreakdown(byPayment: summary.byPayment),
        if (summary.byCategory.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionTitle('Por categoria'),
          const SizedBox(height: 10),
          _CategoryBreakdown(byCategory: summary.byCategory),
        ],
        const SizedBox(height: 20),
        _SectionTitle('Por produto'),
        const SizedBox(height: 10),
        _ProductBreakdown(byProduct: summary.byProduct),
      ],
    );
  }
}

class _GrandTotalCard extends StatelessWidget {
  final DaySummary summary;
  final String title;
  const _GrandTotalCard({required this.summary, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -16,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(
                Money.format(summary.grandTotal),
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(
                      icon: Icons.shopping_bag_outlined,
                      label: '${summary.saleCount} venda(s)'),
                  const SizedBox(width: 8),
                  _InfoChip(
                      icon: Icons.inventory_2_outlined,
                      label: '${summary.byProduct.length} produto(s)'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PaymentBreakdown extends StatelessWidget {
  final Map<PaymentMethod, int> byPayment;
  const _PaymentBreakdown({required this.byPayment});

  @override
  Widget build(BuildContext context) {
    final total =
        byPayment.values.fold<int>(0, (s, v) => s + v);
    return Column(
      children: [
        for (final m in PaymentMethod.values)
          _PaymentRow(method: m, amount: byPayment[m] ?? 0, total: total),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final PaymentMethod method;
  final int amount;
  final int total;
  const _PaymentRow(
      {required this.method, required this.amount, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? amount / total : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: method.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(method.icon, color: method.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(method.label,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
              ),
              Text(
                Money.format(amount),
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: AppColors.bg,
              valueColor: AlwaysStoppedAnimation(method.color),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(pct * 100).round()}%',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final Map<String, int> byCategory;
  const _CategoryBreakdown({required this.byCategory});

  @override
  Widget build(BuildContext context) {
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          for (int i = 0; i < entries.length; i++) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text('${i + 1}',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(entries[i].key,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                  ),
                  Text(
                    Money.format(entries[i].value),
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
            ),
            if (i < entries.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _ProductBreakdown extends StatelessWidget {
  final List<ProductTotal> byProduct;
  const _ProductBreakdown({required this.byProduct});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Cabeçalho
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                    child: Text('Produto',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary))),
                Text('Qtd',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(width: 16),
                SizedBox(
                  width: 80,
                  child: Text('Total',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (int i = 0; i < byProduct.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      byProduct[i].productName,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${byProduct[i].quantity}',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 80,
                    child: Text(
                      Money.format(byProduct[i].total),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            if (i < byProduct.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        fontSize: 11,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _SummaryEmpty extends StatelessWidget {
  const _SummaryEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 52, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhuma venda registrada',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'As vendas do período aparecerão aqui.',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
