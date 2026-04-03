import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/entities.dart';
import 'collection_entry_screen.dart';

class CollectionsHistoryScreen extends StatefulWidget {
  const CollectionsHistoryScreen({super.key});

  @override
  State<CollectionsHistoryScreen> createState() => _CollectionsHistoryScreenState();
}

class _CollectionsHistoryScreenState extends State<CollectionsHistoryScreen> {
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
    final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final end = start.add(const Duration(days: 1));

    return FutureBuilder<List<Shop>>(
      future: controller.fetchShops(),
      builder: (context, shopSnapshot) {
        final shops = shopSnapshot.data ?? const <Shop>[];
        return AppShell(
          title: 'Collections History',
          subtitle: 'Track every payment received from shops, review the payment method used, and void incorrect entries when needed.',
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectionEntryScreen())),
            icon: const Icon(Icons.request_quote_rounded),
            label: const Text('Add Collection'),
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFDDE6DF)),
                ),
                child: Column(
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
                        const DropdownMenuItem<int?>(value: null, child: Text('All shops')),
                        ...shops.map((shop) => DropdownMenuItem<int?>(value: shop.id, child: Text(shop.name))),
                      ],
                      onChanged: (value) => setState(() => _shopId = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<CollectionRecord>>(
                  future: controller.fetchCollections(start: start, end: end, shopId: _shopId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final collections = snapshot.data!;
                    if (collections.isEmpty) {
                      return const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No collections recorded',
                        message: 'Collections for the selected date will appear here.',
                      );
                    }

                    return ListView.separated(
                      itemCount: collections.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final entry = collections[index];
                        return Container(
                          padding: const EdgeInsets.all(18),
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
                                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(Icons.request_quote_outlined, color: Theme.of(context).colorScheme.secondary),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(entry.shopName, style: Theme.of(context).textTheme.titleMedium),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _HistoryChip(label: entry.isVoided ? 'Voided' : entry.paymentMethod),
                                            _HistoryChip(label: AppFormatters.time(entry.createdAt)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    enabled: !entry.isVoided,
                                    onSelected: (value) {
                                      if (value == 'void') {
                                        _voidCollection(entry);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'void', child: Text('Void collection')),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text('Collected amount', style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 4),
                              Text(AppFormatters.currency(entry.amount), style: Theme.of(context).textTheme.titleLarge),
                              if (entry.referenceNote.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(entry.referenceNote, style: Theme.of(context).textTheme.bodyMedium),
                              ],
                              if (entry.voidReason != null && entry.voidReason!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text('Reason: ${entry.voidReason}', style: Theme.of(context).textTheme.bodySmall),
                              ],
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

  Future<void> _voidCollection(CollectionRecord entry) async {
    final controller = context.read<AppController>();
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Void collection'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Void')),
        ],
      ),
    );

    if (confirmed == true && entry.id != null) {
      final reason = reasonController.text.trim().isEmpty ? 'Manual void' : reasonController.text.trim();
      await controller.voidCollection(entry.id!, reason);
      if (mounted) setState(() {});
    }
    reasonController.dispose();
  }
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
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
