import 'package:flutter/material.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final controller = context.watch<AppController>();
    final currentImagePath = _profileImagePath ?? controller.profileImagePath;

    return Form(
      key: _formKey,
      child: AppShell(
        title: 'Profile & Settings',
        subtitle:
            'Update company details, payment methods, profile photo, and local device security from one place.',
        headerImageAsset: AppAssets.settingsHero,
        pageBackgroundAsset: AppAssets.pageTexture,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Center(
              child: Column(
                children: [
                  SalespersonAvatar(
                    name: _salespersonController.text.trim().isEmpty
                        ? controller.currentSalesperson
                        : _salespersonController.text.trim(),
                    imagePath: currentImagePath,
                    size: 104,
                    borderColor: const Color(0xFFE8F5E9),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickProfileImage,
                        icon: const Icon(Icons.photo_camera_back_outlined),
                        label: const Text('Upload Photo'),
                      ),
                      if ((currentImagePath ?? '').isNotEmpty)
                        TextButton.icon(
                          onPressed: _removeProfileImage,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Remove'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bio Care Sales App',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('v2.0 Premium Edition',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SectionCard(
              title: 'Data Management',
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8F5E9)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x052E7D32),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FDF8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.settings_backup_restore_rounded,
                        color: scheme.primary),
                  ),
                  title: const Text('Import / Export Data',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Manage masters and system backups.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DataManagementScreen())),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'App Profile',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8F5E9)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x052E7D32),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
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
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _paymentMethodsController,
                      decoration: const InputDecoration(
                        labelText: 'Payment Methods',
                        hintText: 'Cash, Bank, Cheque',
                        prefixIcon: Icon(Icons.payments_rounded),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'At least one payment method is required.'
                              : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Security',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8F5E9)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x052E7D32),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      value: _pinEnabled,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable local PIN',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle:
                          const Text('Protect app access on this device.'),
                      onChanged: (value) => setState(() => _pinEnabled = value),
                    ),
                    if (_pinEnabled) ...[
                      const Divider(height: 24, color: Color(0xFFE8F5E9)),
                      TextFormField(
                        controller: _pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'New PIN',
                          hintText: 'Leave blank to keep current PIN',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        validator: (value) {
                          if (!_pinEnabled) return null;
                          if (value == null || value.isEmpty) return null;
                          if (value.trim().length < 4) {
                            return 'PIN must be at least 4 digits.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('SAVE PROFILE'),
            ),
            const SizedBox(height: 48),
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
