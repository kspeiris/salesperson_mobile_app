import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    _lastFile = controller.lastGeneratedReport ?? _lastFile;

    return AppShell(
      title: 'Daily Reports',
      subtitle:
          'Generate daily PDF summaries and CSV/JSON export bundles for desktop system entry.',
      headerImageAsset: AppAssets.reportsHero,
      pageBackgroundAsset: AppAssets.pageTexture,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        children: [
          SectionCard(
            title: 'Report Date',
            subtitle:
                'Pick the business date before generating a PDF or export bundle.',
            child: _ReportsDateCard(
              selectedDate: _selectedDate,
              onTap: _pickDate,
            ),
          ),
          SizedBox(height: 20.h),
          FutureBuilder(
            future: controller.reportPreview(_selectedDate),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.h),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              final preview = snapshot.data!;
              return Column(
                children: [
                  SectionCard(
                    title: 'Preview',
                    subtitle:
                        'Check the recorded totals for the selected day before exporting.',
                    child: _ReportsSummaryCard(
                      salesTotal: preview.dashboard.totalSales,
                      collectionsTotal: preview.dashboard.totalCollections,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _generateReport,
                          icon: _isGenerating
                              ? SizedBox.square(
                                  dimension: 18.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('Generate PDF'),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isExporting ? null : _exportBundle,
                          icon: _isExporting
                              ? SizedBox.square(
                                  dimension: 18.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.primary,
                                  ),
                                )
                              : const Icon(Icons.upload_file_outlined),
                          label: const Text('Export Bundle'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 20.h),
          if (_lastFile != null)
            SectionCard(
              title: 'Latest PDF',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PathCard(path: _lastFile!.path, label: 'Saved file'),
                  SizedBox(height: 16.h),
                  FilledButton.icon(
                    onPressed: _shareLastReport,
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share PDF'),
                  ),
                ],
              ),
            ),
          if (controller.lastExportBundle != null) ...[
            SizedBox(height: 20.h),
            SectionCard(
              title: 'Latest export bundle',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PathCard(
                    path: controller.lastExportBundle!.csvFile,
                    label: 'CSV file',
                  ),
                  SizedBox(height: 10.h),
                  _PathCard(
                    path: controller.lastExportBundle!.jsonFile,
                    label: 'JSON file',
                  ),
                  SizedBox(height: 16.h),
                  FilledButton.icon(
                    onPressed: _shareExportBundle,
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share all files'),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _saveExportCopy(
                            controller.lastExportBundle!.csvFile,
                          ),
                          child: const Text('Save CSV'),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _saveExportCopy(
                            controller.lastExportBundle!.jsonFile,
                          ),
                          child: const Text('Save JSON'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
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
    try {
      final file =
          await context.read<AppController>().generateReport(_selectedDate);
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _lastFile = file;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF saved: ${file.path.split('/').last}')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _exportBundle() async {
    setState(() => _isExporting = true);
    try {
      final bundle = await context
          .read<AppController>()
          .exportDesktopImportBundle(_selectedDate);
      if (!mounted) return;
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exported ${bundle.csvFile.split('/').last} and JSON',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _saveExportCopy(String path) async {
    try {
      final savedPath = await context.read<AppController>().saveExportCopy(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(savedPath == null ? 'Save cancelled.' : 'Saved successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _shareLastReport() async {
    try {
      await context.read<AppController>().shareLastReport();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _shareExportBundle() async {
    try {
      await context.read<AppController>().shareExportBundle();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
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
    final scheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(22.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? scheme.surfaceContainerHighest
              : const Color(0xFFF5FBF6),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: scheme.primary,
                size: 22.w,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily records for',
                    style: theme.textTheme.labelMedium?.copyWith(fontSize: 11.sp),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    AppFormatters.date(selectedDate),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.hintColor,
              size: 24.w,
            ),
          ],
        ),
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
    final scheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          _SummaryMetric(
            label: 'Total Sales',
            value: AppFormatters.currency(salesTotal),
            accent: const Color(0xFF93B620),
            icon: Icons.trending_up_rounded,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: Divider(height: 1, color: scheme.outlineVariant),
          ),
          _SummaryMetric(
            label: 'Total Collections',
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
          width: 42.w,
          height: 42.w,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(icon, color: accent, size: 20.w),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 2.h),
              FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22.sp,
                    color: theme.colorScheme.onSurface,
                  ),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? scheme.surfaceContainerHighest
            : const Color(0xFFF4F8F5),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10.sp)),
          SizedBox(height: 6.h),
          Text(
            path,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.sp),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
