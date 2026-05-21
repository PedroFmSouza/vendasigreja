import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../features/backup/backup_screen.dart';
import '../../features/cash_day/presentation/cash_day_providers.dart';
import '../../features/cash_day/presentation/cash_day_screen.dart';
import '../../features/products/presentation/products_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/sales/presentation/sale_screen.dart';
import '../../features/sales/presentation/sales_history_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.receipt_long_rounded, color: Colors.white70),
          tooltip: 'Histórico de vendas',
          onPressed: () => _go(context, const SalesHistoryScreen()),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.church, size: 20, color: Colors.white70),
            const SizedBox(width: 8),
            Text('VendasIgreja',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                    color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.backup_outlined),
            tooltip: 'Backup e exportação',
            onPressed: () => _go(context, const BackupScreen()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          const _TodayCard(),
          const SizedBox(height: 24),
          Text(
            'O QUE DESEJA FAZER?',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: [
              _MenuCard(
                icon: Icons.point_of_sale_rounded,
                label: 'Vender',
                subtitle: 'Registrar venda',
                gradient: AppColors.successGradient,
                onTap: () => _go(context, const SaleScreen()),
              ),
              _MenuCard(
                icon: Icons.inventory_2_rounded,
                label: 'Produtos',
                subtitle: 'Gerenciar catálogo',
                gradient: AppColors.primaryGradient,
                onTap: () => _go(context, const ProductsScreen()),
              ),
              _MenuCard(
                icon: Icons.receipt_long_rounded,
                label: 'Caixa do dia',
                subtitle: 'Ver resumo',
                gradient: AppColors.accentGradient,
                onTap: () => _go(context, const CashDayScreen()),
              ),
              _MenuCard(
                icon: Icons.bar_chart_rounded,
                label: 'Relatórios',
                subtitle: 'Análises e gráficos',
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
                ),
                onTap: () => _go(context, const ReportsScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }
}

class _TodayCard extends ConsumerWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(todaySummaryProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decoração de fundo
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          Dates.day(DateTime.now()),
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Total de hoje',
                style: GoogleFonts.inter(
                    color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              summaryAsync.when(
                loading: () => Text('...', style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                error: (_, _) => Text('—', style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                data: (s) => Text(
                  Money.format(s.grandTotal),
                  style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 6),
              summaryAsync.maybeWhen(
                data: (s) => Row(
                  children: [
                    _StatChip(
                        icon: Icons.shopping_bag_outlined,
                        label: '${s.saleCount} venda(s)'),
                    if (s.byPayment.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _StatChip(
                          icon: Icons.category_outlined,
                          label: '${s.byProduct.length} produto(s)'),
                    ],
                  ],
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

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
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.last.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const Spacer(),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
