import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  runApp(const ProviderScope(child: VendasIgrejaApp()));
}

class VendasIgrejaApp extends StatelessWidget {
  const VendasIgrejaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VendasIgreja',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
