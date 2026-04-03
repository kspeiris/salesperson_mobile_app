import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/theme/app_assets.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/entities.dart';
import 'shop_form_screen.dart';
import 'shop_import_screen.dart';

class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});

  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final scheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.of(context).size.width < 640;

    return AppShell(
      title: 'Customer Management',
      subtitle:
          'Manage Bio Care customer shops and outstanding credit balances.',
      headerImageAsset: AppAssets.shopsHero,
      pageBackgroundAsset: AppAssets.pageTexture,
      actions: [
        IconButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ShopImportScreen())),
          icon: const Icon(Icons.download_for_offline_outlined),
          tooltip: 'Import Shops',
        ),
        IconButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ShopFormScreen())),
          icon: const Icon(Icons.add_business_outlined),
          tooltip: 'Add Shop',
        ),
      ],
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 16 : 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8F5E9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search customer records quickly, then import shops or add a new account from the same workspace.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by shop name, area, or owner',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ShopImportScreen()),
                      ),
                      icon: const Icon(Icons.download_for_offline_outlined),
                      label: const Text('Import'),
                    ),
                    FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ShopFormScreen()),
                      ),
                      icon: const Icon(Icons.add_business_outlined),
                      label: const Text('Add Shop'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<Shop>>(
              future: controller.fetchShops(query: _query),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final shops = snapshot.data!;
                if (shops.isEmpty) {
                  return const EmptyState(
                    icon: Icons.storefront_outlined,
                    title: 'No shops found',
                    message:
                        'Add your first shop or import a CSV file to start recording sales and collections.',
                    imageAsset: AppAssets.emptyStateHero,
                  );
                }
                return ListView.separated(
                  itemCount: shops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final shop = shops[index];
                    return Container(
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
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color:
                                        scheme.primary.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(Icons.storefront_outlined,
                                      color: scheme.primary),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        shop.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _MiniBadge(
                                              icon: Icons.place_outlined,
                                              label: shop.area),
                                          _MiniBadge(
                                              icon:
                                                  Icons.person_outline_rounded,
                                              label: shop.ownerContact),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) =>
                                      _handleAction(value, shop),
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                        value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(
                                        value: 'deactivate',
                                        child: Text('Deactivate')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE8F5E9)),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.account_balance_wallet_outlined,
                                        size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Text('Outstanding credit',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                                color: Colors.grey.shade700)),
                                  ],
                                ),
                                Text(
                                  AppFormatters.currency(shop.balance),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: shop.balance > 0
                                              ? Colors.red.shade700
                                              : scheme.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(String value, Shop shop) async {
    if (value == 'edit') {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => ShopFormScreen(shop: shop)));
      if (mounted) setState(() {});
      return;
    }

    if (value == 'deactivate') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Deactivate shop?'),
          content: Text('This will hide ${shop.name} from active entry lists.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Deactivate')),
          ],
        ),
      );
      if (confirm == true && mounted) {
        await context.read<AppController>().deactivateShop(shop.id!);
        setState(() {});
      }
    }
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FDF8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8F5E9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF263238)),
          const SizedBox(width: 6),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: const Color(0xFF263238))),
        ],
      ),
    );
  }
}
