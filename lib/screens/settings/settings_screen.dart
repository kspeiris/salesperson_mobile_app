import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/section_card.dart';
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

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppController>().settings;
    _companyController = TextEditingController(text: settings.companyName);
    _salespersonController = TextEditingController(text: settings.defaultSalesperson);
    _paymentMethodsController = TextEditingController(text: settings.paymentMethods.join(', '));
    _pinController = TextEditingController();
    _pinEnabled = settings.pinEnabled;
  }

  @override
  void dispose() {
    _companyController.dispose();
    _salespersonController.dispose();
    _paymentMethodsController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final methods = _paymentMethodsController.text
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();

    await context.read<AppController>().saveSettings(
      companyName: _companyController.text,
      defaultSalesperson: _salespersonController.text,
      paymentMethods: methods,
      pinEnabled: _pinEnabled,
      rawPin: _pinController.text,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved locally.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Settings',
      subtitle: 'Configure company details, default salesperson settings, local PIN access, and data management shortcuts.',
      actions: [
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataManagementScreen())),
          icon: const Icon(Icons.storage_outlined),
          tooltip: 'Data Management',
        ),
      ],
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            SectionCard(
              title: 'Tools',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8F5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDDE8E0)),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.storage_outlined),
                  title: const Text('Data Management', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Backup or restore SQLite, import masters, and manage desktop import files.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataManagementScreen())),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'App profile',
              child: Column(
                children: [
                  TextFormField(
                    controller: _companyController,
                    decoration: const InputDecoration(
                      labelText: 'Company name',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Company name is required.' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _salespersonController,
                    decoration: const InputDecoration(
                      labelText: 'Default salesperson',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Default salesperson is required.' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _paymentMethodsController,
                    decoration: const InputDecoration(
                      labelText: 'Payment methods',
                      hintText: 'Cash, Bank, Cheque',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'At least one payment method is required.' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Security',
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8F5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDDE8E0)),
                    ),
                    child: SwitchListTile.adaptive(
                      value: _pinEnabled,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: const Text('Enable local PIN'),
                      subtitle: const Text('Protect app access on this device.'),
                      onChanged: (value) => setState(() => _pinEnabled = value),
                    ),
                  ),
                  if (_pinEnabled) ...[
                    const SizedBox(height: 14),
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
                        if (value.trim().length < 4) return 'PIN must be at least 4 digits.';
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('Save settings')),
          ],
        ),
      ),
    );
  }
}
