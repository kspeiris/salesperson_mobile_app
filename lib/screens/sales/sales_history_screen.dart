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
    final controller = context.read<AppController>();
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreate,
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('Add Sale'),
          ),
          child: FutureBuilder<List<SaleRecord>>(
            future: _salesFuture,
            builder: (context, snapshot) {
              final sales = snapshot.data;

              return ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(bottom: 96.h),
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
                            borderRadius: BorderRadius.circular(20.r),
                            onTap: _pickDate,
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                              child: Text(
                                AppFormatters.date(_selectedDate),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 14.h),
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
                              borderRadius: BorderRadius.circular(18.r),
                              icon: const SizedBox.shrink(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                                fontSize: 16.sp,
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
                  SizedBox(height: 20.h),
                  if (!snapshot.hasData)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.h),
                      child: const Center(child: CircularProgressIndicator()),
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
                        padding: EdgeInsets.only(bottom: 16.h),
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
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        title: const Text('Void sale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a short reason so this void stays clear in the audit trail.',
            ),
            SizedBox(height: 12.h),
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
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: accentColor.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.28 : 1,
        ),
        borderRadius: BorderRadius.circular(999.r),
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
            Icon(icon, size: 12.sp, color: textColor),
            SizedBox(width: 6.w),
          ],
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  fontSize: 10.sp,
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? scheme.surfaceContainerHighest
            : const Color(0xFFF3FAF4),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon, color: scheme.primary, size: 20.w),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.hintColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.sp,
                      ),
                ),
                SizedBox(height: 4.h),
                child,
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: 12.w),
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  color: isVoided
                      ? scheme.error.withValues(alpha: 0.1)
                      : scheme.primary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  isVoided
                      ? Icons.remove_shopping_cart_rounded
                      : Icons.storefront_rounded,
                  color: isVoided ? scheme.error : scheme.primary,
                  size: 24.w,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.shopName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
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
                      ],
                    ),
                  ],
                ),
              ),
              if (!isVoided)
                PopupMenuButton<String>(
                  color: scheme.surface,
                  padding: EdgeInsets.zero,
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
          SizedBox(height: 16.h),
          Divider(height: 1, color: scheme.outlineVariant),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grand total',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.hintColor,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    AppFormatters.currency(sale.total),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18.sp,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                AppFormatters.time(sale.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          if (sale.note.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              sale.note,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
                fontSize: 13.sp,
              ),
            ),
          ],
          if (isVoided && sale.voidReason != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: scheme.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: scheme.error.withValues(alpha: 0.1)),
              ),
              child: Text(
                'Audit reason: ${sale.voidReason}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.error,
                  fontSize: 11.sp,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
