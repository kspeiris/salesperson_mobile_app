import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/theme/app_assets.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_card.dart';
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
  Timer? _searchDebounce;
  String _query = '';
  late Future<List<Shop>> _shopsFuture;
  int? _lastRevision;

  @override
  void initState() {
    super.initState();
    _shopsFuture = _loadShops();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final revision = context.select<AppController, int>(
      (value) => value.shopsRevision,
    );
    final theme = Theme.of(context);
    final scheme = Theme.of(context).colorScheme;

    if (_lastRevision != revision) {
      _lastRevision = revision;
      _shopsFuture = _loadShops();
    }

    return AppShell(
      title: 'Customer Management',
      subtitle:
          'Manage Bio Care customer shops and outstanding credit balances.',
      headerImageAsset: AppAssets.shopsHero,
      pageBackgroundAsset: AppAssets.pageTexture,
      showHeaderImage: false,
      actions: [
        IconButton(
          onPressed: _openImport,
          icon: const Icon(Icons.download_for_offline_outlined),
          tooltip: 'Import Shops',
        ),
        IconButton(
          onPressed: _openCreate,
          icon: const Icon(Icons.add_business_outlined),
          tooltip: 'Add Shop',
        ),
      ],
      child: FutureBuilder<List<Shop>>(
        future: _shopsFuture,
        builder: (context, snapshot) {
          final shops = snapshot.data;

          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              SectionCard(
                title: 'Workspace',
                subtitle:
                    'Search customer records quickly, then import shops or add a new account from the same workspace.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                  _updateQuery('');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (shops != null)
                          _MiniBadge(
                            icon: Icons.storefront_outlined,
                            label: '${shops.length} active shops',
                          ),
                        if (_query.isNotEmpty)
                          _MiniBadge(
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
                          icon: const Icon(Icons.add_business_outlined),
                          label: const Text('Add Shop'),
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
              else if (shops!.isEmpty)
                const EmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'No shops found',
                  message:
                      'Add your first shop or import a CSV file to start recording sales and collections.',
                  imageAsset: AppAssets.emptyStateHero,
                )
              else
                ...shops.map((shop) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: scheme.outlineVariant),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: theme.brightness == Brightness.dark
                                  ? 0.18
                                  : 0.02,
                            ),
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
                          Divider(height: 1, color: scheme.outlineVariant),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final stacked = constraints.maxWidth < 360;

                                final balanceLabel = Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.account_balance_wallet_outlined,
                                        size: 16, color: theme.hintColor),
                                    const SizedBox(width: 6),
                                    Text('Outstanding credit',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(color: theme.hintColor)),
                                  ],
                                );

                                final balanceValue = Text(
                                  AppFormatters.currency(shop.balance),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: shop.balance > 0
                                              ? Colors.red.shade700
                                              : scheme.primary),
                                );

                                if (stacked) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      balanceLabel,
                                      const SizedBox(height: 8),
                                      balanceValue,
                                    ],
                                  );
                                }

                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    balanceLabel,
                                    balanceValue,
                                  ],
                                );
                              },
                            ),
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
      MaterialPageRoute(builder: (_) => const ShopImportScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<List<Shop>> _loadShops() {
    return context.read<AppController>().fetchShops(query: _query);
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
      _shopsFuture = _loadShops();
    });
  }

  Future<void> _openCreate() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShopFormScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _handleAction(String value, Shop shop) async {
    if (value == 'edit') {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => ShopFormScreen(shop: shop)));
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
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : const Color(0xFFF8FDF8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 6),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }
}
