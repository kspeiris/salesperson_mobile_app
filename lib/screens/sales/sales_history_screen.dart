import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/theme/app_assets.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_card.dart';
import '../../models/entities.dart';
import 'sale_entry_screen.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  late DateTime _selectedDate;
  int? _shopId;
  late Future<List<Shop>> _shopsFuture;
  late Future<List<SaleRecord>> _salesFuture;
  int? _lastShopsRevision;
  int? _lastSalesRevision;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _shopsFuture = _loadShops();
    _salesFuture = _loadSales();
  }

  @override
  Widget build(BuildContext context) {
    final shopsRevision = context.select<AppController, int>(
      (value) => value.shopsRevision,
    );
    final salesRevision = context.select<AppController, int>(
      (value) => value.salesRevision,
    );
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_lastShopsRevision != shopsRevision) {
      _lastShopsRevision = shopsRevision;
      _shopsFuture = _loadShops();
    }
    if (_lastSalesRevision != salesRevision) {
      _lastSalesRevision = salesRevision;
      _salesFuture = _loadSales();
    }

    return FutureBuilder<List<Shop>>(
      future: _shopsFuture,
      builder: (context, shopSnapshot) {
        final shops = _distinctShops(shopSnapshot.data ?? const <Shop>[]);

        return AppShell(
          title: 'Sales History',
          subtitle:
              'Review recorded sales by day, filter by shop, and void incorrect entries with an audit reason.',
          headerImageAsset: AppAssets.salesHero,
          pageBackgroundAsset: AppAssets.pageTexture,
          floatingActionButton: _PremiumSalesFab(
            onPressed: _openCreate,
          ),
          child: FutureBuilder<List<SaleRecord>>(
            future: _salesFuture,
            builder: (context, snapshot) {
              final sales = snapshot.data;

              return ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  SectionCard(
                    title: 'Filters',
                    subtitle:
                        'Narrow the list by date or shop to review the right sales quickly.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FilterField(
                          label: 'Date',
                          icon: Icons.calendar_month_rounded,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _pickDate,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Text(
                                AppFormatters.date(_selectedDate),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FilterField(
                          label: 'Shop filter',
                          icon: Icons.store_rounded,
                          trailing: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: theme.hintColor),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int?>(
                              value: _shopId,
                              isExpanded: true,
                              dropdownColor: scheme.surface,
                              borderRadius: BorderRadius.circular(18),
                              icon: const SizedBox.shrink(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                    value: null, child: Text('All shops')),
                                ...shops.map((shop) => DropdownMenuItem<int?>(
                                    value: shop.id, child: Text(shop.name))),
                              ],
                              onChanged: (value) =>
                                  _updateShopFilter(value),
                            ),
                          ),
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
                  else if (sales!.isEmpty)
                    const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No sales recorded',
                      message: 'Sales for the selected date will appear here.',
                      imageAsset: AppAssets.emptyStateHero,
                    )
                  else
                    ...sales.map(
                      (sale) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _SaleHistoryCard(
                          sale: sale,
                          onEdit: sale.isVoided ? null : () => _openEdit(sale),
                          onVoid: sale.isVoided ? null : () => _voidSale(sale),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _updateSelectedDate(picked);
    }
  }

  Future<void> _openCreate() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SaleEntryScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openEdit(SaleRecord sale) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SaleEntryScreen(sale: sale)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _voidSale(SaleRecord sale) async {
    final reasonController = TextEditingController();
    final controller = context.read<AppController>();
    FocusScope.of(context).unfocus();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: const Text('Void sale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a short reason so this void stays clear in the audit trail.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Void')),
        ],
      ),
    );
    if (confirmed == true && sale.id != null) {
      final reason = reasonController.text.trim().isEmpty
          ? 'Manual void'
          : reasonController.text.trim();
      await controller.voidSale(sale.id!, reason);
      if (mounted) setState(() {});
    }
    reasonController.dispose();
  }
}

extension on _SalesHistoryScreenState {
  Future<List<Shop>> _loadShops() {
    return context.read<AppController>().fetchShops();
  }

  Future<List<SaleRecord>> _loadSales() {
    final start =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final end = start.add(const Duration(days: 1));
    return context.read<AppController>().fetchSales(
          start: start,
          end: end,
          shopId: _shopId,
          activeOnly: false,
        );
  }

  void _updateSelectedDate(DateTime value) {
    if (!mounted) return;
    setState(() {
      _selectedDate = value;
      _salesFuture = _loadSales();
    });
  }

  void _updateShopFilter(int? value) {
    if (!mounted) return;
    setState(() {
      _shopId = value;
      _salesFuture = _loadSales();
    });
  }
}

List<Shop> _distinctShops(List<Shop> shops) {
  final seen = <String>{};
  final unique = <Shop>[];

  for (final shop in shops) {
    final key = '${shop.id ?? 'null'}|${shop.name}|${shop.area}';
    if (seen.add(key)) {
      unique.add(shop);
    }
  }

  return unique;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    this.icon,
    this.accentColor = const Color(0xFFEDF5EE),
    this.textColor = const Color(0xFF55705B),
  });

  final String label;
  final IconData? icon;
  final Color accentColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: accentColor.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.28 : 1,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? scheme.outlineVariant
              : Colors.white.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    required this.label,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? scheme.surfaceContainerHighest
            : const Color(0xFFF3FAF4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 8),
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.18 : 0.03,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.surface.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.92 : 0.9,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: theme.hintColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                child,
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _SaleHistoryCard extends StatelessWidget {
  const _SaleHistoryCard({
    required this.sale,
    required this.onEdit,
    required this.onVoid,
  });

  final SaleRecord sale;
  final VoidCallback? onEdit;
  final VoidCallback? onVoid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isVoided = sale.isVoided;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surface,
            theme.brightness == Brightness.dark
                ? scheme.surfaceContainerHighest
                : const Color(0xFFF5FBF6),
          ],
        ),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 14),
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.2 : 0.05,
            ),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              top: -4,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.10 : 0.18,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 14,
              child: Icon(
                Icons.receipt_long_rounded,
                size: 44,
                color: scheme.primary.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.16 : 0.28,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      scheme.primary.withValues(alpha: 0.10),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.brightness == Brightness.dark
                                  ? scheme.surfaceContainerHighest
                                  : const Color(0xFFF0F7F1),
                              theme.brightness == Brightness.dark
                                  ? scheme.surface
                                  : const Color(0xFFDDEEDF),
                            ],
                          ),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Icon(
                          isVoided
                              ? Icons.remove_shopping_cart_rounded
                              : Icons.storefront_rounded,
                          color: isVoided
                              ? const Color(0xFF8C5A5A)
                              : const Color(0xFF295D31),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sale.shopName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _StatusChip(
                                  label: isVoided ? 'Voided' : sale.paymentType,
                                  icon: isVoided
                                      ? Icons.block_rounded
                                      : Icons.payments_outlined,
                                  accentColor: isVoided
                                      ? const Color(0xFFF9ECEC)
                                      : const Color(0xFFEDF6EF),
                                  textColor: isVoided
                                      ? const Color(0xFF9A4B4B)
                                      : const Color(0xFF4F6D55),
                                ),
                                _StatusChip(
                                  label: '${sale.items.length} items',
                                  icon: Icons.inventory_2_outlined,
                                ),
                                _StatusChip(
                                  label: AppFormatters.time(sale.createdAt),
                                  icon: Icons.schedule_rounded,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        enabled: !isVoided,
                        color: scheme.surface,
                        surfaceTintColor: Colors.transparent,
                        onSelected: (value) {
                          if (value == 'edit' && onEdit != null) onEdit!();
                          if (value == 'void' && onVoid != null) onVoid!();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit sale'),
                          ),
                          PopupMenuItem(
                            value: 'void',
                            child: Text('Void sale'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(
                      height: 1,
                      color: scheme.outlineVariant,
                    ),
                  ),
                  Text(
                    'Grand total',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.currency(sale.total),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (sale.note.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      sale.note,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                  if (sale.voidReason != null &&
                      sale.voidReason!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF3A2222)
                            : const Color(0xFFF9EEEE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Audit reason: ${sale.voidReason}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF8A4A4A),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumSalesFab extends StatelessWidget {
  const _PremiumSalesFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 12),
            color: Colors.black.withValues(alpha: 0.12),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          ),
        ),
        child: FloatingActionButton.extended(
          onPressed: onPressed,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          extendedPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          icon: const Icon(Icons.add_shopping_cart_rounded),
          label: const Text('Add Sale'),
        ),
      ),
    );
  }
}
