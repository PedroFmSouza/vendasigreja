import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../sales/domain/day_summary.dart';
import '../../sales/presentation/sale_providers.dart';

class DateRange {
  final DateTime from;
  final DateTime to;
  const DateRange(this.from, this.to);

  String get fromKey => Dates.dayKey(from);
  String get toKey => Dates.dayKey(to);

  String get label {
    if (fromKey == toKey) return Dates.day(from);
    return '${Dates.day(from)} – ${Dates.day(to)}';
  }
}

final reportRangeProvider =
    NotifierProvider<ReportRangeNotifier, DateRange>(ReportRangeNotifier.new);

class ReportRangeNotifier extends Notifier<DateRange> {
  @override
  DateRange build() {
    final now = DateTime.now();
    return DateRange(
      DateTime(now.year, now.month, now.day),
      DateTime(now.year, now.month, now.day),
    );
  }

  void setRange(DateTime from, DateTime to) =>
      state = DateRange(from, to);

  void setToday() {
    final now = DateTime.now();
    setRange(DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day));
  }

  void setThisWeek() {
    final now = DateTime.now();
    final from = now.subtract(Duration(days: now.weekday - 1));
    setRange(DateTime(from.year, from.month, from.day),
        DateTime(now.year, now.month, now.day));
  }

  void setThisMonth() {
    final now = DateTime.now();
    setRange(DateTime(now.year, now.month, 1),
        DateTime(now.year, now.month, now.day));
  }

  void setAllTime() {
    setRange(DateTime(2024), DateTime.now());
  }
}

final reportSummaryProvider = FutureProvider<DaySummary>((ref) {
  ref.watch(salesRevisionProvider); // recarrega a cada venda/exclusão
  final range = ref.watch(reportRangeProvider);
  return ref.watch(saleRepositoryProvider).summaryByRange(range.fromKey, range.toKey);
});

final reportTotalsPerDayProvider = FutureProvider<Map<String, int>>((ref) {
  ref.watch(salesRevisionProvider); // recarrega a cada venda/exclusão
  final range = ref.watch(reportRangeProvider);
  return ref.watch(saleRepositoryProvider).totalsPerDay(range.fromKey, range.toKey);
});
