import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../sales/domain/day_summary.dart';
import '../../sales/domain/payment_method.dart';

// ── Wrapper de card de gráfico ────────────────────────────────────────────────

class ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  const ChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

// ── KPI cards ─────────────────────────────────────────────────────────────────

class KpiRow extends StatelessWidget {
  final DaySummary summary;
  const KpiRow({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final avgTicket = summary.saleCount > 0
        ? summary.grandTotal ~/ summary.saleCount
        : 0;
    final bestProduct =
        summary.byProduct.isNotEmpty ? summary.byProduct.first : null;

    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            icon: Icons.attach_money_rounded,
            color: AppColors.success,
            label: 'Ticket médio',
            value: Money.format(avgTicket),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            icon: Icons.star_rounded,
            color: AppColors.accent,
            label: 'Mais vendido',
            value: bestProduct?.productName ?? '—',
            subValue: bestProduct != null
                ? '${bestProduct.quantity} un.'
                : null,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? subValue;

  const _KpiCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          if (subValue != null)
            Text(subValue!,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Gráfico de pizza — pagamentos ─────────────────────────────────────────────

class PaymentPieChart extends StatefulWidget {
  final Map<PaymentMethod, int> byPayment;
  const PaymentPieChart({super.key, required this.byPayment});

  @override
  State<PaymentPieChart> createState() => _PaymentPieChartState();
}

class _PaymentPieChartState extends State<PaymentPieChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.byPayment.values.fold<int>(0, (s, v) => s + v);
    if (total == 0) return const _NoData();

    final entries =
        widget.byPayment.entries.where((e) => e.value > 0).toList();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 48,
              pieTouchData: PieTouchData(
                touchCallback: (event, resp) {
                  setState(() {
                    _touched = (!event.isInterestedForInteractions ||
                            resp == null ||
                            resp.touchedSection == null)
                        ? -1
                        : resp.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: [
                for (int i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    value: entries[i].value.toDouble(),
                    color: entries[i].key.color,
                    radius: _touched == i ? 52 : 44,
                    title: _touched == i
                        ? '${(entries[i].value / total * 100).round()}%'
                        : '',
                    titleStyle: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
              ],
            ),
          ),
        ),
        // Centro estático com total
        Transform.translate(
          offset: const Offset(0, -12),
          child: Column(
            children: [
              Text('Total',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text(Money.format(total),
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final e in entries)
              _PaymentLegendItem(method: e.key, amount: e.value, total: total),
          ],
        ),
      ],
    );
  }
}

class _PaymentLegendItem extends StatelessWidget {
  final PaymentMethod method;
  final int amount;
  final int total;
  const _PaymentLegendItem(
      {required this.method, required this.amount, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (amount / total * 100).round() : 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: method.color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text('${method.label} · $pct% · ${Money.format(amount)}',
            style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Gráfico de pizza — categorias ────────────────────────────────────────────

class CategoryPieChart extends StatefulWidget {
  final Map<String, int> byCategory;
  const CategoryPieChart({super.key, required this.byCategory});

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touched = -1;

  static const _palette = [
    AppColors.primary,
    AppColors.pix,
    AppColors.accent,
    AppColors.card,
    AppColors.success,
    AppColors.danger,
    Color(0xFF7B1FA2),
    Color(0xFF00838F),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = widget.byCategory.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = entries.fold<int>(0, (s, e) => s + e.value);
    if (total == 0) return const _NoData();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 48,
              pieTouchData: PieTouchData(
                touchCallback: (event, resp) {
                  setState(() {
                    _touched = (!event.isInterestedForInteractions ||
                            resp == null ||
                            resp.touchedSection == null)
                        ? -1
                        : resp.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: [
                for (int i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    value: entries[i].value.toDouble(),
                    color: _palette[i % _palette.length],
                    radius: _touched == i ? 52 : 44,
                    title: _touched == i
                        ? '${(entries[i].value / total * 100).round()}%'
                        : '',
                    titleStyle: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
              ],
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -12),
          child: Column(
            children: [
              Text('Total',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text(Money.format(total),
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (int i = 0; i < entries.length; i++)
              _LegendItem(
                color: _palette[i % _palette.length],
                label: entries[i].key,
                amount: entries[i].value,
                total: total,
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int amount;
  final int total;
  const _LegendItem(
      {required this.color,
      required this.label,
      required this.amount,
      required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (amount / total * 100).round() : 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text('$label · $pct% · ${Money.format(amount)}',
            style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Barras top produtos ───────────────────────────────────────────────────────

class TopProductsChart extends StatelessWidget {
  final List<ProductTotal> byProduct;
  final int limit;

  const TopProductsChart({
    super.key,
    required this.byProduct,
    this.limit = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (byProduct.isEmpty) return const _NoData();
    final top = byProduct.take(limit).toList();
    final maxVal = top.first.total.toDouble();

    return Column(
      children: [
        for (int i = 0; i < top.length; i++) ...[
          _ProductBar(
            rank: i + 1,
            item: top[i],
            ratio: maxVal > 0 ? top[i].total / maxVal : 0,
          ),
          if (i < top.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ProductBar extends StatelessWidget {
  final int rank;
  final ProductTotal item;
  final double ratio;
  const _ProductBar(
      {required this.rank, required this.item, required this.ratio});

  static const _barColors = [
    AppColors.primary,
    Color(0xFF1976D2),
    Color(0xFF1E88E5),
    Color(0xFF2196F3),
    Color(0xFF42A5F5),
    Color(0xFF64B5F6),
    Color(0xFF90CAF9),
    Color(0xFFBBDEFB),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _barColors[rank <= _barColors.length ? rank - 1 : _barColors.length - 1];
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            '$rank',
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: rank == 1 ? AppColors.accent : AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            item.productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: ratio.clamp(0.03, 1.0),
                child: Container(
                  height: 22,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      '${item.quantity}un',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            Money.format(item.total),
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

// ── Linha de evolução diária ──────────────────────────────────────────────────

class DailyTotalsChart extends StatefulWidget {
  final Map<String, int> totalsPerDay;
  const DailyTotalsChart({super.key, required this.totalsPerDay});

  @override
  State<DailyTotalsChart> createState() => _DailyTotalsChartState();
}

class _DailyTotalsChartState extends State<DailyTotalsChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.totalsPerDay.isEmpty) {
      return const _NoData(message: 'Sem dados no período');
    }
    if (widget.totalsPerDay.length < 2) {
      return const _NoData(message: 'Disponível com 2+ dias de vendas');
    }

    final keys = widget.totalsPerDay.keys.toList()..sort();
    final values = keys.map((k) => widget.totalsPerDay[k]! / 100).toList();
    final maxY = values.reduce((a, b) => a > b ? a : b);

    final spots = [
      for (int i = 0; i < keys.length; i++) FlSpot(i.toDouble(), values[i]),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY * 1.25,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: AppColors.divider,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchCallback: (event, resp) {
                  setState(() {
                    _touchedIndex = resp?.lineBarSpots?.first.spotIndex;
                  });
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.primaryDark,
                  getTooltipItems: (spots) => spots
                      .map((s) => LineTooltipItem(
                            Money.format((s.y * 100).round()),
                            GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                          ))
                      .toList(),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 56,
                    interval: maxY > 0 ? maxY / 4 : 1,
                    getTitlesWidget: (value, meta) => Text(
                      Money.format((value * 100).round()),
                      style: GoogleFonts.inter(
                          fontSize: 9, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: keys.length > 7
                        ? (keys.length / 5).ceilToDouble()
                        : 1,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= keys.length) {
                        return const SizedBox.shrink();
                      }
                      final parts = keys[i].split('-');
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${parts[2]}/${parts[1]}',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              color: _touchedIndex == i
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: _touchedIndex == i
                                  ? FontWeight.w700
                                  : FontWeight.w400),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: AppColors.primary,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, i) =>
                        FlDotCirclePainter(
                      radius: _touchedIndex == i ? 6 : 3,
                      color: AppColors.primary,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.18),
                        AppColors.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_touchedIndex != null && _touchedIndex! < keys.length) ...[
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${Dates.day(DateTime.parse(keys[_touchedIndex!]))} · '
                '${Money.format(widget.totalsPerDay[keys[_touchedIndex!]]!)}',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Gráfico de barras agrupadas por categoria ─────────────────────────────────

class CategoryBarChart extends StatelessWidget {
  final Map<String, int> byCategory;
  const CategoryBarChart({super.key, required this.byCategory});

  @override
  Widget build(BuildContext context) {
    if (byCategory.isEmpty) return const _NoData();

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.first.value.toDouble();

    final barColors = [
      AppColors.primary,
      AppColors.pix,
      AppColors.accent,
      AppColors.card,
      AppColors.success,
      AppColors.danger,
    ];

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.25,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.primaryDark,
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                '${sorted[groupIndex].key}\n',
                GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
                children: [
                  TextSpan(
                    text: Money.format(sorted[groupIndex].value),
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= sorted.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      sorted[i].key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 10, color: AppColors.textSecondary),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < sorted.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: sorted[i].value.toDouble(),
                    color: barColors[i % barColors.length],
                    width: 28,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ── Histórico por dia ─────────────────────────────────────────────────────────

class DailyHistoryList extends StatelessWidget {
  final Map<String, int> totalsPerDay;
  const DailyHistoryList({super.key, required this.totalsPerDay});

  @override
  Widget build(BuildContext context) {
    if (totalsPerDay.isEmpty) return const _NoData();

    final keys = totalsPerDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final maxVal = totalsPerDay.values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        for (int i = 0; i < keys.length; i++) ...[
          _DayRow(
            date: keys[i],
            amount: totalsPerDay[keys[i]]!,
            ratio: maxVal > 0 ? totalsPerDay[keys[i]]! / maxVal : 0,
            isTop: totalsPerDay[keys[i]] == maxVal,
          ),
          if (i < keys.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final String date;
  final int amount;
  final double ratio;
  final bool isTop;
  const _DayRow({
    required this.date,
    required this.amount,
    required this.ratio,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(date);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTop
            ? AppColors.accent.withValues(alpha: 0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTop ? AppColors.accent.withValues(alpha: 0.3) : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          if (isTop)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.emoji_events_rounded,
                  size: 16, color: AppColors.accent),
            ),
          SizedBox(
            width: 80,
            child: Text(
              dt != null ? Dates.day(dt) : date,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isTop ? AppColors.accent : AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: AppColors.bg,
                valueColor: AlwaysStoppedAnimation(
                  isTop ? AppColors.accent : AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            Money.format(amount),
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isTop ? AppColors.accent : AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

// ── Utilitários ───────────────────────────────────────────────────────────────

class _NoData extends StatelessWidget {
  final String message;
  const _NoData({this.message = 'Sem dados no período'});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(message,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
