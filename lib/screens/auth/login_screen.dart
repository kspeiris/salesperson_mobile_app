import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.dark
                ? [
                    const Color(0xFF0D1510),
                    const Color(0xFF122018),
                    const Color(0xFF18241D),
                  ]
                : [
                    const Color(0xFFF8FDF8),
                    const Color(0xFFF3FAF3),
                    const Color(0xFFEFF7FF),
                  ],
          ),
          image: const DecorationImage(
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
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _IntroPanel(
                        companyName: controller.settings.companyName),
                    SizedBox(height: 24.h),
                    _LoginCard(
                      formKey: _formKey,
                      salespersonController: _salespersonController,
                      pinController: _pinController,
                      pinEnabled: controller.settings.pinEnabled,
                      profileImagePath: controller.profileImagePath,
                      onSubmit: _submit,
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
  });

  final String companyName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      constraints: BoxConstraints(minHeight: 280.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.r),
        image: const DecorationImage(
          image: AssetImage(AppAssets.loginHero),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 36,
            offset: const Offset(0, 20),
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.24 : 0.11,
            ),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.r),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              stops: const [0.0, 0.55, 1.0],
              colors: [
                const Color(0xFF143B1E).withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.82 : 0.90,
                ),
                const Color(0xFF93B620).withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.56 : 0.64,
                ),
                const Color(0xFFB7CF3A).withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.16 : 0.20,
                ),
              ],
            ),
          ),
          padding: EdgeInsets.all(22.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16.r),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.22)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.spa_rounded,
                        color: const Color(0xFFD8F3DC), size: 16.w),
                    SizedBox(width: 8.w),
                    Text(
                      companyName,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                'Bio Care Sales App',
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 24.sp,
                  height: 1.1,
                  letterSpacing: -0.6,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Capture orders and route actions in one workspace.',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.84),
                  fontSize: 14.sp,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16.h),
              Wrap(
                spacing: 12.w,
                runSpacing: 8.h,
                children: const [
                  _Badge(
                      icon: Icons.wifi_off_rounded, label: 'Offline-First'),
                  _Badge(icon: Icons.insights_rounded, label: 'Insights'),
                ],
              ),
            ],
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
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.w, color: Colors.white.withValues(alpha: 0.92)),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.96),
              fontWeight: FontWeight.w700,
              fontSize: 11.sp,
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
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController salespersonController;
  final TextEditingController pinController;
  final bool pinEnabled;
  final String? profileImagePath;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            blurRadius: 34,
            offset: const Offset(0, 18),
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.24 : 0.07,
            ),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
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
                    height: 36,
                    showPlate: false,
                    alignment: Alignment.centerLeft,
                  ),
                  const Spacer(),
                  SalespersonAvatar(
                    name: salespersonController.text.trim().isEmpty
                        ? 'Bio Care'
                        : salespersonController.text.trim(),
                    imagePath: profileImagePath,
                    size: 42.w,
                    backgroundColor: scheme.primary.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.18 : 0.10,
                    ),
                    foregroundColor: scheme.primary,
                    borderColor: scheme.outlineVariant,
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              Text(
                'Welcome back',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800, fontSize: 20.sp),
              ),
              SizedBox(height: 28.h),
              TextFormField(
                controller: salespersonController,
                decoration: InputDecoration(
                  labelText: 'Salesperson ID / Name',
                  prefixIcon: Container(
                    margin: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
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
                SizedBox(height: 20.h),
                TextFormField(
                  controller: pinController,
                  obscureText: true,
                  style: TextStyle(
                      fontWeight: FontWeight.w500, letterSpacing: 4, fontSize: 16.sp),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Access PIN',
                    prefixIcon: Container(
                      margin: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
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
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSubmit,
                  child: const Text('Access Workspace'),
                ),
              ),
              SizedBox(height: 24.h),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 14.w,
                      color: theme.hintColor,
                    ),
                    Text(
                      'End-to-end encrypted local storage',
                      style: TextStyle(
                        color: theme.hintColor,
                        fontSize: 11.sp,
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
