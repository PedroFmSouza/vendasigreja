import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../sales/domain/day_summary.dart';
import '../../sales/presentation/sale_providers.dart';

/// Resumo do caixa de hoje. Refaz quando as vendas de hoje mudam.
final todaySummaryProvider = FutureProvider<DaySummary>((ref) async {
  ref.watch(todaySalesProvider);
  final days = ref.watch(cashDayRepositoryProvider);
  final sales = ref.watch(saleRepositoryProvider);
  final day = await days.getOrCreate(Dates.todayKey());
  return sales.summaryByDay(day.id!);
});
