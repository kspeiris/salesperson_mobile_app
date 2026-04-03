import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/theme/app_assets.dart';
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
      subtitle: 'Handle exports, backups, restore flows, and master data imports from one place.',
      headerImageAsset: AppAssets.settingsHero,
      pageBackgroundAsset: AppAssets.pageTexture,
      child: ListView(
        children: [
          SectionCard(
            title: 'Desktop import files',
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.upload_file_outlined,
                  title: 'CSV / JSON export',
                  subtitle: controller.lastExportBundle == null
                      ? 'Generate from Reports screen for manual desktop import.'
                      : 'Latest export files are ready for sharing or saving.',
                ),
                if (controller.lastExportBundle != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _working ? null : () => controller.shareExportBundle(),
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Share files'),
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
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Database backup',
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.backup_outlined,
                  title: 'Create SQLite backup',
                  subtitle: controller.lastBackupPath == null
                      ? 'Create a local .db file copy of the app database.'
                      : 'Last backup saved locally at ${controller.lastBackupPath!.split('/').last}',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _working ? null : _createBackup,
                      icon: const Icon(Icons.backup_outlined),
                      label: const Text('Create backup'),
                    ),
                    if (controller.lastBackupPath != null)
                      OutlinedButton.icon(
                        onPressed: _working ? null : () => _saveBackup(controller.lastBackupPath!),
                        icon: const Icon(Icons.save_alt_outlined),
                        label: const Text('Save backup copy'),
                      ),
                    OutlinedButton.icon(
                      onPressed: _working ? null : _restoreBackup,
                      icon: const Icon(Icons.restore_outlined),
                      label: const Text('Restore backup'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Master data imports',
            child: Column(
              children: [
                _NavTile(
                  icon: Icons.storefront_outlined,
                  title: 'Import shops',
                  subtitle: 'Load CSV or TXT files for offline shop master data.',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopImportScreen())),
                ),
                const SizedBox(height: 12),
                _NavTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'Import products',
                  subtitle: 'Load SKU, pricing, description, and barcode master data.',
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
    final controller = context.read<AppController>();
    final messenger = ScaffoldMessenger.of(context);

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

    final backupPath = await controller.pickBackupFile();
    if (backupPath == null) return;

    setState(() => _working = true);
    await controller.restoreBackup(backupPath);
    if (!mounted) return;
    setState(() => _working = false);
    messenger.showSnackBar(
      SnackBar(content: Text('Backup restored from ${File(backupPath).uri.pathSegments.last}')),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE8E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDDE8E0)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
