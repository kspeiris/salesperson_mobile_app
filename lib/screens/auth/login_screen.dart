import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_controller.dart';
import '../../core/theme/app_assets.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/salesperson_avatar.dart';

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
    try {
      final error = controller.login(
        salesperson: _salespersonController.text,
        pin: _pinController.text,
      );
      if (error != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
        return;
      }
      if (!mounted) return;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final width = MediaQuery.of(context).size.width;
    final stacked = width < 860;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FDF8),
              Color(0xFFF3FAF3),
              Color(0xFFEFF7FF),
            ],
          ),
          image: DecorationImage(
            image: AssetImage(AppAssets.pageTexture),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            opacity: 0.07,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                  stacked ? 16 : 32, 20, stacked ? 16 : 32, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _IntroPanel(
                              companyName: controller.settings.companyName,
                              compact: true),
                          const SizedBox(height: 24),
                          _LoginCard(
                            formKey: _formKey,
                            salespersonController: _salespersonController,
                            pinController: _pinController,
                            pinEnabled: controller.settings.pinEnabled,
                            profileImagePath: controller.profileImagePath,
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
                            child: _IntroPanel(
                                companyName: controller.settings.companyName),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            flex: 4,
                            child: _LoginCard(
                              formKey: _formKey,
                              salespersonController: _salespersonController,
                              pinController: _pinController,
                              pinEnabled: controller.settings.pinEnabled,
                              profileImagePath: controller.profileImagePath,
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
      constraints: BoxConstraints(minHeight: compact ? 336 : 500),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        image: const DecorationImage(
          image: AssetImage(AppAssets.loginHero),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 36,
            offset: Offset(0, 20),
            color: Color(0x1C1B5E20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              stops: const [0.0, 0.55, 1.0],
              colors: [
                const Color(0xFF143B1E).withValues(alpha: 0.90),
                const Color(0xFF2E7D32).withValues(alpha: 0.64),
                const Color(0xFF9CCC65).withValues(alpha: 0.20),
              ],
            ),
          ),
          padding: EdgeInsets.all(compact ? 22 : 38),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 285 : 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.22)),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 18,
                        offset: Offset(0, 8),
                        color: Color(0x14000000),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.spa_rounded,
                          color: Color(0xFFD8F3DC), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        companyName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Bio Care Sales App',
                  style: (compact
                          ? textTheme.headlineLarge
                          : textTheme.displaySmall)
                      ?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -0.9,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '"Pure Health. Trusted Quality."\nCapture orders, collections, and route actions in one beautifully focused workspace.',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    fontSize: compact ? 18 : null,
                  ),
                ),
                const SizedBox(height: 20),
                const Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Badge(
                        icon: Icons.wifi_off_rounded, label: 'Offline-First'),
                    _Badge(icon: Icons.insights_rounded, label: 'Insights'),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 6),
            color: Color(0x12000000),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.92)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.96),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
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
    required this.profileImagePath,
    required this.onSubmit,
    this.compact = false,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController salespersonController;
  final TextEditingController pinController;
  final bool pinEnabled;
  final String? profileImagePath;
  final VoidCallback onSubmit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.70)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 34,
            offset: Offset(0, 18),
            color: Color(0x120F172A),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 22 : 34),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const BrandLogo(
                    height: 44,
                    showPlate: false,
                    alignment: Alignment.centerLeft,
                  ),
                  const Spacer(),
                  SalespersonAvatar(
                    name: salespersonController.text.trim().isEmpty
                        ? 'Bio Care'
                        : salespersonController.text.trim(),
                    imagePath: profileImagePath,
                    size: 48,
                    backgroundColor: const Color(0xFFEAF6EC),
                    foregroundColor: const Color(0xFF1B5E20),
                    borderColor: const Color(0xFFD8E9DA),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Welcome back',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to access your dashboard and today\'s routes.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF64748B),
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: salespersonController,
                style: const TextStyle(fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  labelText: 'Salesperson ID / Name',
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF6EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.badge_outlined),
                  ),
                ),
                textInputAction:
                    pinEnabled ? TextInputAction.next : TextInputAction.done,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter your ID.'
                    : null,
                onFieldSubmitted: (_) {
                  if (!pinEnabled) onSubmit();
                },
              ),
              if (pinEnabled) ...[
                const SizedBox(height: 20),
                TextFormField(
                  controller: pinController,
                  obscureText: true,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, letterSpacing: 4),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Access PIN',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF6EC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.password_rounded),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => onSubmit(),
                  validator: (value) {
                    if (!pinEnabled) return null;
                    if (value == null || value.trim().isEmpty) {
                      return 'PIN is required.';
                    }
                    if (value.trim().length < 4) {
                      return 'PIN must be at least 4 digits.';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  clipBehavior: Clip.antiAlias,
                  onPressed: onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: const Color(0x332E7D32),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ).copyWith(
                    overlayColor:
                        const WidgetStatePropertyAll(Color(0x142E7D32)),
                    backgroundColor:
                        const WidgetStatePropertyAll(Colors.transparent),
                    shadowColor:
                        const WidgetStatePropertyAll(Colors.transparent),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFF2E7D32),
                          Color(0xFF43A047),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 18,
                          offset: Offset(0, 10),
                          color: Color(0x2B2E7D32),
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Center(
                        child: Text(
                          'Access Workspace',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: const Color(0xFF94A3B8).withValues(alpha: 0.90),
                    ),
                    Text(
                      'End-to-end encrypted local storage',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF94A3B8).withValues(alpha: 0.88),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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

