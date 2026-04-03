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
    final theme = Theme.of(context);
    _lastFile = controller.lastGeneratedReport ?? _lastFile;

    return AppShell(
      title: 'Daily Reports',
      subtitle:
          'Generate daily PDF summaries and CSV/JSON export bundles for desktop system entry.',
      headerImageAsset: AppAssets.reportsHero,
      pageBackgroundAsset: AppAssets.pageTexture,
      header: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _HeaderChip(
            icon: Icons.calendar_today_outlined,
            label: AppFormatters.date(_selectedDate),
          ),
          _HeaderChip(
            icon: Icons.badge_outlined,
            label: controller.currentSalesperson,
          ),
          const _HeaderChip(
            icon: Icons.cloud_off_outlined,
            label: 'Generated locally',
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          _ReportsDateCard(
            selectedDate: _selectedDate,
            onTap: _pickDate,
          ),
          const SizedBox(height: 20),
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
              return Column(
                children: [
                  _ReportsSummaryCard(
                    salesTotal: preview.dashboard.totalSales,
                    collectionsTotal: preview.dashboard.totalCollections,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                            backgroundColor: scheme.primary,
                            shadowColor: const Color(0x1A2E7D32),
                          ),
                          onPressed: _isGenerating ? null : _generateReport,
                          icon: _isGenerating
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('Generate PDF'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: _isExporting ? null : _exportBundle,
                          icon: _isExporting
                              ? SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primary,
                                  ),
                                )
                              : const Icon(Icons.upload_file_outlined),
                          label: const Text('Export CSV'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          if (_lastFile != null)
            SectionCard(
              title: 'Latest PDF',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PathCard(path: _lastFile!.path, label: 'Saved file'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () =>
                        context.read<AppController>().shareLastReport(),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share PDF'),
                  ),
                ],
              ),
            ),
          if (controller.lastExportBundle != null) ...[
            const SizedBox(height: 18),
            SectionCard(
              title: 'Latest export bundle',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PathCard(
                    path: controller.lastExportBundle!.csvFile,
                    label: 'CSV file',
                  ),
                  const SizedBox(height: 10),
                  _PathCard(
                    path: controller.lastExportBundle!.jsonFile,
                    label: 'JSON file',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () =>
                            context.read<AppController>().shareExportBundle(),
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Share files'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _saveExportCopy(
                          controller.lastExportBundle!.csvFile,
                        ),
                        icon: const Icon(Icons.save_alt_outlined),
                        label: const Text('Save CSV copy'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _saveExportCopy(
                          controller.lastExportBundle!.jsonFile,
                        ),
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
    final file =
        await context.read<AppController>().generateReport(_selectedDate);
    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _lastFile = file;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('PDF saved to ${file.path}')));
  }

  Future<void> _exportBundle() async {
    setState(() => _isExporting = true);
    final bundle = await context
        .read<AppController>()
        .exportDesktopImportBundle(_selectedDate);
    if (!mounted) return;
    setState(() => _isExporting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Exported ${bundle.csvFile.split('/').last} and ${bundle.jsonFile.split('/').last}',
        ),
      ),
    );
  }

  Future<void> _saveExportCopy(String path) async {
    final savedPath = await context.read<AppController>().saveExportCopy(path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(savedPath == null ? 'Save cancelled.' : 'Saved to $savedPath'),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5EC).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsDateCard extends StatelessWidget {
  const _ReportsDateCard({
    required this.selectedDate,
    required this.onTap,
  });

  final DateTime selectedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFDCEADB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 22,
            offset: Offset(0, 12),
            color: Color(0x102E7D32),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Select Report Date',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5FBF6),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFDDEEDD)),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 16,
                    offset: Offset(0, 8),
                    color: Color(0x082E7D32),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppFormatters.date(selectedDate),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4E6870),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF7C8C7E),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsSummaryCard extends StatelessWidget {
  const _ReportsSummaryCard({
    required this.salesTotal,
    required this.collectionsTotal,
  });

  final double salesTotal;
  final double collectionsTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF5FBF6)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFDCEADB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 14),
            color: Color(0x10204E2A),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.insert_chart_outlined_rounded,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Daily Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SummaryMetric(
            label: 'Sales',
            value: AppFormatters.currency(salesTotal),
            accent: const Color(0xFF2E7D32),
            icon: Icons.trending_up_rounded,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFE1EEE3)),
          ),
          _SummaryMetric(
            label: 'Collections',
            value: AppFormatters.currency(collectionsTotal),
            accent: const Color(0xFF5A8B68),
            icon: Icons.account_balance_wallet_rounded,
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6A8070),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  letterSpacing: -0.6,
                  color: const Color(0xFF203126),
                ),
              ),
            ],
          ),
        ),
      ],
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
