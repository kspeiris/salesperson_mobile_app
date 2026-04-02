import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
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
    return AppShell(
      title: 'Shops',
      subtitle: 'Search, add, edit, and deactivate customer shops used for sales and collection entry.',
      actions: [
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopImportScreen())),
          icon: const Icon(Icons.download_for_offline_outlined),
          tooltip: 'Import Shops',
        ),
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopFormScreen())),
          icon: const Icon(Icons.add_business_outlined),
        ),
      ],
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search by shop name, area, or owner',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
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
                    message: 'Add your first shop or import a CSV file to start recording sales and collections.',
                  );
                }
                return ListView.separated(
                  itemCount: shops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final shop = shops[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.storefront_outlined),
                        ),
                        title: Text(shop.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          '${shop.area}\nOwner: ${shop.ownerContact}\nOutstanding: ${AppFormatters.currency(shop.balance)}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) => _handleAction(value, shop),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
                          ],
                        ),
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
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ShopFormScreen(shop: shop)));
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
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Deactivate')),
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
