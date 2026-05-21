import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../products/presentation/product_providers.dart';
import '../sales/presentation/sale_providers.dart';
import 'backup_service.dart';
import 'csv_export_service.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(appDatabaseProvider));
});

final csvExportServiceProvider = Provider<CsvExportService>((ref) {
  return CsvExportService(ref.watch(appDatabaseProvider));
});

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) _snack(e.toString(), AppColors.danger, Icons.error_outline);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg,
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ));
  }

  Future<void> _exportDb() => _run(() async {
        await ref.read(backupServiceProvider).exportDatabase();
      });

  Future<void> _exportCsv() => _run(() async {
        await ref.read(csvExportServiceProvider).export();
      });

  Future<void> _restore() => _run(() async {
        final ok = await _confirmRestore();
        if (!ok) return;
        final done =
            await ref.read(backupServiceProvider).restoreDatabase();
        if (done && mounted) {
          ref.invalidate(productListProvider);
          // Força recarga de vendas, caixa e relatórios.
          ref.read(salesRevisionProvider.notifier).bump();
          _snack('Backup restaurado com sucesso.',
              AppColors.success, Icons.check_circle_outline);
        }
      });

  Future<bool> _confirmRestore() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.danger, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Restaurar backup'),
          ],
        ),
        content: const Text(
          'Isso substitui TODOS os dados atuais (produtos e vendas) '
          'pelos dados do arquivo escolhido. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurar',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup e exportação')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ActionCard(
              icon: Icons.storage_rounded,
              iconColor: AppColors.primary,
              title: 'Exportar banco de dados',
              description:
                  'Cópia completa de todos os dados (.db). '
                  'Guarde num local seguro para restaurar se necessário.',
              buttonLabel: 'Exportar .db',
              buttonIcon: Icons.upload_rounded,
              onTap: _busy ? null : _exportDb,
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.table_rows_rounded,
              iconColor: AppColors.success,
              title: 'Exportar CSV',
              description:
                  'Dois arquivos .csv separados por ponto-e-vírgula '
                  '(vendas + itens). Compatível com Excel e Google Sheets.',
              buttonLabel: 'Exportar CSV',
              buttonIcon: Icons.ios_share_rounded,
              onTap: _busy ? null : _exportCsv,
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.restore_rounded,
              iconColor: AppColors.danger,
              title: 'Restaurar backup',
              description:
                  'Substitui os dados atuais pelos de um arquivo .db '
                  'gerado anteriormente.',
              buttonLabel: 'Restaurar de arquivo',
              buttonIcon: Icons.folder_open_rounded,
              outlined: true,
              onTap: _busy ? null : _restore,
            ),
            if (_busy) ...[
              const SizedBox(height: 28),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String buttonLabel;
  final IconData buttonIcon;
  final bool outlined;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.buttonIcon,
    this.outlined = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          outlined
              ? OutlinedButton.icon(
                  onPressed: onTap,
                  icon: Icon(buttonIcon, size: 18),
                  label: Text(buttonLabel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: iconColor,
                    side: BorderSide(color: iconColor, width: 1.5),
                    minimumSize: const Size.fromHeight(46),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: onTap,
                  icon: Icon(buttonIcon, size: 18),
                  label: Text(buttonLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
        ],
      ),
    );
  }
}
