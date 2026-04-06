import 'package:flutter/material.dart';
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
              'Track every payment received from shops, review the payment method used, and void incorrect entries when needed.',
          headerImageAsset: AppAssets.collectionsHero,
          pageBackgroundAsset: AppAssets.pageTexture,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreate,
            icon: const Icon(Icons.request_quote_rounded),
            label: const Text('Add Collection'),
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
          ),
          child: FutureBuilder<List<CollectionRecord>>(
            future: _collectionsFuture,
            builder: (context, snapshot) {
              final collections = snapshot.data;

              return ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  SectionCard(
                    title: 'Filters',
                    subtitle:
                        'Choose a day or shop to focus on the right collection records.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: _pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.calendar_month_outlined),
                              labelText: 'Date',
                            ),
                            child: Text(AppFormatters.date(_selectedDate)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int?>(
                          initialValue: _shopId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.storefront_outlined),
                            labelText: 'Shop filter',
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                                value: null, child: Text('All shops')),
                            ...shops.map((shop) => DropdownMenuItem<int?>(
                                value: shop.id, child: Text(shop.name))),
                          ],
                          onChanged: _updateShopFilter,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!snapshot.hasData)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
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
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFDDE6DF)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(Icons.request_quote_outlined,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(entry.shopName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _HistoryChip(
                                                label: entry.isVoided
                                                    ? 'Voided'
                                                    : entry.paymentMethod),
                                            _HistoryChip(
                                                label: AppFormatters.time(
                                                    entry.createdAt)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    enabled: !entry.isVoided,
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _openEdit(entry);
                                      }
                                      if (value == 'void') {
                                        _voidCollection(entry);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit collection')),
                                      PopupMenuItem(
                                          value: 'void',
                                          child: Text('Void collection')),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text('Collected amount',
                                  style:
                                      Theme.of(context).textTheme.labelMedium),
                              const SizedBox(height: 4),
                              Text(
                                AppFormatters.currency(entry.amount),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              if (entry.referenceNote.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(entry.referenceNote,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                              if (entry.voidReason != null &&
                                  entry.voidReason!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Reason: ${entry.voidReason}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: const Text('Void collection'),
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

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3EA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
