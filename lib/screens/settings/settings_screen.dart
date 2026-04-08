import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/theme/app_assets.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/salesperson_avatar.dart';
import '../data/data_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _companyController;
  late final TextEditingController _salespersonController;
  late final TextEditingController _paymentMethodsController;
  late final TextEditingController _pinController;
  bool _pinEnabled = false;
  String? _profileImagePath;
  String _themeMode = 'system';

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppController>().settings;
    _companyController = TextEditingController(text: settings.companyName);
    _salespersonController =
        TextEditingController(text: settings.defaultSalesperson);
    _paymentMethodsController =
        TextEditingController(text: settings.paymentMethods.join(', '));
    _pinController = TextEditingController();
    _pinEnabled = settings.pinEnabled;
    _profileImagePath = settings.profileImagePath;
    _themeMode = settings.themeMode;
    _companyController.addListener(_refreshPreview);
    _salespersonController.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _companyController.removeListener(_refreshPreview);
    _salespersonController.removeListener(_refreshPreview);
    _companyController.dispose();
    _salespersonController.dispose();
    _paymentMethodsController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final methods = _paymentMethodsController.text
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();

    try {
      await context.read<AppController>().saveSettings(
            companyName: _companyController.text,
            defaultSalesperson: _salespersonController.text,
            paymentMethods: methods,
            pinEnabled: _pinEnabled,
            themeMode: _themeMode,
            rawPin: _pinController.text,
            profileImagePath: _profileImagePath,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile saved locally.')));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final controller = context.watch<AppController>();
    final currentImagePath = _profileImagePath ?? controller.profileImagePath;

    return Form(
      key: _formKey,
      child: AppShell(
        title: 'Profile & Settings',
        subtitle:
            'Update company details, payment methods, profile photo, and local device security.',
        headerImageAsset: AppAssets.settingsHero,
        pageBackgroundAsset: AppAssets.pageTexture,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(bottom: 24.h),
          children: [
            Center(
              child: Column(
                children: [
                  SalespersonAvatar(
                    name: _salespersonController.text.trim().isEmpty
                        ? controller.currentSalesperson
                        : _salespersonController.text.trim(),
                    imagePath: currentImagePath,
                    size: 96.w,
                    borderColor: scheme.outlineVariant,
                  ),
                  SizedBox(height: 16.h),
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 12.h,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickProfileImage,
                        icon: Icon(Icons.photo_camera_back_outlined, size: 18.w),
                        label: const Text('Update Photo'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                        ),
                      ),
                      if ((currentImagePath ?? '').isNotEmpty)
                        TextButton.icon(
                          onPressed: _removeProfileImage,
                          icon: Icon(Icons.delete_outline_rounded, size: 18.w),
                          label: const Text('Remove'),
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            SectionCard(
              title: 'Master Data Management',
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                leading: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.settings_backup_restore_rounded,
                      color: scheme.primary, size: 22.w),
                ),
                title: Text('Database Tools',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                subtitle: Text('Manage system backups and master data.', style: TextStyle(fontSize: 12.sp)),
                trailing: Icon(Icons.chevron_right_rounded, size: 20.w),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DataManagementScreen())),
              ),
            ),
            SizedBox(height: 16.h),
            SectionCard(
              title: 'Company Profile',
              child: Column(
                children: [
                  TextFormField(
                    controller: _companyController,
                    decoration: const InputDecoration(
                      labelText: 'Company Name',
                      prefixIcon: Icon(Icons.business_rounded),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Company name is required.'
                            : null,
                  ),
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: _salespersonController,
                    decoration: const InputDecoration(
                      labelText: 'Salesperson Name',
                      prefixIcon: Icon(Icons.badge_rounded),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Name is required.'
                            : null,
                  ),
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: _paymentMethodsController,
                    decoration: const InputDecoration(
                      labelText: 'Payment Methods',
                      hintText: 'Cash, Bank, Cheque',
                      prefixIcon: Icon(Icons.payments_rounded),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Required.'
                            : null,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SectionCard(
              title: 'Appearance',
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'system',
                    groupValue: _themeMode,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('System default'),
                    onChanged: (value) => setState(() => _themeMode = value!),
                  ),
                  RadioListTile<String>(
                    value: 'light',
                    groupValue: _themeMode,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Light mode'),
                    onChanged: (value) => setState(() => _themeMode = value!),
                  ),
                  RadioListTile<String>(
                    value: 'dark',
                    groupValue: _themeMode,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dark mode'),
                    onChanged: (value) => setState(() => _themeMode = value!),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SectionCard(
              title: 'Security',
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    value: _pinEnabled,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable local PIN',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onChanged: (value) => setState(() => _pinEnabled = value),
                  ),
                  if (_pinEnabled) ...[
                    SizedBox(height: 12.h),
                    TextFormField(
                      controller: _pinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'New PIN',
                        hintText: 'Leave blank to keep same',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      validator: (value) {
                        if (!_pinEnabled) return null;
                        if (value == null || value.isEmpty) return null;
                        if (value.trim().length < 4) {
                          return 'PIN must be 4+ digits.';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: _save,
              child: const Text('SAVE PROFILE'),
            ),
            SizedBox(height: 48.h),
          ],
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    final path = await context.read<AppController>().pickAndSaveProfileImage();
    if (!mounted || path == null) return;
    setState(() => _profileImagePath = path);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile photo updated.')),
    );
  }

  Future<void> _removeProfileImage() async {
    await context.read<AppController>().clearProfileImage();
    if (!mounted) return;
    setState(() => _profileImagePath = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile photo removed.')),
    );
  }
}
