import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BackupService {
  Future<String?> createBackup(String databasePath) async {
    final source = File(databasePath);
    if (!await source.exists()) return null;

    final docs = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(docs.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = p.join(backupDir.path, 'salesperson_backup_$timestamp.db');
    await source.copy(backupPath);
    return backupPath;
  }

  Future<String?> saveBackupCopy(String sourcePath) async {
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save SQLite backup',
      fileName: p.basename(sourcePath),
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
    if (savePath == null) return null;
    await File(sourcePath).copy(savePath);
    return savePath;
  }

  Future<String?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db'],
      allowMultiple: false,
    );
    final filePath = result?.files.single.path;
    return filePath == null || filePath.isEmpty ? null : filePath;
  }
}
