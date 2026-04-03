import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../../app/app_controller.dart';
import '../../core/theme/app_assets.dart';

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
    // Removed explicit push. app.dart handles switching based on controller.authenticated state.
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final width = MediaQuery.of(context).size.width;
    final stacked = width < 860;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              const Color(0xFFEFF6FF), // extremely light blue
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
          image: const DecorationImage(
            image: AssetImage(AppAssets.pageTexture),
            fit: BoxFit.cover,
            opacity: 0.05,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(stacked ? 16 : 32, 16, stacked ? 16 : 32, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _IntroPanel(companyName: controller.settings.companyName, compact: true),
                          const SizedBox(height: 24),
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
                          Expanded(
                            flex: 5,
                            child: _IntroPanel(companyName: controller.settings.companyName),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            flex: 4,
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        image: const DecorationImage(
          image: AssetImage(AppAssets.loginHero),
          fit: BoxFit.cover,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF1B5E20),
          ],
        ),
        boxShadow: const [
           BoxShadow(
            blurRadius: 32,
            offset: Offset(0, 16),
            color: Color(0x1F2E7D32),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF16311A).withValues(alpha: 0.78),
                  const Color(0xFF2E7D32).withValues(alpha: 0.52),
                ],
              ),
            ),
            padding: EdgeInsets.all(compact ? 24 : 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.eco_rounded, color: Color(0xFFA5D6A7), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        companyName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Bio Care Sales App',
                  style: textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1.1),
                ),
                const SizedBox(height: 16),
                Text(
                  '"Pure Health. Trusted Quality."\nCapture orders, manage collections, and execute route strategies seamlessly with a delightfully engineered workflow.',
                  style: textTheme.titleMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85), height: 1.5, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 32),
                const Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Badge(icon: Icons.wifi_off_rounded, label: 'Offline-First Storage'),
                    _Badge(icon: Icons.insights_rounded, label: 'Smart Insights'),
                    _Badge(icon: Icons.security_rounded, label: 'Enterprise Grade'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});
  
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 40,
            offset: Offset(0, 20),
            color: Color(0x0A0F172A),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 24 : 40),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to access your dashboard and today\'s routes.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: salespersonController,
                style: const TextStyle(fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  labelText: 'Salesperson ID / Name',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                textInputAction: pinEnabled ? TextInputAction.next : TextInputAction.done,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter your ID.' : null,
                onFieldSubmitted: (_) {
                  if (!pinEnabled) onSubmit();
                },
              ),
              if (pinEnabled) ...[
                const SizedBox(height: 20),
                TextFormField(
                  controller: pinController,
                  obscureText: true,
                  style: const TextStyle(fontWeight: FontWeight.w500, letterSpacing: 4),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Access PIN',
                    prefixIcon: Icon(Icons.password_rounded),
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
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Access Workspace', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: Color(0xFF94A3B8)),
                    SizedBox(width: 8),
                    Text(
                      'End-to-end encrypted local storage',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
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

