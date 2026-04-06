import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/theme/app_assets.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_card.dart';
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

  Color _getProductColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('aloe')) return const Color(0xFF2E7D32);
    if (lower.contains('orange') || lower.contains('fruit')) {
      return Colors.orange.shade700;
    }
    if (lower.contains('energy')) return Colors.amber.shade800;
    if (lower.contains('herbal')) {
      return Colors.purple.shade600;
    }
    return const Color(0xFF263238);
  }

  IconData _getProductIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('aloe')) return Icons.spa_outlined;
    if (lower.contains('orange') ||
        lower.contains('fruit') ||
        lower.contains('citrus')) {
      return Icons.local_drink_outlined;
    }
    if (lower.contains('energy') || lower.contains('boost')) {
      return Icons.bolt_outlined;
    }
    if (lower.contains('herbal')) return Icons.eco_outlined;
    return Icons.inventory_2_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final scheme = Theme.of(context).colorScheme;

    return AppShell(
      title: 'Products',
      subtitle:
          'Manage the Bio Care product catalog, pricing, and barcode items.',
      headerImageAsset: AppAssets.productsHero,
      pageBackgroundAsset: AppAssets.pageTexture,
      actions: [
        IconButton(
          onPressed: _openImport,
          icon: const Icon(Icons.download_for_offline_outlined),
          tooltip: 'Import Products',
        ),
        IconButton(
          onPressed: _openCreate,
          icon: const Icon(Icons.add_box_outlined),
          tooltip: 'Add Product',
        ),
      ],
      child: FutureBuilder<List<Product>>(
        future: controller.fetchProducts(query: _query),
        builder: (context, snapshot) {
          final products = snapshot.data;

          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              SectionCard(
                title: 'Workspace',
                subtitle:
                    'Search the catalog quickly, then import or add products without leaving this screen.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (products != null)
                          _ProductBadge(
                            icon: Icons.inventory_2_outlined,
                            label: '${products.length} active products',
                          ),
                        if (_query.isNotEmpty)
                          _ProductBadge(
                            icon: Icons.tune_rounded,
                            label: 'Filtered by "${_query.trim()}"',
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _openImport,
                          icon: const Icon(Icons.download_for_offline_outlined),
                          label: const Text('Import'),
                        ),
                        FilledButton.icon(
                          onPressed: _openCreate,
                          icon: const Icon(Icons.add_box_outlined),
                          label: const Text('Add Product'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!snapshot.hasData)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (products!.isEmpty)
                const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No products found',
                  message:
                      'Add Bio Care products locally or import a CSV file.',
                  imageAsset: AppAssets.emptyStateHero,
                )
              else
                ...products.map((product) {
                  final productIcon = _getProductIcon(product.name);
                  final iconColor = _getProductColor(product.name);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(18),
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
                            child:
                                Icon(productIcon, color: iconColor, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _ProductBadge(
                                        icon: Icons.sell_outlined,
                                        label: product.sku),
                                    _ProductBadge(
                                      icon: Icons.qr_code_2_rounded,
                                      label: product.barcode.isEmpty
                                          ? 'No barcode'
                                          : product.barcode,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text('Unit price',
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                                const SizedBox(height: 4),
                                Text(
                                  AppFormatters.currency(product.unitPrice),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: scheme.primary),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) =>
                                _handleAction(value, product),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                  value: 'deactivate',
                                  child: Text('Deactivate')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openImport() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductImportScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openCreate() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductFormScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _handleAction(String value, Product product) async {
    if (value == 'edit') {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProductFormScreen(product: product)));
      if (mounted) setState(() {});
      return;
    }

    if (value == 'deactivate') {
      FocusScope.of(context).unfocus();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          title: const Text('Deactivate product?'),
          content: Text('This will hide ${product.name} from sales entry.'),
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
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: const Color(0xFF263238)),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
