import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
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
      child: ListView(
        children: [
          const SectionCard(
            title: 'Expected Columns',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CSV header example:'),
                SizedBox(height: 8),
                SelectableText('name,owner_contact,area,phone,credit_limit,balance'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            value: _replaceExisting,
            contentPadding: EdgeInsets.zero,
            title: const Text('Replace existing shop records'),
            subtitle: const Text('Deletes current shop master data before import.'),
            onChanged: (value) => setState(() => _replaceExisting = value),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _working ? null : _pickAndImport,
            icon: const Icon(Icons.file_open_outlined),
            label: const Text('Pick CSV/TXT File'),
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() => _working = true);
    final importResult = await context.read<AppController>().importShopsFromFile(path, replaceExisting: _replaceExisting);
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.summary, style: const TextStyle(fontWeight: FontWeight.w800)),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Issues', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...result.errors.take(10).map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $entry'),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
