import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../screens/dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  late final TextEditingController _salespersonController;

  @override
  void initState() {
    super.initState();
    _salespersonController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<AppController>();
    if (_salespersonController.text.isEmpty) {
      _salespersonController.text = controller.settings.defaultSalesperson;
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _salespersonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = context.read<AppController>();
    final error = controller.login(
      salesperson: _salespersonController.text,
      pin: _pinController.text,
    );
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: 0.18),
              const Color(0xFFEFE7D8),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 760;
                    if (stacked) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _IntroPanel(companyName: controller.settings.companyName),
                          const SizedBox(height: 20),
                          _LoginCard(
                            formKey: _formKey,
                            salespersonController: _salespersonController,
                            pinController: _pinController,
                            pinEnabled: controller.settings.pinEnabled,
                            onSubmit: _submit,
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _IntroPanel(companyName: controller.settings.companyName)),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _LoginCard(
                            formKey: _formKey,
                            salespersonController: _salespersonController,
                            pinController: _pinController,
                            pinEnabled: controller.settings.pinEnabled,
                            onSubmit: _submit,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroPanel extends StatelessWidget {
  const _IntroPanel({required this.companyName});

  final String companyName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(Icons.point_of_sale_rounded, size: 32, color: scheme.primary),
            ),
            const SizedBox(height: 20),
            Text('Salesperson Daily Recorder', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            Text(
              '$companyName field teams can capture sales, collections, and PDF-ready summaries with a workflow built for speed.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            const _FeatureRow(
              icon: Icons.inventory_2_outlined,
              title: 'Fast local entry',
              description: 'Record item-level sales and payment collections even with no signal.',
            ),
            const SizedBox(height: 16),
            const _FeatureRow(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Report-ready output',
              description: 'Generate daily PDFs and desktop-friendly exports from the same screen.',
            ),
            const SizedBox(height: 16),
            const _FeatureRow(
              icon: Icons.verified_user_outlined,
              title: 'Controlled access',
              description: 'Support salesperson identity and an optional local PIN for device protection.',
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.salespersonController,
    required this.pinController,
    required this.pinEnabled,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController salespersonController;
  final TextEditingController pinController;
  final bool pinEnabled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sign in', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'Open your daily workspace, record transactions quickly, and create report-ready files without internet.',
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: salespersonController,
                decoration: const InputDecoration(
                  labelText: 'Salesperson',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter the salesperson name.' : null,
              ),
              if (pinEnabled) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'PIN',
                    hintText: 'Enter your access PIN',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (value) {
                    if (!pinEnabled) return null;
                    if (value == null || value.trim().isEmpty) return 'PIN is required.';
                    if (value.trim().length < 4) return 'PIN must be at least 4 digits.';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onSubmit,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Continue to dashboard'),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE4DDD2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.offline_bolt_rounded),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Offline-first mode is active. Records stay on the device until you share reports or exports.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: scheme.secondary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(description),
            ],
          ),
        ),
      ],
    );
  }
}
