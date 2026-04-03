import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/entities.dart';
import 'product_form_screen.dart';
import 'product_import_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getProductEmoji(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('aloe')) return '🌿';
    if (lower.contains('orange') || lower.contains('fruit') || lower.contains('citrus')) return '🍊';
    if (lower.contains('energy') || lower.contains('boost')) return '💪';
    if (lower.contains('herbal')) return '🍃';
    return '🧪';
  }

  Color _getProductColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('aloe')) return const Color(0xFF2E7D32);
    if (lower.contains('orange') || lower.contains('fruit')) return Colors.orange.shade700;
    if (lower.contains('energy')) return Colors.amber.shade800;
    if (lower.contains('herbal')) return Colors.purple.shade600;
    return const Color(0xFF263238);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final scheme = Theme.of(context).colorScheme;

    return AppShell(
      title: 'Products',
      subtitle: 'Manage the Bio Care product catalog, pricing, and barcode items.',
      actions: [
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductImportScreen())),
          icon: const Icon(Icons.download_for_offline_outlined),
          tooltip: 'Import Products',
        ),
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductFormScreen())),
          icon: const Icon(Icons.add_box_outlined),
          tooltip: 'Add Product',
        ),
      ],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8F5E9)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by product name, SKU, or barcode',
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProductImportScreen()),
                        ),
                        icon: const Icon(Icons.download_for_offline_outlined),
                        label: const Text('Import'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProductFormScreen()),
                        ),
                        icon: const Icon(Icons.add_box_outlined),
                        label: const Text('Add Product'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: controller.fetchProducts(query: _query),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final products = snapshot.data!;
                if (products.isEmpty) {
                  return const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No products found',
                    message: 'Add Bio Care products locally or import a CSV file.',
                  );
                }
                return ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final emoji = _getProductEmoji(product.name);
                    final iconColor = _getProductColor(product.name);

                    return Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(emoji, style: const TextStyle(fontSize: 24)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name, style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _ProductBadge(icon: Icons.sell_outlined, label: product.sku),
                                    _ProductBadge(
                                      icon: Icons.qr_code_2_rounded,
                                      label: product.barcode.isEmpty ? 'No barcode' : product.barcode,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text('Unit price', style: Theme.of(context).textTheme.bodySmall),
                                const SizedBox(height: 4),
                                Text(
                                  AppFormatters.currency(product.unitPrice),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: scheme.primary),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) => _handleAction(value, product),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
                            ],
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

  Future<void> _handleAction(String value, Product product) async {
    if (value == 'edit') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)));
      if (mounted) setState(() {});
      return;
    }

    if (value == 'deactivate') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Deactivate product?'),
          content: Text('This will hide ${product.name} from sales entry.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Deactivate')),
          ],
        ),
      );
      if (confirm == true && mounted) {
        await context.read<AppController>().deactivateProduct(product.id!);
        setState(() {});
      }
    }
  }
}

class _ProductBadge extends StatelessWidget {
  const _ProductBadge({
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
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF263238)), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
