import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/theme/app_assets.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/section_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late DateTime _selectedDate;
  bool _isGenerating = false;
  bool _isExporting = false;
  File? _lastFile;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final scheme = Theme.of(context).colorScheme;
    _lastFile = controller.lastGeneratedReport ?? _lastFile;

    return AppShell(
      title: 'Daily Reports',
      subtitle: 'Generate daily PDF summaries and CSV/JSON export bundles for desktop system entry.',
      headerImageAsset: AppAssets.reportsHero,
      pageBackgroundAsset: AppAssets.pageTexture,
      header: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _HeaderChip(icon: Icons.calendar_today_outlined, label: AppFormatters.date(_selectedDate)),
          _HeaderChip(icon: Icons.badge_outlined, label: controller.currentSalesperson),
          const _HeaderChip(icon: Icons.cloud_off_outlined, label: 'Generated locally'),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),
          SectionCard(
            title: '📅 Select Report Date',
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FDF8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8F5E9)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: scheme.primary),
                    const SizedBox(width: 12),
                    Text(AppFormatters.date(_selectedDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder(
            future: controller.reportPreview(_selectedDate),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final preview = snapshot.data!;
              return SectionCard(
                title: '📄 Daily Summary',
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8F5E9)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Sales', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                              Text(AppFormatters.currency(preview.dashboard.totalSales), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, color: Color(0xFFE8F5E9)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Collections', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                              Text(AppFormatters.currency(preview.dashboard.totalCollections), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isGenerating ? null : _generateReport,
                            icon: _isGenerating
                                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('Generate PDF'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isExporting ? null : _exportBundle,
                            icon: _isExporting
                                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.upload_file_outlined),
                            label: const Text('Export CSV'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          if (_lastFile != null)
            SectionCard(
               title: 'Latest PDF',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PathCard(path: _lastFile!.path, label: 'Saved file'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => context.read<AppController>().shareLastReport(),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share PDF'),
                  ),
                ],
              ),
            ),
          if (controller.lastExportBundle != null) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Latest export bundle',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PathCard(path: controller.lastExportBundle!.csvFile, label: 'CSV file'),
                  const SizedBox(height: 10),
                  _PathCard(path: controller.lastExportBundle!.jsonFile, label: 'JSON file'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.read<AppController>().shareExportBundle(),
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Share files'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _saveExportCopy(controller.lastExportBundle!.csvFile),
                        icon: const Icon(Icons.save_alt_outlined),
                        label: const Text('Save CSV copy'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _saveExportCopy(controller.lastExportBundle!.jsonFile),
                        icon: const Icon(Icons.code_outlined),
                        label: const Text('Save JSON copy'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);
    final file = await context.read<AppController>().generateReport(_selectedDate);
    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _lastFile = file;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF saved to ${file.path}')));
  }

  Future<void> _exportBundle() async {
    setState(() => _isExporting = true);
    final bundle = await context.read<AppController>().exportDesktopImportBundle(_selectedDate);
    if (!mounted) return;
    setState(() => _isExporting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported ${bundle.csvFile.split('/').last} and ${bundle.jsonFile.split('/').last}')),
    );
  }

  Future<void> _saveExportCopy(String path) async {
    final savedPath = await context.read<AppController>().saveExportCopy(path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(savedPath == null ? 'Save cancelled.' : 'Saved to $savedPath')),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.path,
    required this.label,
  });

  final String path;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE8E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(path, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
