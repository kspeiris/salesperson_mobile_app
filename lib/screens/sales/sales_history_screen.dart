import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/entities.dart';

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
    final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final end = start.add(const Duration(days: 1));

    return FutureBuilder<List<Shop>>(
      future: controller.fetchShops(),
      builder: (context, shopSnapshot) {
        final shops = shopSnapshot.data ?? const <Shop>[];

        return AppShell(
          title: 'Sales History',
          subtitle: 'Review recorded sales by day, filter by shop, and void incorrect entries with an audit reason.',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _shopId,
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
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<SaleRecord>>(
                  future: controller.fetchSales(start: start, end: end, shopId: _shopId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final sales = snapshot.data!;
                    if (sales.isEmpty) {
                      return const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No sales recorded',
                        message: 'Sales for the selected date will appear here.',
                      );
                    }

                    return ListView.separated(
                      itemCount: sales.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final sale = sales[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.point_of_sale_rounded),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(sale.shopName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                          ),
                                          _StatusChip(label: sale.isVoided ? 'Voided' : sale.paymentType),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text('${AppFormatters.time(sale.createdAt)} - ${sale.items.length} items'),
                                      if (sale.note.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(sale.note, style: Theme.of(context).textTheme.bodySmall),
                                      ],
                                      if (sale.voidReason != null && sale.voidReason!.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text('Reason: ${sale.voidReason}', style: Theme.of(context).textTheme.bodySmall),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(AppFormatters.currency(sale.total), style: const TextStyle(fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 8),
                                    PopupMenuButton<String>(
                                      enabled: !sale.isVoided,
                                      onSelected: (value) {
                                        if (value == 'void') _voidSale(sale);
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: 'void', child: Text('Void sale')),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

  Future<void> _voidSale(SaleRecord sale) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Void sale'),
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
    if (confirmed == true && sale.id != null) {
      final reason = reasonController.text.trim().isEmpty ? 'Manual void' : reasonController.text.trim();
      await context.read<AppController>().voidSale(sale.id!, reason);
      if (mounted) setState(() {});
    }
    reasonController.dispose();
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECE3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}
