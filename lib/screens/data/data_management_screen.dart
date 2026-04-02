import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/section_card.dart';
import '../products/product_import_screen.dart';
import '../shops/shop_import_screen.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    return AppShell(
      title: 'Data Management',
      child: ListView(
        children: [
          SectionCard(
            title: 'Desktop Import Files',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.upload_file_outlined)),
                  title: const Text('CSV / JSON export', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(controller.lastExportBundle == null
                      ? 'Generate from Reports screen for manual desktop import.'
                      : 'Last files are ready for sharing or saving.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
                if (controller.lastExportBundle != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _working ? null : () => controller.shareExportBundle(),
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Share Files'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _working ? null : () => _saveExport(controller.lastExportBundle!.csvFile),
                          icon: const Icon(Icons.save_alt_outlined),
                          label: const Text('Save CSV'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _working ? null : () => _saveExport(controller.lastExportBundle!.jsonFile),
                          icon: const Icon(Icons.code_outlined),
                          label: const Text('Save JSON'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Database Backup',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.backup_outlined)),
                  title: const Text('Create SQLite backup', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(controller.lastBackupPath == null
                      ? 'Create a local .db file copy of the app database.'
                      : 'Last backup saved locally at ${controller.lastBackupPath!.split('/').last}'),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _working ? null : _createBackup,
                      icon: const Icon(Icons.backup_outlined),
                      label: const Text('Create Backup'),
                    ),
                    if (controller.lastBackupPath != null)
                      OutlinedButton.icon(
                        onPressed: _working ? null : () => _saveBackup(controller.lastBackupPath!),
                        icon: const Icon(Icons.save_alt_outlined),
                        label: const Text('Save Backup Copy'),
                      ),
                    OutlinedButton.icon(
                      onPressed: _working ? null : _restoreBackup,
                      icon: const Icon(Icons.restore_outlined),
                      label: const Text('Restore Backup'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Master Data Imports',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.storefront_outlined)),
                  title: const Text('Import Shops', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Load CSV or JSON-like text files for offline shop master data.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopImportScreen())),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
                  title: const Text('Import Products', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Load SKU, pricing, description, and barcode master data.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductImportScreen())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveExport(String path) async {
    setState(() => _working = true);
    final savedPath = await context.read<AppController>().saveExportCopy(path);
    if (!mounted) return;
    setState(() => _working = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(savedPath == null ? 'Save cancelled.' : 'Saved to $savedPath')),
    );
  }

  Future<void> _createBackup() async {
    setState(() => _working = true);
    final backupPath = await context.read<AppController>().createBackup();
    if (!mounted) return;
    setState(() => _working = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(backupPath == null ? 'Backup failed.' : 'Backup created at $backupPath')),
    );
  }

  Future<void> _saveBackup(String path) async {
    setState(() => _working = true);
    final savedPath = await context.read<AppController>().saveBackupCopy(path);
    if (!mounted) return;
    setState(() => _working = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(savedPath == null ? 'Save cancelled.' : 'Backup copy saved to $savedPath')),
    );
  }

  Future<void> _restoreBackup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore database backup?'),
        content: const Text('This replaces the current local SQLite database with the selected backup file.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
        ],
      ),
    );
    if (confirm != true) return;

    final backupPath = await context.read<AppController>().pickBackupFile();
    if (backupPath == null) return;

    setState(() => _working = true);
    await context.read<AppController>().restoreBackup(backupPath);
    if (!mounted) return;
    setState(() => _working = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backup restored from ${File(backupPath).uri.pathSegments.last}')),
    );
  }
}
