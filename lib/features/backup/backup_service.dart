import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/data/app_database.dart';

/// Exporta e restaura o arquivo SQLite do app.
class BackupService {
  final AppDatabase _appDb;
  BackupService(this._appDb);

  /// Copia o banco para um arquivo temporário datado e abre o share sheet.
  Future<void> exportDatabase() async {
    final dbPath = await _appDb.path();
    final source = File(dbPath);
    if (!await source.exists()) {
      throw const BackupException('Banco de dados não encontrado.');
    }

    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final tmp = await getTemporaryDirectory();
    final dest = File('${tmp.path}/vendasigreja_backup_$stamp.db');
    await source.copy(dest.path);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(dest.path)],
        text: 'Backup VendasIgreja — $stamp',
      ),
    );
  }

  /// Substitui o banco atual por um arquivo escolhido pelo usuário.
  /// Retorna false se o usuário cancelar a seleção.
  Future<bool> restoreDatabase() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      withData: false,
    );
    if (result == null || result.files.single.path == null) {
      return false;
    }

    final picked = File(result.files.single.path!);
    if (!picked.path.toLowerCase().endsWith('.db')) {
      throw const BackupException('Selecione um arquivo .db válido.');
    }

    // Fecha a conexão antes de sobrescrever o arquivo.
    await _appDb.close();
    final dbPath = await _appDb.path();
    await picked.copy(dbPath);
    // Próximo acesso reabre a conexão automaticamente.
    return true;
  }
}

class BackupException implements Exception {
  final String message;
  const BackupException(this.message);
  @override
  String toString() => message;
}
