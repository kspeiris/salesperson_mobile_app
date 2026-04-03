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
    final width = MediaQuery.of(context).size.width;
    final stacked = width < 760;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: 0.18),
              scheme.secondary.withValues(alpha: 0.16),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(stacked ? 16 : 20, 12, stacked ? 16 : 20, 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _IntroPanel(companyName: controller.settings.companyName, compact: true),
                          const SizedBox(height: 18),
                          _LoginCard(
                            formKey: _formKey,
                            salespersonController: _salespersonController,
                            pinController: _pinController,
                            pinEnabled: controller.settings.pinEnabled,
                            onSubmit: _submit,
                            compact: true,
                          ),
                        ],
                      )
                    : Row(
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
  const _IntroPanel({
    required this.companyName,
    this.compact = false,
  });

  final String companyName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            scheme.tertiary,
            const Color(0xFF0C3E38),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 28,
            offset: Offset(0, 14),
            color: Color(0x1A10241D),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 22 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: compact ? 58 : 68,
              height: compact ? 58 : 68,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: const Icon(Icons.waves_rounded, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              'Bio Care Field Hub',
              style: textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              '$companyName helps route teams capture orders, collections, and shop activity with a clean offline workflow built for daily field execution.',
              style: textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.88)),
            ),
            const SizedBox(height: 22),
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _TopBadge(icon: Icons.offline_bolt_rounded, label: 'Works offline'),
                _TopBadge(icon: Icons.route_outlined, label: 'Built for routes'),
                _TopBadge(icon: Icons.bar_chart_rounded, label: 'Reports ready'),
              ],
            ),
            const SizedBox(height: 24),
            const _FeatureRow(
              icon: Icons.shopping_bag_outlined,
              title: 'Faster field capture',
              description: 'Move from shop visit to saved order in a few taps with a layout tuned for mobile use.',
            ),
            const SizedBox(height: 16),
            const _FeatureRow(
              icon: Icons.payments_outlined,
              title: 'Collections stay visible',
              description: 'Keep balances, receipts, and follow-up activity easier to track during a busy route day.',
            ),
            const SizedBox(height: 16),
            const _FeatureRow(
              icon: Icons.insert_chart_outlined_rounded,
              title: 'A better daily overview',
              description: 'See sales, credit, collections, and next actions quickly without digging through screens.',
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
    this.compact = false,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController salespersonController;
  final TextEditingController pinController;
  final bool pinEnabled;
  final VoidCallback onSubmit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE1E8E1)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 12),
            color: Color(0x1210241D),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 22 : 28),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sign in to your route', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'Start with your salesperson name, unlock the workspace, and continue logging field activity even without internet access.',
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: salespersonController,
                decoration: const InputDecoration(
                  labelText: 'Salesperson',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                textInputAction: pinEnabled ? TextInputAction.next : TextInputAction.done,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter the salesperson name.' : null,
                onFieldSubmitted: (_) {
                  if (!pinEnabled) onSubmit();
                },
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
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => onSubmit(),
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
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: const Text('Open workspace'),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8F5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDDE8E0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.cloud_done_outlined, color: scheme.primary),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Offline-first mode is active. Records stay safely on the device until you generate or share reports.',
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

class _TopBadge extends StatelessWidget {
  const _TopBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
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
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.80)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
