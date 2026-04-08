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
import 'collection_entry_screen.dart';

class CollectionsHistoryScreen extends StatefulWidget {
  const CollectionsHistoryScreen({super.key});

  @override
  State<CollectionsHistoryScreen> createState() =>
      _CollectionsHistoryScreenState();
}

class _CollectionsHistoryScreenState extends State<CollectionsHistoryScreen> {
  late DateTime _selectedDate;
  int? _shopId;
  late Future<List<Shop>> _shopsFuture;
  late Future<List<CollectionRecord>> _collectionsFuture;
  int? _lastShopsRevision;
  int? _lastCollectionsRevision;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _shopsFuture = _loadShops();
    _collectionsFuture = _loadCollections();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shopsRevision = context.select<AppController, int>(
      (value) => value.shopsRevision,
    );
    final collectionsRevision = context.select<AppController, int>(
      (value) => value.collectionsRevision,
    );

    if (_lastShopsRevision != shopsRevision) {
      _lastShopsRevision = shopsRevision;
      _shopsFuture = _loadShops();
    }
    if (_lastCollectionsRevision != collectionsRevision) {
      _lastCollectionsRevision = collectionsRevision;
      _collectionsFuture = _loadCollections();
    }

    return FutureBuilder<List<Shop>>(
      future: _shopsFuture,
      builder: (context, shopSnapshot) {
        final shops = _distinctShops(shopSnapshot.data ?? const <Shop>[]);
        return AppShell(
          title: 'Collections History',
          subtitle:
              'Track every payment received from shops and review the payment method handled for each receipt.',
          headerImageAsset: AppAssets.collectionsHero,
          pageBackgroundAsset: AppAssets.pageTexture,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreate,
            icon: const Icon(Icons.request_quote_rounded),
            label: const Text('Add Collection'),
          ),
          child: FutureBuilder<List<CollectionRecord>>(
            future: _collectionsFuture,
            builder: (context, snapshot) {
              final collections = snapshot.data;

              return ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(bottom: 96.h),
                children: [
                  SectionCard(
                    title: 'Filters',
                    subtitle:
                        'Choose a day or shop to focus on the right collection records.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FilterField(
                          label: 'Date',
                          icon: Icons.calendar_month_rounded,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18.r),
                            onTap: _pickDate,
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                              child: Text(
                                AppFormatters.date(_selectedDate),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        _FilterField(
                          label: 'Shop filter',
                          icon: Icons.storefront_outlined,
                          trailing: Icon(Icons.keyboard_arrow_down_rounded, color: theme.hintColor),
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
                              onChanged: _updateShopFilter,
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
                  else if (collections!.isEmpty)
                    const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No collections recorded',
                      message:
                          'Collections for the selected date will appear here.',
                      imageAsset: AppAssets.emptyStateHero,
                    )
                  else
                    ...collections.map((entry) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: _CollectionHistoryCard(
                          collection: entry,
                          onEdit: entry.isVoided ? null : () => _openEdit(entry),
                          onVoid: entry.isVoided ? null : () => _voidCollection(entry),
                        ),
                      );
                    }),
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
      MaterialPageRoute(builder: (_) => const CollectionEntryScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openEdit(CollectionRecord entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CollectionEntryScreen(collection: entry),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _voidCollection(CollectionRecord entry) async {
    final controller = context.read<AppController>();
    final reasonController = TextEditingController();
    FocusScope.of(context).unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        title: const Text('Void collection'),
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

    if (confirmed == true && entry.id != null) {
      final reason = reasonController.text.trim().isEmpty
          ? 'Manual void'
          : reasonController.text.trim();
      await controller.voidCollection(entry.id!, reason);
      if (mounted) setState(() {});
    }
    reasonController.dispose();
  }
}

extension on _CollectionsHistoryScreenState {
  Future<List<Shop>> _loadShops() {
    return context.read<AppController>().fetchShops();
  }

  Future<List<CollectionRecord>> _loadCollections() {
    final start =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final end = start.add(const Duration(days: 1));
    return context.read<AppController>().fetchCollections(
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
      _collectionsFuture = _loadCollections();
    });
  }

  void _updateShopFilter(int? value) {
    if (!mounted) return;
    setState(() {
      _shopId = value;
      _collectionsFuture = _loadCollections();
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

class _CollectionHistoryCard extends StatelessWidget {
  const _CollectionHistoryCard({
    required this.collection,
    required this.onEdit,
    required this.onVoid,
  });

  final CollectionRecord collection;
  final VoidCallback? onEdit;
  final VoidCallback? onVoid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isVoided = collection.isVoided;

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
                      : scheme.secondary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.request_quote_rounded,
                  color: isVoided ? scheme.error : scheme.secondary,
                  size: 24.w,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.shopName,
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
                          label: isVoided ? 'Voided' : collection.paymentMethod,
                          icon: isVoided
                              ? Icons.block_rounded
                              : Icons.account_balance_rounded,
                          accentColor: isVoided
                              ? const Color(0xFFF9ECEC)
                              : scheme.secondary.withValues(alpha: 0.1),
                          textColor: isVoided
                              ? const Color(0xFF9A4B4B)
                              : scheme.secondary,
                        ),
                        _StatusChip(
                          label: AppFormatters.time(collection.createdAt),
                          icon: Icons.schedule_rounded,
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
                      child: Text('Edit collection'),
                    ),
                    PopupMenuItem(
                      value: 'void',
                      child: Text('Void collection'),
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
                    'Collected amount',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.hintColor,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    AppFormatters.currency(collection.amount),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18.sp,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (collection.referenceNote.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              collection.referenceNote,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
                fontSize: 13.sp,
              ),
            ),
          ],
          if (isVoided && collection.voidReason != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: scheme.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: scheme.error.withValues(alpha: 0.1)),
              ),
              child: Text(
                'Audit reason: ${collection.voidReason}',
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    this.icon,
    this.accentColor,
    this.textColor,
  });

  final String label;
  final IconData? icon;
  final Color? accentColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = textColor ?? theme.hintColor;
    final bg = accentColor ?? scheme.surfaceContainerHighest.withValues(alpha: 0.4);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.sp, color: color),
            SizedBox(width: 4.w),
          ],
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }
}
