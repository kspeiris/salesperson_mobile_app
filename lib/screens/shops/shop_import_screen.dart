import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/theme/app_assets.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/section_card.dart';
import '../../models/entities.dart';

class ShopImportScreen extends StatefulWidget {
  const ShopImportScreen({super.key});

  @override
  State<ShopImportScreen> createState() => _ShopImportScreenState();
}

class _ShopImportScreenState extends State<ShopImportScreen> {
  bool _replaceExisting = false;
  bool _working = false;
  ImportResult? _result;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Import Shops',
      subtitle:
          'Bring in shop master data from a flat file and review any row-level issues before continuing.',
      headerImageAsset: AppAssets.shopsHero,
      pageBackgroundAsset: AppAssets.pageTexture,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          SectionCard(
            title: 'Expected columns',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use a header row with these columns so shop records and balances map correctly.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FDF8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8F5E9)),
                  ),
                  child: const SelectableText(
                      'name,owner_contact,area,phone,credit_limit,balance'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Import options',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose whether this file should replace the current shop list or merge into it.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  value: _replaceExisting,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Replace existing shop records'),
                  subtitle: const Text(
                      'Deletes current shop master data before import.'),
                  onChanged: (value) =>
                      setState(() => _replaceExisting = value),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _working ? null : _pickAndImport,
                  icon: _working
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.file_open_outlined),
                  label: Text(_working ? 'Importing...' : 'Pick CSV/TXT file'),
                ),
              ],
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            _ImportSummaryCard(result: _result!),
          ],
        ],
      ),
    );
  }

  Future<void> _pickAndImport() async {
    final controller = context.read<AppController>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() => _working = true);
    try {
      final importResult = await controller.importShopsFromFile(path,
          replaceExisting: _replaceExisting);
      if (!mounted) return;
      setState(() {
        _working = false;
        _result = importResult;
      });
      messenger.showSnackBar(
        SnackBar(content: Text(importResult.summary)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _working = false);
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _ImportSummaryCard extends StatelessWidget {
  const _ImportSummaryCard({required this.result});

  final ImportResult result;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Import result',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.summary,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Issues',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...result.errors.take(10).map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: SelectableText('- $entry',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ),
            if (result.errors.length > 10) ...[
              const SizedBox(height: 6),
              Text(
                '${result.errors.length - 10} more issue(s) not shown.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
