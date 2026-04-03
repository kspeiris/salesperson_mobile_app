import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/widgets/app_shell.dart';
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
      subtitle: 'Configure your company profile, manage master data, and perform system backups from one central hub.',
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _ProfileHeader(
            salesperson: controller.currentSalesperson,
            companyName: controller.settings.companyName,
          ),
          const SizedBox(height: 24),
          
          SectionCard(
            title: 'Master Data',
            child: Column(
              children: [
                _MoreTile(
                  icon: Icons.storefront_outlined,
                  title: 'Retailer Shops',
                  subtitle: 'Manage shops, view current balances and route areas.',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopsScreen())),
                ),
                const SizedBox(height: 12),
                _MoreTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'Product Catalog',
                  subtitle: 'Manage items, pricing, and barcode identifiers.',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SectionCard(
            title: 'Import Operations',
            child: Column(
              children: [
                _MoreTile(
                  icon: Icons.file_upload_outlined,
                  title: 'Import Shops (CSV)',
                  subtitle: 'Update shop masters via bulk CSV upload.',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopImportScreen())),
                ),
                const SizedBox(height: 12),
                _MoreTile(
                  icon: Icons.upload_file_outlined,
                  title: 'Import Products (CSV)',
                  subtitle: 'Update item masters and price lists via CSV.',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductImportScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SectionCard(
            title: 'System & Security',
            child: Column(
              children: [
                _MoreTile(
                  icon: Icons.settings_backup_restore_rounded,
                  title: 'Data Management',
                  subtitle: 'Create backups and restore previous database states.',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataManagementScreen())),
                ),
                const SizedBox(height: 12),
                _MoreTile(
                  icon: Icons.tune_rounded,
                  title: 'App Settings',
                  subtitle: 'Company profile, payment methods, and PIN security.',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SectionCard(
            title: 'About Bio Care',
            child: Column(
              children: [
                _MoreTile(
                  icon: Icons.info_outline_rounded,
                  title: 'App Version',
                  subtitle: 'v2.0.4 Premium - Bio Care Field Systems',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Bio Care Sales',
                      applicationVersion: '2.0.4',
                      applicationIcon: const Icon(Icons.eco_rounded, color: Color(0xFF2E7D32), size: 48),
                      children: [
                        const Text('Pure Health. Trusted Quality.'),
                        const SizedBox(height: 10),
                        const Text('A specialized field sales automation tool engineered for the Bio Care distribution network.'),
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
  });

  final String salesperson;
  final String companyName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8F5E9)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_rounded, size: 32, color: scheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  salesperson,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  companyName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
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
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FDF8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8F5E9)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8F5E9)),
              ),
              child: Icon(icon, color: scheme.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
