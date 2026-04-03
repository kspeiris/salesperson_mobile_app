import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/theme/app_assets.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/section_card.dart';
import '../../models/entities.dart';

class ProductImportScreen extends StatefulWidget {
  const ProductImportScreen({super.key});

  @override
  State<ProductImportScreen> createState() => _ProductImportScreenState();
}

class _ProductImportScreenState extends State<ProductImportScreen> {
  bool _replaceExisting = false;
  bool _working = false;
  ImportResult? _result;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Import Products',
      subtitle: 'Bring product records into the device and review import issues before sales teams start using them.',
      headerImageAsset: AppAssets.productsHero,
      pageBackgroundAsset: AppAssets.pageTexture,
      child: ListView(
        children: [
          const SectionCard(
            title: 'Expected columns',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CSV header example:'),
                SizedBox(height: 8),
                SelectableText('name,sku,unit_price,description,barcode'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Import options',
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: _replaceExisting,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Replace existing product records'),
                  subtitle: const Text('Deletes current product master data before import.'),
                  onChanged: (value) => setState(() => _replaceExisting = value),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _working ? null : _pickAndImport,
                  icon: _working
                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() => _working = true);
    final importResult = await controller.importProductsFromFile(path, replaceExisting: _replaceExisting);
    if (!mounted) return;
    setState(() {
      _working = false;
      _result = importResult;
    });
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
          Text(result.summary, style: const TextStyle(fontWeight: FontWeight.w800)),
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Issues', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...result.errors.take(10).map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('- $entry'),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
