import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/theme/app_assets.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/empty_state.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final compact = MediaQuery.of(context).size.width < 640;
    final theme = Theme.of(context);
    final start =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final end = start.add(const Duration(days: 1));

    return FutureBuilder<List<Shop>>(
      future: controller.fetchShops(),
      builder: (context, shopSnapshot) {
        final shops = _distinctShops(shopSnapshot.data ?? const <Shop>[]);

        return AppShell(
          title: 'Sales History',
          subtitle:
              'Review recorded sales by day, filter by shop, and void incorrect entries with an audit reason.',
          headerImageAsset: AppAssets.salesHero,
          pageBackgroundAsset: AppAssets.pageTexture,
          floatingActionButton: _PremiumSalesFab(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SaleEntryScreen())),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 18 : 22),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FCF8).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFD8E9DA)),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 24,
                      offset: Offset(0, 14),
                      color: Color(0x102E7D32),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEEF8EF), Color(0xFFDCEFD9)],
                            ),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('Filters',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Narrow the list by date or shop to review the correct sales quickly.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: const Color(0xFF6E8472)),
                    ),
                    const SizedBox(height: 18),
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
                              color: const Color(0xFF35533B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FilterField(
                      label: 'Shop filter',
                      icon: Icons.store_rounded,
                      trailing: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF4E6B53)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: _shopId,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          icon: const SizedBox.shrink(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF223327),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                                value: null, child: Text('All shops')),
                            ...shops.map((shop) => DropdownMenuItem<int?>(
                                value: shop.id, child: Text(shop.name))),
                          ],
                          onChanged: (value) => setState(() => _shopId = value),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<SaleRecord>>(
                  future: controller.fetchSales(
                      start: start, end: end, shopId: _shopId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final sales = snapshot.data!;
                    if (sales.isEmpty) {
                      return const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No sales recorded',
                        message:
                            'Sales for the selected date will appear here.',
                        imageAsset: AppAssets.emptyStateHero,
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: sales.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final sale = sales[index];
                        return _SaleHistoryCard(
                          sale: sale,
                          onVoid: sale.isVoided ? null : () => _voidSale(sale),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _voidSale(SaleRecord sale) async {
    final reasonController = TextEditingController();
    final controller = context.read<AppController>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Void sale'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason'),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FAF4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDEDDC)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 8),
            color: Color(0x082E7D32),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32)),
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
                        color: const Color(0xFF6C8370),
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
    required this.onVoid,
  });

  final SaleRecord sale;
  final VoidCallback? onVoid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVoided = sale.isVoided;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF5FBF6)],
        ),
        border: Border.all(color: const Color(0xFFDCEADF)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 14),
            color: Color(0x0D214B2B),
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
                  color: const Color(0xFFB7DDBA).withValues(alpha: 0.18),
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 14,
              child: Icon(
                Icons.receipt_long_rounded,
                size: 44,
                color: const Color(0xFF9CCAA3).withValues(alpha: 0.28),
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
                      const Color(0xFFEAF5EC).withValues(alpha: 0.26),
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
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF0F7F1), Color(0xFFDDEEDF)],
                          ),
                          border: Border.all(color: Colors.white),
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
                                color: const Color(0xFF223327),
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
                        color: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        onSelected: (value) {
                          if (value == 'void' && onVoid != null) onVoid!();
                        },
                        itemBuilder: (_) => const [
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
                      color: const Color(0xFFDCE9DE).withValues(alpha: 0.9),
                    ),
                  ),
                  Text(
                    'Grand total',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF6C8370),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.currency(sale.total),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: const Color(0xFF1D2F22),
                    ),
                  ),
                  if (sale.note.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      sale.note,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF607565),
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
                        color: const Color(0xFFF9EEEE),
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
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 12),
            color: Color(0x22357F3A),
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
