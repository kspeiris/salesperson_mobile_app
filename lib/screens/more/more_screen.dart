import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/theme/app_assets.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/salesperson_avatar.dart';
import '../../core/widgets/section_card.dart';
import '../data/data_management_screen.dart';
import '../products/product_import_screen.dart';
import '../products/products_screen.dart';
import '../settings/settings_screen.dart';
import '../shops/shop_import_screen.dart';
import '../shops/shops_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();

    return AppShell(
      title: 'Management',
      showBack: false,
      subtitle:
          'Configure your company profile, manage master data, and perform system backups from one central hub.',
      headerImageAsset: AppAssets.settingsHero,
      pageBackgroundAsset: AppAssets.pageTexture,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(bottom: 32.h),
        children: [
          _ProfileHeader(
            salesperson: controller.currentSalesperson,
            companyName: controller.settings.companyName,
            profileImagePath: controller.profileImagePath,
          ),
          SizedBox(height: 24.h),
          SectionCard(
            title: 'Master Data',
            child: Column(
              children: [
                _MoreTile(
                  icon: Icons.storefront_outlined,
                  title: 'Retailer Shops',
                  subtitle:
                      'Manage shops, view current balances and route areas.',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ShopsScreen())),
                ),
                SizedBox(height: 12.h),
                _MoreTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'Product Catalog',
                  subtitle: 'Manage items, pricing, and barcode identifiers.',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProductsScreen())),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          SectionCard(
            title: 'Import Operations',
            child: Column(
              children: [
                _MoreTile(
                  icon: Icons.file_upload_outlined,
                  title: 'Import Shops (CSV)',
                  subtitle: 'Update shop masters via bulk CSV upload.',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ShopImportScreen())),
                ),
                SizedBox(height: 12.h),
                _MoreTile(
                  icon: Icons.upload_file_outlined,
                  title: 'Import Products (CSV)',
                  subtitle: 'Update item masters and price lists via CSV.',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProductImportScreen())),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          SectionCard(
            title: 'System & Security',
            child: Column(
              children: [
                _MoreTile(
                  icon: Icons.settings_backup_restore_rounded,
                  title: 'Data Management',
                  subtitle:
                      'Create backups and restore previous database states.',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DataManagementScreen())),
                ),
                SizedBox(height: 12.h),
                _MoreTile(
                  icon: Icons.tune_rounded,
                  title: 'App Settings',
                  subtitle:
                      'Company profile, payment methods, and PIN security.',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen())),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          SectionCard(
            title: 'About Bio Care',
            child: Column(
              children: [
                _MoreTile(
                  icon: Icons.info_outline_rounded,
                  title: 'App Version',
                  subtitle: 'v1.1.0 - Bio Care Field Systems',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Bio Care Consumers Sales App',
                      applicationVersion: '1.1.0',
                      applicationIcon: Icon(Icons.eco_rounded,
                          color: const Color(0xFF93B620), size: 48.w),
                      children: [
                        const Text('Pure Health. Trusted Quality.'),
                        const SizedBox(height: 10),
                        const Text(
                            'A specialized field sales automation tool engineered for the Bio Care distribution network.'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.salesperson,
    required this.companyName,
    this.profileImagePath,
  });

  final String salesperson;
  final String companyName;
  final String? profileImagePath;

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
      child: Row(
        children: [
          SalespersonAvatar(
            name: salesperson,
            imagePath: profileImagePath,
            size: 64.w,
            borderColor: scheme.outlineVariant,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  salesperson,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800, fontSize: 18.sp),
                ),
                SizedBox(height: 2.h),
                Text(
                  companyName,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.hintColor, fontSize: 13.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : const Color(0xFFF8FDF8),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Icon(icon, color: scheme.primary, size: 20.w),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15.sp),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(color: theme.hintColor, fontSize: 12.sp),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.hintColor, size: 20.w),
          ],
        ),
      ),
    );
  }
}
