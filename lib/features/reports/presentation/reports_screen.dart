import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../cash_day/presentation/summary_view.dart';
import '../../sales/domain/day_summary.dart';
import '../data/report_exporter.dart';
import 'report_charts.dart';
import 'report_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(reportRangeProvider);
    final summaryAsync = ref.watch(reportSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Relatórios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Escolher período',
            onPressed: () => _pickRange(context, ref),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.accent,
          labelStyle:
              GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Detalhado'),
            Tab(text: 'Histórico'),
          ],
        ),
      ),
      floatingActionButton: summaryAsync.maybeWhen(
        data: (s) => s.isEmpty
            ? null
            : FloatingActionButton.extended(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.ios_share_rounded),
                label: Text('Exportar',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                onPressed: () => _export(context, ref, s),
              ),
        orElse: () => null,
      ),
      body: Column(
        children: [
          _PeriodBar(range: range, onPickRange: () => _pickRange(context, ref)),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _DashboardTab(),
                _DetailedTab(),
                _HistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref
          .read(reportRangeProvider.notifier)
          .setRange(picked.start, picked.end);
    }
  }

  Future<void> _export(
      BuildContext context, WidgetRef ref, DaySummary summary) async {
    final range = ref.read(reportRangeProvider);
    await showExportSheet(context, summary: summary, rangeLabel: range.label);
  }
}

// ── Barra de período com atalhos ──────────────────────────────────────────────

class _PeriodBar extends ConsumerWidget {
  final DateRange range;
  final VoidCallback onPickRange;
  const _PeriodBar({required this.range, required this.onPickRange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(reportRangeProvider.notifier);
    final now = DateTime.now();
    final todayKey = Dates.dayKey(now);
    final isToday =
        range.fromKey == todayKey && range.toKey == todayKey;

    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final isWeek = range.fromKey == Dates.dayKey(weekStart) &&
        range.toKey == todayKey;

    final isMonth = range.fromKey == Dates.dayKey(DateTime(now.year, now.month, 1)) &&
        range.toKey == todayKey;

    final isAll = range.fromKey == Dates.dayKey(DateTime(2024)) &&
        range.toKey != todayKey
        ? false
        : range.fromKey == Dates.dayKey(DateTime(2024));

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          // Atalhos rápidos
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                _QuickChip(
                  label: 'Hoje',
                  selected: isToday,
                  onTap: notifier.setToday,
                ),
                const SizedBox(width: 8),
                _QuickChip(
                  label: 'Semana',
                  selected: isWeek,
                  onTap: notifier.setThisWeek,
                ),
                const SizedBox(width: 8),
                _QuickChip(
                  label: 'Mês',
                  selected: isMonth,
                  onTap: notifier.setThisMonth,
                ),
                const SizedBox(width: 8),
                _QuickChip(
                  label: 'Tudo',
                  selected: isAll && !isToday && !isWeek && !isMonth,
                  onTap: notifier.setAllTime,
                ),
                const SizedBox(width: 8),
                _QuickChip(
                  label: 'Personalizado',
                  icon: Icons.calendar_month_rounded,
                  selected: false,
                  onTap: onPickRange,
                ),
              ],
            ),
          ),
          // Label do período selecionado
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.date_range_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  range.label,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  const _QuickChip(
      {required this.label,
      required this.selected,
      required this.onTap,
      this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: selected ? Colors.white : AppColors.primary),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab: Dashboard ────────────────────────────────────────────────────────────

class _DashboardTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(reportSummaryProvider);
    final totalsAsync = ref.watch(reportTotalsPerDayProvider);

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => _ErrorState(error: e.toString()),
      data: (summary) {
        if (summary.isEmpty) return const _EmptyState();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            // KPI cards no topo
            KpiRow(summary: summary),
            const SizedBox(height: 16),

            // Pizza de categorias
            ChartCard(
              title: 'Categorias',
              subtitle: 'Distribuição por categoria',
              child: CategoryPieChart(byCategory: summary.byCategory),
            ),
            const SizedBox(height: 12),

            // Evolução diária (só mostra se há dados do provider)
            ChartCard(
              title: 'Evolução por dia',
              subtitle: 'Receita acumulada',
              child: totalsAsync.when(
                loading: () => const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator())),
                error: (e, st) => _ErrorState(error: e.toString()),
                data: (totals) => DailyTotalsChart(totalsPerDay: totals),
              ),
            ),
            const SizedBox(height: 12),

            // Top produtos
            ChartCard(
              title: 'Produtos mais vendidos',
              subtitle: 'Por receita gerada',
              child: TopProductsChart(byProduct: summary.byProduct),
            ),
            const SizedBox(height: 12),

          ],
        );
      },
    );
  }
}

// ── Tab: Detalhado ────────────────────────────────────────────────────────────

class _DetailedTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(reportSummaryProvider);
    final range = ref.watch(reportRangeProvider);

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => _ErrorState(error: e.toString()),
      data: (summary) {
        if (summary.isEmpty) return const _EmptyState();
        return SummaryView(
          summary: summary,
          title: 'Período: ${range.label}',
        );
      },
    );
  }
}

// ── Tab: Histórico ────────────────────────────────────────────────────────────

class _HistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(reportTotalsPerDayProvider);
    final summaryAsync = ref.watch(reportSummaryProvider);

    return totalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => _ErrorState(error: e.toString()),
      data: (totals) {
        if (totals.isEmpty) return const _EmptyState();

        final totalValue = summaryAsync.maybeWhen(
            data: (s) => s.grandTotal, orElse: () => 0);
        final dayCount = totals.length;
        final avgPerDay = dayCount > 0 ? totalValue ~/ dayCount : 0;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            // Sumário de dias
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    icon: Icons.calendar_today_rounded,
                    color: AppColors.primary,
                    label: 'Dias de venda',
                    value: '$dayCount',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatBox(
                    icon: Icons.trending_up_rounded,
                    color: AppColors.success,
                    label: 'Média por dia',
                    value: Money.format(avgPerDay),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lista de dias
            ChartCard(
              title: 'Ranking de dias',
              subtitle: 'Melhor dia em destaque',
              child: DailyHistoryList(totalsPerDay: totals),
            ),
          ],
        );
      },
    );
  }
}

// ── StatBox ───────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _StatBox(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Estados de vazio / erro ───────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.bar_chart_rounded,
                size: 40, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Text('Nenhuma venda no período',
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('Selecione outro intervalo de datas',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 36, color: AppColors.danger),
          const SizedBox(height: 12),
          Text('Erro ao carregar dados',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
