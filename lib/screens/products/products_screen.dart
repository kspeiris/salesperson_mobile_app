import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  Timer? _searchDebounce;
  String _query = '';
  late Future<List<Product>> _productsFuture;
  int? _lastRevision;

  @override
  void initState() {
    super.initState();
    _productsFuture = _loadProducts();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Color _getProductColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('aloe')) return const Color(0xFF93B620);
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
    final revision = context.select<AppController, int>(
      (value) => value.productsRevision,
    );
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_lastRevision != revision) {
      _lastRevision = revision;
      _productsFuture = _loadProducts();
    }

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
        future: _productsFuture,
        builder: (context, snapshot) {
          final products = snapshot.data;

          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(bottom: 24.h),
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
                                  _updateQuery('');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                    SizedBox(height: 14.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
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
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              if (!snapshot.hasData)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.h),
                  child: const Center(child: CircularProgressIndicator()),
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
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48.w,
                            height: 48.w,
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            alignment: Alignment.center,
                            child:
                                Icon(productIcon, color: iconColor, size: 24.w),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16.sp
                                    )),
                                SizedBox(height: 8.h),
                                Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
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
                                SizedBox(height: 16.h),
                                Text('Unit price',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.hintColor,
                                      fontSize: 11.sp
                                    )),
                                SizedBox(height: 4.h),
                                Text(
                                  AppFormatters.currency(product.unitPrice),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18.sp,
                                      color: scheme.primary),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
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

  Future<List<Product>> _loadProducts() {
    return context.read<AppController>().fetchProducts(query: _query);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 250),
      () => _updateQuery(value),
    );
  }

  void _updateQuery(String value) {
    if (!mounted) return;
    final normalized = value.trim();
    if (normalized == _query) return;
    setState(() {
      _query = normalized;
      _productsFuture = _loadProducts();
    });
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
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : const Color(0xFFF8FDF8),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: scheme.onSurface),
          SizedBox(width: 4.w),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurface, fontSize: 10.sp),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
